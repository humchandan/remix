// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import { PRBMathUD60x18 } from "prb-math/PRBMathUD60x18.sol";

contract RobustHybridExchange is AccessControl, ReentrancyGuard {
    using PRBMathUD60x18 for uint256;

    bytes32 public constant SUBADMIN_ROLE = keccak256("SUBADMIN_ROLE");

    uint256 public swapFeeBps = 50; // 0.5% default
    address public feeRecipient;

    mapping(address => bool) public allowedTokens;
    mapping(address => mapping(address => uint256)) public globalRates;

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

    event TokenWhitelistUpdated(address indexed token, bool allowed);
    event GlobalRateSet(address indexed tokenIn, address indexed tokenOut, uint256 rate);
    event OrderCreated(uint256 indexed orderId, address indexed maker, address tokenIn, address tokenOut, uint256 amountInitial, uint256 rate, uint256 expiresAt);
    event OrderMatched(uint256 indexed orderId, address indexed taker, uint256 fillAmount, uint256 outAmount, uint256 fee);
    event OrderCancelled(uint256 indexed orderId, uint256 amountRefunded);
    event OrderPruned(uint256 indexed orderId);
    event SwapGlobal(address indexed sender, address indexed tokenIn, address indexed tokenOut, uint256 amountIn, uint256 amountOut, uint256 fee);
    event FeeUpdated(uint256 oldFeeBps, uint256 newFeeBps);
    event FeeRecipientUpdated(address oldRecipient, address newRecipient);
    event EmergencyWithdraw(address indexed token, uint256 amount, address indexed to);

    constructor(address _feeRecipient) {
        require(_feeRecipient != address(0), "Fee recipient required");
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        feeRecipient = _feeRecipient;
    }

    // Admin controls and modifiers omitted for brevity (same as before)...

    // --------- Precision Loss Mitigation with PRBMath (18 decimals) ----------

    function normalize(address token, uint256 amount) public view returns (uint256) {
        uint8 decimals = getDecimals(token);
        if (decimals == 18) return amount;
        if (decimals < 18) return amount * (10 ** (18 - decimals));
        // If more than 18 decimals, divide with rounding up to favor user
        return (amount + (10 ** (decimals - 18) - 1)) / 10 ** (decimals - 18);
    }

    function denormalize(address token, uint256 nAmount) public view returns (uint256) {
        uint8 decimals = getDecimals(token);
        if (decimals == 18) return nAmount;
        if (decimals < 18) return (nAmount + (10 ** (18 - decimals) - 1)) / 10 ** (18 - decimals);
        // If more than 18 decimals, multiply
        return nAmount * (10 ** (decimals - 18));
    }

    function mul18(uint256 a, uint256 b) internal pure returns (uint256) {
        // Scaled mul: (a * b) / 1e18, using PRBMath for exact rounding
        return PRBMathUD60x18.mul(a, b);
    }

    // --------- Global Pool: Instant Admin Swaps (using PRBMath) ---------

    function swapGlobal(address tokenIn, address tokenOut, uint256 amountIn) external nonReentrant {
        require(allowedTokens[tokenIn] && allowedTokens[tokenOut], "Tokens not allowed");
        uint256 rate = globalRates[tokenIn][tokenOut];
        require(rate > 0, "No global rate");

        uint256 nAmountIn = normalize(tokenIn, amountIn);
        uint256 nAmountOut = mul18(nAmountIn, rate);
        uint256 amountOut = denormalize(tokenOut, nAmountOut);

        uint256 fee = amountOut * swapFeeBps / 10000;
        uint256 receiverGets = amountOut - fee;
        require(receiverGets > 0, "Amount too small");

        IERC20(tokenIn).transferFrom(msg.sender, address(this), amountIn);
        IERC20(tokenOut).transfer(msg.sender, receiverGets);
        if (fee > 0) IERC20(tokenOut).transfer(feeRecipient, fee);

        emit SwapGlobal(msg.sender, tokenIn, tokenOut, amountIn, receiverGets, fee);
    }

    // --------- Orderbook: Custom Orders, Partial Fills, Expiration, Slippage ---------

    // Slippage protection: minOutAmount
    function matchOrder(uint256 orderId, uint256 fillAmount, uint256 minOutAmount) external nonReentrant {
        require(orderId < orders.length, "Invalid");
        Order storage ord = orders[orderId];
        require(ord.active, "Inactive");
        require(allowedTokens[ord.tokenIn] && allowedTokens[ord.tokenOut], "Tokens not allowed");
        require(block.timestamp < ord.expiresAt, "Expired");
        require(fillAmount > 0 && fillAmount <= ord.amountRemaining, "Invalid fill");

        uint256 nFillAmount = normalize(ord.tokenIn, fillAmount);
        uint256 nTokenOut = mul18(nFillAmount, ord.rate);
        uint256 tokenOutAmount = denormalize(ord.tokenOut, nTokenOut);

        uint256 fee = tokenOutAmount * swapFeeBps / 10000;
        uint256 takerGets = tokenOutAmount - fee;
        require(takerGets > 0, "Too small");
        require(takerGets >= minOutAmount, "Slippage too high");

        IERC20(ord.tokenOut).transferFrom(msg.sender, address(this), tokenOutAmount);
        IERC20(ord.tokenOut).transfer(ord.maker, takerGets);
        if (fee > 0) IERC20(ord.tokenOut).transfer(feeRecipient, fee);

        IERC20(ord.tokenIn).transfer(msg.sender, fillAmount);

        ord.amountRemaining -= fillAmount;
        if (ord.amountRemaining == 0) ord.active = false;

        emit OrderMatched(orderId, msg.sender, fillAmount, tokenOutAmount, fee);
    }

    // Partial fill cancellation
    function cancelRemaining(uint256 orderId) external nonReentrant {
        require(orderId < orders.length, "Invalid");
        Order storage ord = orders[orderId];
        require(ord.maker == msg.sender && ord.active, "Unauthorized");
        require(ord.amountRemaining < ord.amountInitial, "Must be partially filled");

        uint256 refund = ord.amountRemaining;
        ord.amountRemaining = 0;
        ord.active = false;
        IERC20(ord.tokenIn).transfer(msg.sender, refund);

        emit OrderCancelled(orderId, refund);
    }

    // Order auto-pruning by anyone
    function pruneExpiredOrder(uint256 orderId) external nonReentrant {
        require(orderId < orders.length, "Invalid");
        Order storage ord = orders[orderId];
        require(ord.active && block.timestamp >= ord.expiresAt, "Not expired");
        ord.active = false;
        emit OrderPruned(orderId);
    }

    // (existing order creation/cancel functions unchanged except events and modifiers as above)

    // --------- Enhanced Admin Events ---------

    function setFeeRecipient(address recipient) external onlyAdminOrSub {
        require(recipient != address(0), "Zero address");
        emit FeeRecipientUpdated(feeRecipient, recipient);
        feeRecipient = recipient;
    }

    function emergencyWithdraw(address token) external onlyAdminOrSub {
        uint256 bal = IERC20(token).balanceOf(address(this));
        require(bal > 0, "Nothing to withdraw");
        IERC20(token).transfer(msg.sender, bal);
        emit EmergencyWithdraw(token, bal, msg.sender);
    }

    // --------- Utility ---------
    function getDecimals(address token) public view returns (uint8) {
        return IERC20Metadata(token).decimals();
    }
}

