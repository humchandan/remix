// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
// FIX: In OpenZeppelin v5, ReentrancyGuard is in /utils/, not /security/
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

contract INR1Token is ERC20, AccessControl, ReentrancyGuard {
    // Roles
    bytes32 public constant ADMIN_ROLE = DEFAULT_ADMIN_ROLE;
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant BURNER_ROLE = keccak256("BURNER_ROLE");

    // Blacklist mapping
    mapping(address => bool) public blacklisted;

    // Events
    event Blacklisted(address indexed account, bool isBlacklisted);
    event Minted(address indexed to, uint256 amount);
    event Burned(address indexed from, uint256 amount);

    constructor(address admin) ERC20("INR1 Stable", "INR1") {
        require(admin != address(0), "Zero admin");
        _grantRole(ADMIN_ROLE, admin);
        
        // Grant admin all roles initially so they can manage the system
        _grantRole(MINTER_ROLE, admin);
        _grantRole(BURNER_ROLE, admin);

        // Premint 6 billion INR1 to admin
        _mint(admin, 6_000_000_000 ether); 
        emit Minted(admin, 6_000_000_000 ether);
    }

    // --- Security Modifier ---
    modifier notBlacklisted(address account) {
        require(!blacklisted[account], "Account is blacklisted");
        _;
    }

    // --- Admin Functions ---
    function setBlacklisted(address account, bool value)
        external
        onlyRole(ADMIN_ROLE)
    {
        blacklisted[account] = value;
        emit Blacklisted(account, value);
    }

    // --- Minting ---
    function mint(address to, uint256 amount)
        external
        onlyRole(MINTER_ROLE)
        notBlacklisted(to)
        nonReentrant
    {
        _mint(to, amount);
        emit Minted(to, amount);
    }

    // --- FORCED BURN (Seizure) ---
    // This restores utility to the BURNER_ROLE. 
    // It allows the issuer to destroy tokens held by blacklisted/criminal accounts.
    function burn(address from, uint256 amount)
        external
        onlyRole(BURNER_ROLE)
        nonReentrant
    {
        _burn(from, amount);
        emit Burned(from, amount);
    }
   
    // --- Hook: Checks Blacklist on Transfer/Mint/Burn ---
    function _update(address from, address to, uint256 value) internal override {
        // 1. Check Sender (unless minting)
        if (from != address(0)) {
            require(!blacklisted[from], "Sender blacklisted");
        }
        
        // 2. Check Receiver (unless burning)
        if (to != address(0)) {
            require(!blacklisted[to], "Receiver blacklisted");
        }

        super._update(from, to, value);
    }

    // --- Emergency Rescue ---
    function rescueERC20(address token, address to, uint256 amount)
        external
        onlyRole(ADMIN_ROLE)
        nonReentrant
    {
        require(token != address(this), "Cannot rescue INR1"); 
        require(to != address(0), "Zero to");
        IERC20(token).transfer(to, amount);
    }
}