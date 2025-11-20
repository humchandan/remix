// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

contract RobustHybridExchange is AccessControl, ReentrancyGuard {
    // Access roles
    bytes32 public constant SUBADMIN_ROLE = keccak256("SUBADMIN_ROLE");

    // Swap fees (basis points, 10000 = 100%)
    uint256 public swapFeeBps = 50; // 0.5% default
    address public feeRecipient;

    // Whitelisted tokens (admin approved only)
    mapping(address => bool) public allowedTokens;

    // Admin-set fixed rates: tokenIn => tokenOut => rate (1e18 precision)
    mapping(address => mapping(address => uint256)) public globalRates;

    // Orderbook struct
    struct Order {
        address maker;
        address tokenIn;
        address tokenOut;
        uint256 amountInitial;
        uint256 amountRemaining;
        uint256 rate;      // 1e18 precision
        uint256 expiresAt; // unix timestamp
        bool active;
    }
    Order[] public orders;

    // Events
    event TokenWhitelistUpdated(address indexed token, bool allowed);
    event GlobalRateSet(address indexed tokenIn, address indexed tokenOut, uint256 rate);
    event OrderCreated(uint256 indexed orderId, address indexed maker, address tokenIn, address tokenOut, uint256 amountInitial, uint256 rate, uint256 expiresAt);
    event OrderMatched(uint256 indexed orderId, address indexed taker, uint256 fillAmount, uint256 outAmount, uint256 fee);
    event OrderCancelled(uint256 indexed orderId, uint256 amountRefunded);
    event SwapGlobal(address indexed sender, address indexed tokenIn, address indexed tokenOut, uint256 amountIn, uint256 amountOut, uint256 fee);
    event FeeUpdated(uint256 oldFeeBps, uint256 newFeeBps);
    event FeeRecipientUpdated(address oldRecipient, address newRecipient);

    // Constructor
    constructor(address _feeRecipient) {
        require(_feeRecipient != address(0), "Fee recipient required");
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        feeRecipient = _feeRecipient;
    }

    // --------- Admin Controls ---------

    function setAllowedToken(address token, bool allowed) external onlyAdminOrSub {
        allowedTokens[token] = allowed;
        emit TokenWhitelistUpdated(token, allowed);
    }

    function setGlobalRate(address tokenIn, address tokenOut, uint256 rate) external onlyAdminOrSub {
        require(rate > 0, "Zero rate");
        require(allowedTokens[tokenIn] && allowedTokens[tokenOut], "Tokens not allowed");
        globalRates[tokenIn][tokenOut] = rate;
        emit GlobalRateSet(tokenIn, tokenOut, rate);
    }

    function setFee(uint256 newFeeBps) external onlyAdminOrSub {
        require(newFeeBps <= 1000, "Fee too high"); // <=10%
        emit FeeUpdated(swapFeeBps, newFeeBps);
        swapFeeBps = newFeeBps;
    }

    function setFeeRecipient(address recipient) external onlyAdminOrSub {
        require(recipient != address(0), "Zero address");
        emit FeeRecipientUpdated(feeRecipient, recipient);
        feeRecipient = recipient;
    }

    function grantSubAdmin(address account) external onlyRole(DEFAULT_ADMIN_ROLE) {
        grantRole(SUBADMIN_ROLE, account);
    }

    // Emergency admin can withdraw stuck tokens
    function emergencyWithdraw(address token) external onlyAdminOrSub {
        uint256 bal = IERC20(token).balanceOf(address(this));
        require(bal > 0, "Nothing to withdraw");
        IERC20(token).transfer(msg.sender, bal);
    }

    modifier onlyAdminOrSub() {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender) || hasRole(SUBADMIN_ROLE, msg.sender), "Not admin/subadmin");
        _;
    }

    // --------- Utility Functions ---------

    function getDecimals(address token) public view returns (uint8) {
        return IERC20Metadata(token).decimals();
    }

    function normalize(address token, uint256 amount) public view returns (uint256) {
        uint8 decimals = getDecimals(token);
        return amount * (10 ** (18 - decimals)); // Up to 18
    }

    function denormalize(address token, uint256 nAmount) public view returns (uint256) {
        uint8 decimals = getDecimals(token);
        return nAmount / (10 ** (18 - decimals)); // Down to token decimals
    }

    // --------- Global Pool: Instant Admin Swaps ---------

    function swapGlobal(address tokenIn, address tokenOut, uint256 amountIn) external nonReentrant {
        require(allowedTokens[tokenIn] && allowedTokens[tokenOut], "Tokens not allowed");
        uint256 rate = globalRates[tokenIn][tokenOut];
        require(rate > 0, "No global rate");
        uint256 nAmountIn = normalize(tokenIn, amountIn);
        uint256 nAmountOut = nAmountIn * rate / 1e18;
        uint256 amountOut = denormalize(tokenOut, nAmountOut);

        uint256 fee = amountOut * swapFeeBps / 10000;
        uint256 receiverGets = amountOut - fee;
        require(receiverGets > 0, "Amount too small");

        IERC20(tokenIn).transferFrom(msg.sender, address(this), amountIn);
        IERC20(tokenOut).transfer(msg.sender, receiverGets);
        if (fee > 0) IERC20(tokenOut).transfer(feeRecipient, fee);

        emit SwapGlobal(msg.sender, tokenIn, tokenOut, amountIn, receiverGets, fee);
    }

    // --------- Orderbook: Custom Orders, Partial Fills ---------

    function createOrder(
        address tokenIn,
        address tokenOut,
        uint256 amountIn,
        uint256 rate,
        uint256 expiresInSeconds
    ) external nonReentrant {
        require(allowedTokens[tokenIn] && allowedTokens[tokenOut], "Tokens not allowed");
        require(rate > 0, "Rate zero");
        uint256 expiresAt = block.timestamp + expiresInSeconds;
        uint256 nAmountIn = normalize(tokenIn, amountIn);
        require(nAmountIn > 0, "Too small");

        IERC20(tokenIn).transferFrom(msg.sender, address(this), amountIn);

        orders.push(Order({
            maker: msg.sender,
            tokenIn: tokenIn,
            tokenOut: tokenOut,
            amountInitial: amountIn,
            amountRemaining: amountIn,
            rate: rate,
            expiresAt: expiresAt,
            active: true
        }));

        emit OrderCreated(orders.length - 1, msg.sender, tokenIn, tokenOut, amountIn, rate, expiresAt);
    }

    // Cancel or refund expired/unfilled order
    function cancelOrder(uint256 orderId) external nonReentrant {
        require(orderId < orders.length, "Invalid");
        Order storage ord = orders[orderId];
        require(ord.active, "Inactive");
        require(ord.maker == msg.sender, "Only maker");
        ord.active = false;
        uint256 refundAmount = ord.amountRemaining;
        ord.amountRemaining = 0;
        if (refundAmount > 0) {
            IERC20(ord.tokenIn).transfer(msg.sender, refundAmount);
            emit OrderCancelled(orderId, refundAmount);
        }
    }

    // Partial fill support
    function matchOrder(uint256 orderId, uint256 fillAmount) external nonReentrant {
        require(orderId < orders.length, "Invalid");
        Order storage ord = orders[orderId];
        require(ord.active, "Inactive");
        require(allowedTokens[ord.tokenIn] && allowedTokens[ord.tokenOut], "Tokens not allowed");
        require(block.timestamp < ord.expiresAt, "Expired");
        require(fillAmount > 0 && fillAmount <= ord.amountRemaining, "Invalid fill");

        // Calculate tokenOut required (proportional to fill)
        uint256 nFillAmount = normalize(ord.tokenIn, fillAmount);
        uint256 nTokenOut = nFillAmount * ord.rate / 1e18;
        uint256 tokenOutAmount = denormalize(ord.tokenOut, nTokenOut);

        uint256 fee = tokenOutAmount * swapFeeBps / 10000;
        uint256 takerGets = tokenOutAmount - fee;
        require(takerGets > 0, "Too small");

        // Take tokenOut from taker, reward maker
        IERC20(ord.tokenOut).transferFrom(msg.sender, address(this), tokenOutAmount);
        IERC20(ord.tokenOut).transfer(ord.maker, takerGets);
        if (fee > 0) IERC20(ord.tokenOut).transfer(feeRecipient, fee);

        // Send tokenIn to taker
        IERC20(ord.tokenIn).transfer(msg.sender, fillAmount);

        // Update order
        ord.amountRemaining -= fillAmount;
        if (ord.amountRemaining == 0) ord.active = false;

        emit OrderMatched(orderId, msg.sender, fillAmount, tokenOutAmount, fee);
    }
}
