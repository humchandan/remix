// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

interface IERC20Metadata {
    function decimals() external view returns (uint8);
}

contract GenesisPool is Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    uint8 constant MAX_DIRECT_REFERRALS = 36;
    uint8 constant REFERRAL_LEVELS = 7;
    uint256[REFERRAL_LEVELS] public REFERRAL_PERCENTS = [
        300, 200, 100, 100, 100, 50, 25
    ];
    uint256 constant WITHDRAWAL_CAP_MULTIPLIER = 3;
    uint256 constant MIN_REFERRAL_CLAIM = 1000e18;

    IERC20 public INR1;
    IERC20 public USD1;
    address public subadmin;
    uint8 public inrDecimals;
    uint8 public usdDecimals;
    uint256 public usdInrParity = 90;

    mapping(address => bool) public tokenWhitelist;
    address public pendingINR1;
    address public pendingUSD1;
    bool public inr1UpdatePending;
    bool public usd1UpdatePending;

    // INGOT logic
    uint256 public constant INGOTS_POOL_MAX = 100;
    uint256 public constant INR1_PER_INGOT = 1000 * 1e18; // 18 decimals
    uint256 public constant USD1_PER_INGOT = 11 * 1e18;   // 18 decimals

    struct Pool {
        uint256 poolId;
        string poolType;
        uint256 currentFill;      // Number of INGOTS in pool
        bool isActive;
        bool paidOut;
        uint256 totalInvested;    // in token units (18 decimals)
    }
    mapping(uint256 => Pool) public pools;
    uint256 public lastCreatedPoolId;
    uint256 public totalInvestedAllPools;

    struct Order {
        uint256 orderNo;
        address user;
        uint256 investedAmount;
        uint256 interest;
        string paymentToken;
        bool paidOut;
    }
    mapping(uint256 => Order[]) public poolOrders;

    struct User {
        address referrer;
        address[REFERRAL_LEVELS] uplines;
        address[] downlines;
        uint256 invested;
        uint256 referralRewardTotal;
        uint256 referralWithdrawn;
        bool registered;
    }
    mapping(address => User) public users;

    mapping(address => uint256) public pendingINR1Payout;
    mapping(address => bool) public isBlacklisted;
    bool public emergencyActive;
    uint256 public reserveTreasury;
    uint256 public operationalTreasury;

    uint256 public constant MAX_POOL_ID = 1_000_000_000;

    event TreasuryFunded(string treasury, uint256 amount, string token);
    event TreasuryWithdraw(string treasury, uint256 amount);
    event PoolAdded(uint256 indexed poolId, string poolType);
    event PoolClosed(uint256 indexed poolId, uint256 totalInvested);
    event PoolActivated(uint256 poolId, string poolType);
    event PoolJoined(address indexed user, uint256 poolId, uint256 orderNo, uint256 ingots, string paymentToken);
    event PaidOut(address indexed user, uint256 poolId, uint256 orderNo, uint256 reward);
    event ReferralRewardClaimed(address indexed user, uint256 amount);
    event EmergencyActivated(bool flag);
    event INRTOKENUpdated(address newAddr);
    event USDTOKENUpdated(address newAddr);
    event ParityUpdated(uint256 newParity);
    event ReferralStatus(address indexed user, uint256 totalEarned, uint256 claimable, uint256 withdrawn, uint256 cap);
    event PoolStatus(address indexed user, uint256 pendingReward, bool canWithdraw);
    event ReferrerChanged(address indexed user, address indexed oldReferrer, address indexed newReferrer);

    modifier payInAllowed() { require(!emergencyActive, "Emergency: No deposits"); _; }
    modifier onlySubadmin() { require(msg.sender == subadmin, "Not subadmin"); _; }
    modifier onlySubadminOrOwner() { require(msg.sender == owner() || msg.sender == subadmin, "Not admin or subadmin"); _; }

    constructor(address _subadmin, address _inr1, address _usd1) Ownable(msg.sender) {
        require(_subadmin != address(0), "Subadmin required");
        require(_inr1 != address(0) && _usd1 != address(0), "Tokens required");
        subadmin = _subadmin;
        INR1 = IERC20(_inr1);
        USD1 = IERC20(_usd1);
        inrDecimals = IERC20Metadata(_inr1).decimals();
        usdDecimals = IERC20Metadata(_usd1).decimals();
        tokenWhitelist[_inr1] = true;
        tokenWhitelist[_usd1] = true;

        // Init 9 Standard + 3 Lottery pools
        uint256 poolCounter = 1;
        for (; poolCounter <= 9; ++poolCounter) {
            pools[poolCounter] = Pool(poolCounter, "Standard", 0, true, false, 0);
            emit PoolAdded(poolCounter, "Standard");
        }
        for (; poolCounter <= 12; ++poolCounter) {
            pools[poolCounter] = Pool(poolCounter, "Lottery", 0, true, false, 0);
            emit PoolAdded(poolCounter, "Lottery");
        }
        lastCreatedPoolId = poolCounter - 1;
    }
        // Owner can update INR1 contract address
