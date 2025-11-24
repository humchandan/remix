// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;


import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract INR1Stable is ERC20, AccessControl, ReentrancyGuard {
    bytes32 public constant SUBADMIN_ROLE = keccak256("SUBADMIN_ROLE");

    // Mutable peg
    uint256 public pegNumerator;   // e.g., 92
    uint256 public pegDenominator; // e.g., 1

    // Roles and state
    address public admin;

    // Blacklist
    mapping(address => bool) public blacklisted;

    // Collateral allowlist
    mapping(address => bool) public allowedCollateral;

    // --- Events ---
    event PegChanged(
        uint256 oldNumerator,
        uint256 oldDenominator,
        uint256 newNumerator,
        uint256 newDenominator,
        address indexed changedBy
    );
    event CollateralTokenSet(address indexed token, bool allowed);
    event Blacklisted(address indexed account, bool isBlacklisted);
    event Deposited(
        address indexed user,
        address indexed collateralToken,
        uint256 collateralAmount,
        uint256 mintedINR1
    );
    event Redeemed(
        address indexed user,
        address indexed collateralToken,
        uint256 redeemedINR1,
        uint256 returnedCollateral
    );

    constructor(address _admin)
        ERC20("INR1 Stable", "INR1")
    {
        require(_admin != address(0), "Zero admin");
        _grantRole(DEFAULT_ADMIN_ROLE, _admin);
        admin = _admin;

        // Default peg: 92 INR1 per 1 USD1
        pegNumerator = 92;
        pegDenominator = 1;

        // Initial mint: 10 million INR1 to admin
        _mint(_admin, 10_000_000 ether);
    }

    // --- MODIFIER: Check blacklist ---
    modifier notBlacklisted(address account) {
        require(!blacklisted[account], "Account blacklisted");
        _;
    }

    // --- ADMIN: Set the pegging (immediate, emits event for user tracking) ---
    function setPeg(uint256 _numerator, uint256 _denominator)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        require(_numerator > 0 && _denominator > 0, "Invalid peg values");

        uint256 oldNum = pegNumerator;
        uint256 oldDen = pegDenominator;

        pegNumerator = _numerator;
        pegDenominator = _denominator;

        emit PegChanged(oldNum, oldDen, _numerator, _denominator, msg.sender);
    }

    // --- SUBADMIN: Blacklist management ---
    function setBlacklisted(address account, bool _isBlacklisted)
        external
        onlyRole(SUBADMIN_ROLE)
    {
        require(account != address(0), "Zero address");
        blacklisted[account] = _isBlacklisted;
        emit Blacklisted(account, _isBlacklisted);
    }

    // --- ADMIN/SUBADMIN: Collateral allowlist ---
    function setCollateralToken(address token, bool allowed)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
        onlyRole(SUBADMIN_ROLE)
    {
        require(token != address(0), "Zero token");
        allowedCollateral[token] = allowed;
        emit CollateralTokenSet(token, allowed);
    }

    // --- USER: Deposit collateral and mint INR1 ---
    function deposit(address collateralToken, uint256 collateralAmount)
        external
        nonReentrant
        notBlacklisted(msg.sender)
    {
        require(allowedCollateral[collateralToken], "Collateral not allowed");
        require(collateralAmount > 0, "Zero amount");

        uint256 mintAmount = (collateralAmount * pegNumerator) / pegDenominator;

        IERC20 collateral = IERC20(collateralToken);
        require(
            collateral.transferFrom(msg.sender, address(this), collateralAmount),
            "Collateral transfer failed"
        );

        _mint(msg.sender, mintAmount);

        emit Deposited(msg.sender, collateralToken, collateralAmount, mintAmount);
    }

    // --- USER: Redeem INR1 for collateral ---
    function redeem(address collateralToken, uint256 redeemAmount)
        external
        nonReentrant
        notBlacklisted(msg.sender)
    {
        require(allowedCollateral[collateralToken], "Collateral not allowed");
        require(redeemAmount > 0, "Zero amount");

        uint256 collateralAmount = (redeemAmount * pegDenominator) / pegNumerator;
        require(collateralAmount > 0, "Redeem amount too small");

        IERC20 collateral = IERC20(collateralToken);
        require(
            collateral.balanceOf(address(this)) >= collateralAmount,
            "Insufficient collateral reserve"
        );

        _burn(msg.sender, redeemAmount);
        require(
            collateral.transfer(msg.sender, collateralAmount),
            "Collateral return failed"
        );

        emit Redeemed(msg.sender, collateralToken, redeemAmount, collateralAmount);
    }

    // --- Emergency withdrawal (admin only) ---
    function rescueToken(address token, address to, uint256 amount)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        require(!allowedCollateral[token], "Cannot rescue collateral");
        require(to != address(0), "Zero recipient");
        IERC20(token).transfer(to, amount);
    }
}