function setINR1(address newINR1) external onlyOwner {
    require(newINR1 != address(0), "Zero address");
    INR1 = IERC20(newINR1);
    inrDecimals = IERC20Metadata(newINR1).decimals();
    tokenWhitelist[newINR1] = true;
    emit INRTOKENUpdated(newINR1);
}

// Owner can update USD1 contract address
function setUSD1(address newUSD1) external onlyOwner {
    require(newUSD1 != address(0), "Zero address");
    USD1 = IERC20(newUSD1);
    usdDecimals = IERC20Metadata(newUSD1).decimals();
    tokenWhitelist[newUSD1] = true;
    emit USDTOKENUpdated(newUSD1);
}

    // Public registration - must be called before staking/joinPool
    function register(address referrer) external {
        require(!users[msg.sender].registered, "Already registered");
        require(referrer == address(0) || users[referrer].registered, "Referrer must be registered");
        require(referrer != msg.sender, "Cannot refer self");
        if (referrer != address(0)) {
            require(users[referrer].downlines.length < MAX_DIRECT_REFERRALS, "Direct referral cap reached");
            users[referrer].downlines.push(msg.sender);
        }
        users[msg.sender].registered = true;
        users[msg.sender].referrer = referrer;
        address upline = referrer;
        for (uint8 i = 0; i < REFERRAL_LEVELS; i++) {
            users[msg.sender].uplines[i] = upline;
            if (upline == address(0)) break;
            upline = users[upline].referrer;
        }
    }


    function forceCreatePool(uint256 poolId, string memory poolType) external onlyOwner {
    require(poolId > 0 && poolId <= MAX_POOL_ID, "PoolId out of range");
    require(bytes(poolType).length > 0, "poolType required");
    require(pools[poolId].poolId == 0, "Pool already exists");

    pools[poolId] = Pool(
        poolId,
        poolType,
        0,
        true,
        false,
        0
    );

    if (poolId > lastCreatedPoolId) {
        lastCreatedPoolId = poolId;
    }
    emit PoolAdded(poolId, poolType);
}

    function changeReferrer(address user, address newReferrer) external onlyOwner {
        require(user != newReferrer, "Cannot refer self");
        require(users[user].registered, "User must be registered");
        require(newReferrer == address(0) || users[newReferrer].registered, "Referrer must be registered");
        address oldRef = users[user].referrer;
        users[user].referrer = newReferrer;
        address upline = newReferrer;
        for (uint8 i = 0; i < REFERRAL_LEVELS; i++) {
            users[user].uplines[i] = upline;
            if (upline == address(0)) break;
            upline = users[upline].referrer;
        }
        emit ReferrerChanged(user, oldRef, newReferrer);
    }
        function setTokenDecimals(uint8 _inrDecimals, uint8 _usdDecimals) external onlyOwner {
    inrDecimals = _inrDecimals;
    usdDecimals = _usdDecimals;
}


    // User must be registered before joining/staking in pool
    function joinPool(uint256 poolId, uint256 amount, bool useUSD)
        external payInAllowed nonReentrant
    {
        require(users[msg.sender].registered, "Not registered");
        require(!isBlacklisted[msg.sender], "Blacklisted");
        address depositToken = useUSD ? address(USD1) : address(INR1);
        require(tokenWhitelist[depositToken], "Token not whitelisted");

        // ---- INGOT LOGIC ----
        uint256 ingots;
        if (useUSD) {
            require(amount >= USD1_PER_INGOT, "Below min stake (USD1)");
            require(USD1.balanceOf(msg.sender) >= amount, "Insufficient USD1");
            USD1.safeTransferFrom(msg.sender, address(this), amount);
            ingots = amount / USD1_PER_INGOT;
        } else {
            require(amount >= INR1_PER_INGOT, "Below min stake (INR1)");
            require(INR1.balanceOf(msg.sender) >= amount, "Insufficient INR1");
            INR1.safeTransferFrom(msg.sender, address(this), amount);
            ingots = amount / INR1_PER_INGOT;
        }
        require(ingots > 0, "Minimum is 1 ingot");
        Pool storage pool = pools[poolId];
        require(pool.isActive, "Pool not active");
        require(pool.currentFill + ingots <= INGOTS_POOL_MAX, "Pool full");
        users[msg.sender].invested += amount;

        // Update pool filling and invested amount
        pool.totalInvested += amount;
        pool.currentFill += ingots;
        totalInvestedAllPools += amount;
        poolOrders[poolId].push(Order(pool.currentFill, msg.sender, amount, 10, useUSD ? "USD1" : "INR1", false));

        uint256 reserveAmt = (amount * 5) / 100;
        uint256 operationalAmt = (amount * 95) / 100;
        reserveTreasury += reserveAmt;
        operationalTreasury += operationalAmt;

        emit PoolJoined(msg.sender, poolId, pool.currentFill, ingots, useUSD ? "USD1" : "INR1");
        _distributeReferralRewards(msg.sender, amount);

        if (pool.currentFill == INGOTS_POOL_MAX && poolId < MAX_POOL_ID) {
    pools[poolId].isActive = false;
    emit PoolClosed(poolId, pools[poolId].totalInvested);

    // Only create the truly next available pool, never overwriting or reusing IDs
    uint256 nextPoolId = lastCreatedPoolId + 1;
    require(pools[nextPoolId].poolId == 0, "Next pool already exists"); // Strict: NEVER re-create

    pools[nextPoolId] = Pool(
        nextPoolId,
        nextPoolId <= 9 ? "Standard" : "Lottery",
        0,
        true,
        false,
        0
    );
    lastCreatedPoolId = nextPoolId; // Only increase counter here!
    emit PoolAdded(nextPoolId, pools[nextPoolId].poolType);
}


    }

    function _distributeReferralRewards(address user, uint256 amount) internal {
        for (uint8 i = 0; i < REFERRAL_LEVELS; i++) {
            address upline = users[user].uplines[i];
            if (upline == address(0)) break;
            uint256 reward = (amount * REFERRAL_PERCENTS[i]) / 10000;
            users[upline].referralRewardTotal += reward;
            emit ReferralStatus(
                upline,
                users[upline].referralRewardTotal,
                getClaimableReferral(upline),
                users[upline].referralWithdrawn,
                users[upline].invested * WITHDRAWAL_CAP_MULTIPLIER
            );
        }
    }

    function getClaimableReferral(address user) public view returns (uint256) {
        User storage u = users[user];
        uint256 cap = u.invested * WITHDRAWAL_CAP_MULTIPLIER;
        uint256 claimable = u.referralRewardTotal - u.referralWithdrawn;
        if (u.referralWithdrawn + claimable > cap) {
            claimable = cap - u.referralWithdrawn;
        }
        return claimable;
    }
    function withdrawReferralReward() external nonReentrant {
        User storage user = users[msg.sender];
        uint256 claimable = getClaimableReferral(msg.sender);
        require(claimable >= MIN_REFERRAL_CLAIM, "Not enough to claim");
        user.referralWithdrawn += claimable;
        require(INR1.balanceOf(address(this)) >= claimable, "Insufficient INR1");
        INR1.safeTransfer(msg.sender, claimable);
        emit ReferralRewardClaimed(msg.sender, claimable);
        emit ReferralStatus(msg.sender, user.referralRewardTotal, getClaimableReferral(msg.sender), user.referralWithdrawn, user.invested * WITHDRAWAL_CAP_MULTIPLIER);
    }

    function triggerPayout(uint256 poolId) external onlyOwner nonReentrant {
        Pool storage pool = pools[poolId];
        require(pool.currentFill > 0, "Pool not filled");
        require(!pool.paidOut, "Already paid out");
        uint256 coverage = (operationalTreasury + reserveTreasury) * 100 / totalInvestedAllPools;
        require(coverage >= 60, "Insufficient advance funds (min 60%)");
        for (uint256 i = 0; i < poolOrders[poolId].length; ++i) {
            Order storage order = poolOrders[poolId][i];
            if (order.paidOut || order.investedAmount == 0) continue;
            uint256 principal = order.investedAmount;
            uint256 interest = (principal * order.interest) / 100;
            uint256 payout = principal + interest;
            uint256 fee2 = (payout * 2) / 100;
            reserveTreasury += fee2;
            pendingINR1Payout[order.user] += payout - fee2;
            order.paidOut = true;
            emit PaidOut(order.user, poolId, order.orderNo, payout - fee2);
            emit PoolStatus(order.user, pendingINR1Payout[order.user], true);
        }
        pool.paidOut = true;
        pool.isActive = false;
    }

    function getClaimablePoolReward(address user) external view returns (uint256) {
        return pendingINR1Payout[user];
    }
    function withdrawReward() external nonReentrant {
        uint256 payout = pendingINR1Payout[msg.sender];
        require(payout > 0, "No payout");
        pendingINR1Payout[msg.sender] = 0;
        require(INR1.balanceOf(address(this)) >= payout, "Insufficient INR1 balance");
        INR1.safeTransfer(msg.sender, payout);
        emit PoolStatus(msg.sender, 0, false);
    }

    function setEmergencyActive(bool flag) external onlyOwner {
        emergencyActive = flag;
        emit EmergencyActivated(flag);
    }
    function adminWithdrawReserve(uint256 amount) external onlyOwner {
        require(amount <= reserveTreasury, "Not enough reserve treasury");
        reserveTreasury -= amount;
        INR1.safeTransfer(msg.sender, amount);
        emit TreasuryWithdraw("Reserve", amount);
    }
    function adminSweepToken(address token, uint256 amount, address to) external onlyOwner {
    require(IERC20(token).balanceOf(address(this)) >= amount, "Insufficient token in contract");
    IERC20(token).safeTransfer(to, amount);
    emit TreasuryWithdraw("AdminSweep", amount);
}

    function adminWithdrawOperational(uint256 amount) external onlyOwner {
        require(amount <= operationalTreasury, "Not enough operational treasury");
        operationalTreasury -= amount;
        INR1.safeTransfer(msg.sender, amount);
        emit TreasuryWithdraw("Operational", amount);
    }

    function getActivePoolId() public view returns (uint256) {
        for (uint256 pid = lastCreatedPoolId; pid >= 1; pid--) {
            if (pools[pid].isActive) {
                return pid;
            }
        }
        return 0;
    }
    function getNextPoolId() public view returns (uint256) {
        uint256 possible = lastCreatedPoolId + 1;
        if (possible <= MAX_POOL_ID) {
            return possible;
        }
        return 0;
    }
}
