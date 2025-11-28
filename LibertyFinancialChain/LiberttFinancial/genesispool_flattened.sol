
// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


// OpenZeppelin Contracts (last updated v5.4.0) (token/ERC20/IERC20.sol)

pragma solidity >=0.4.16;

/**
 * @dev Interface of the ERC-20 standard as defined in the ERC.
 */
interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the value of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the value of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves a `value` amount of tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 value) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets a `value` amount of tokens as the allowance of `spender` over the
     * caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 value) external returns (bool);

    /**
     * @dev Moves a `value` amount of tokens from `from` to `to` using the
     * allowance mechanism. `value` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 value) external returns (bool);
}

// File: @openzeppelin/contracts/interfaces/IERC20.sol


// OpenZeppelin Contracts (last updated v5.4.0) (interfaces/IERC20.sol)

pragma solidity >=0.4.16;


// File: @openzeppelin/contracts/utils/introspection/IERC165.sol


// OpenZeppelin Contracts (last updated v5.4.0) (utils/introspection/IERC165.sol)

pragma solidity >=0.4.16;

/**
 * @dev Interface of the ERC-165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[ERC].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[ERC section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// File: @openzeppelin/contracts/interfaces/IERC165.sol


// OpenZeppelin Contracts (last updated v5.4.0) (interfaces/IERC165.sol)

pragma solidity >=0.4.16;


// File: @openzeppelin/contracts/interfaces/IERC1363.sol


// OpenZeppelin Contracts (last updated v5.4.0) (interfaces/IERC1363.sol)

pragma solidity >=0.6.2;



/**
 * @title IERC1363
 * @dev Interface of the ERC-1363 standard as defined in the https://eips.ethereum.org/EIPS/eip-1363[ERC-1363].
 *
 * Defines an extension interface for ERC-20 tokens that supports executing code on a recipient contract
 * after `transfer` or `transferFrom`, or code on a spender contract after `approve`, in a single transaction.
 */
interface IERC1363 is IERC20, IERC165 {
    /*
     * Note: the ERC-165 identifier for this interface is 0xb0202a11.
     * 0xb0202a11 ===
     *   bytes4(keccak256('transferAndCall(address,uint256)')) ^
     *   bytes4(keccak256('transferAndCall(address,uint256,bytes)')) ^
     *   bytes4(keccak256('transferFromAndCall(address,address,uint256)')) ^
     *   bytes4(keccak256('transferFromAndCall(address,address,uint256,bytes)')) ^
     *   bytes4(keccak256('approveAndCall(address,uint256)')) ^
     *   bytes4(keccak256('approveAndCall(address,uint256,bytes)'))
     */

    /**
     * @dev Moves a `value` amount of tokens from the caller's account to `to`
     * and then calls {IERC1363Receiver-onTransferReceived} on `to`.
     * @param to The address which you want to transfer to.
     * @param value The amount of tokens to be transferred.
     * @return A boolean value indicating whether the operation succeeded unless throwing.
     */
    function transferAndCall(address to, uint256 value) external returns (bool);

    /**
     * @dev Moves a `value` amount of tokens from the caller's account to `to`
     * and then calls {IERC1363Receiver-onTransferReceived} on `to`.
     * @param to The address which you want to transfer to.
     * @param value The amount of tokens to be transferred.
     * @param data Additional data with no specified format, sent in call to `to`.
     * @return A boolean value indicating whether the operation succeeded unless throwing.
     */
    function transferAndCall(address to, uint256 value, bytes calldata data) external returns (bool);

    /**
     * @dev Moves a `value` amount of tokens from `from` to `to` using the allowance mechanism
     * and then calls {IERC1363Receiver-onTransferReceived} on `to`.
     * @param from The address which you want to send tokens from.
     * @param to The address which you want to transfer to.
     * @param value The amount of tokens to be transferred.
     * @return A boolean value indicating whether the operation succeeded unless throwing.
     */
    function transferFromAndCall(address from, address to, uint256 value) external returns (bool);

    /**
     * @dev Moves a `value` amount of tokens from `from` to `to` using the allowance mechanism
     * and then calls {IERC1363Receiver-onTransferReceived} on `to`.
     * @param from The address which you want to send tokens from.
     * @param to The address which you want to transfer to.
     * @param value The amount of tokens to be transferred.
     * @param data Additional data with no specified format, sent in call to `to`.
     * @return A boolean value indicating whether the operation succeeded unless throwing.
     */
    function transferFromAndCall(address from, address to, uint256 value, bytes calldata data) external returns (bool);

    /**
     * @dev Sets a `value` amount of tokens as the allowance of `spender` over the
     * caller's tokens and then calls {IERC1363Spender-onApprovalReceived} on `spender`.
     * @param spender The address which will spend the funds.
     * @param value The amount of tokens to be spent.
     * @return A boolean value indicating whether the operation succeeded unless throwing.
     */
    function approveAndCall(address spender, uint256 value) external returns (bool);

    /**
     * @dev Sets a `value` amount of tokens as the allowance of `spender` over the
     * caller's tokens and then calls {IERC1363Spender-onApprovalReceived} on `spender`.
     * @param spender The address which will spend the funds.
     * @param value The amount of tokens to be spent.
     * @param data Additional data with no specified format, sent in call to `spender`.
     * @return A boolean value indicating whether the operation succeeded unless throwing.
     */
    function approveAndCall(address spender, uint256 value, bytes calldata data) external returns (bool);
}

// File: @openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol


// OpenZeppelin Contracts (last updated v5.3.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.20;



/**
 * @title SafeERC20
 * @dev Wrappers around ERC-20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    /**
     * @dev An operation with an ERC-20 token failed.
     */
    error SafeERC20FailedOperation(address token);

    /**
     * @dev Indicates a failed `decreaseAllowance` request.
     */
    error SafeERC20FailedDecreaseAllowance(address spender, uint256 currentAllowance, uint256 requestedDecrease);

    /**
     * @dev Transfer `value` amount of `token` from the calling contract to `to`. If `token` returns no value,
     * non-reverting calls are assumed to be successful.
     */
    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeCall(token.transfer, (to, value)));
    }

    /**
     * @dev Transfer `value` amount of `token` from `from` to `to`, spending the approval given by `from` to the
     * calling contract. If `token` returns no value, non-reverting calls are assumed to be successful.
     */
    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeCall(token.transferFrom, (from, to, value)));
    }

    /**
     * @dev Variant of {safeTransfer} that returns a bool instead of reverting if the operation is not successful.
     */
    function trySafeTransfer(IERC20 token, address to, uint256 value) internal returns (bool) {
        return _callOptionalReturnBool(token, abi.encodeCall(token.transfer, (to, value)));
    }

    /**
     * @dev Variant of {safeTransferFrom} that returns a bool instead of reverting if the operation is not successful.
     */
    function trySafeTransferFrom(IERC20 token, address from, address to, uint256 value) internal returns (bool) {
        return _callOptionalReturnBool(token, abi.encodeCall(token.transferFrom, (from, to, value)));
    }

    /**
     * @dev Increase the calling contract's allowance toward `spender` by `value`. If `token` returns no value,
     * non-reverting calls are assumed to be successful.
     *
     * IMPORTANT: If the token implements ERC-7674 (ERC-20 with temporary allowance), and if the "client"
     * smart contract uses ERC-7674 to set temporary allowances, then the "client" smart contract should avoid using
     * this function. Performing a {safeIncreaseAllowance} or {safeDecreaseAllowance} operation on a token contract
     * that has a non-zero temporary allowance (for that particular owner-spender) will result in unexpected behavior.
     */
    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 oldAllowance = token.allowance(address(this), spender);
        forceApprove(token, spender, oldAllowance + value);
    }

    /**
     * @dev Decrease the calling contract's allowance toward `spender` by `requestedDecrease`. If `token` returns no
     * value, non-reverting calls are assumed to be successful.
     *
     * IMPORTANT: If the token implements ERC-7674 (ERC-20 with temporary allowance), and if the "client"
     * smart contract uses ERC-7674 to set temporary allowances, then the "client" smart contract should avoid using
     * this function. Performing a {safeIncreaseAllowance} or {safeDecreaseAllowance} operation on a token contract
     * that has a non-zero temporary allowance (for that particular owner-spender) will result in unexpected behavior.
     */
    function safeDecreaseAllowance(IERC20 token, address spender, uint256 requestedDecrease) internal {
        unchecked {
            uint256 currentAllowance = token.allowance(address(this), spender);
            if (currentAllowance < requestedDecrease) {
                revert SafeERC20FailedDecreaseAllowance(spender, currentAllowance, requestedDecrease);
            }
            forceApprove(token, spender, currentAllowance - requestedDecrease);
        }
    }

    /**
     * @dev Set the calling contract's allowance toward `spender` to `value`. If `token` returns no value,
     * non-reverting calls are assumed to be successful. Meant to be used with tokens that require the approval
     * to be set to zero before setting it to a non-zero value, such as USDT.
     *
     * NOTE: If the token implements ERC-7674, this function will not modify any temporary allowance. This function
     * only sets the "standard" allowance. Any temporary allowance will remain active, in addition to the value being
     * set here.
     */
    function forceApprove(IERC20 token, address spender, uint256 value) internal {
        bytes memory approvalCall = abi.encodeCall(token.approve, (spender, value));

        if (!_callOptionalReturnBool(token, approvalCall)) {
            _callOptionalReturn(token, abi.encodeCall(token.approve, (spender, 0)));
            _callOptionalReturn(token, approvalCall);
        }
    }

    /**
     * @dev Performs an {ERC1363} transferAndCall, with a fallback to the simple {ERC20} transfer if the target has no
     * code. This can be used to implement an {ERC721}-like safe transfer that rely on {ERC1363} checks when
     * targeting contracts.
     *
     * Reverts if the returned value is other than `true`.
     */
    function transferAndCallRelaxed(IERC1363 token, address to, uint256 value, bytes memory data) internal {
        if (to.code.length == 0) {
            safeTransfer(token, to, value);
        } else if (!token.transferAndCall(to, value, data)) {
            revert SafeERC20FailedOperation(address(token));
        }
    }

    /**
     * @dev Performs an {ERC1363} transferFromAndCall, with a fallback to the simple {ERC20} transferFrom if the target
     * has no code. This can be used to implement an {ERC721}-like safe transfer that rely on {ERC1363} checks when
     * targeting contracts.
     *
     * Reverts if the returned value is other than `true`.
     */
    function transferFromAndCallRelaxed(
        IERC1363 token,
        address from,
        address to,
        uint256 value,
        bytes memory data
    ) internal {
        if (to.code.length == 0) {
            safeTransferFrom(token, from, to, value);
        } else if (!token.transferFromAndCall(from, to, value, data)) {
            revert SafeERC20FailedOperation(address(token));
        }
    }

    /**
     * @dev Performs an {ERC1363} approveAndCall, with a fallback to the simple {ERC20} approve if the target has no
     * code. This can be used to implement an {ERC721}-like safe transfer that rely on {ERC1363} checks when
     * targeting contracts.
     *
     * NOTE: When the recipient address (`to`) has no code (i.e. is an EOA), this function behaves as {forceApprove}.
     * Opposedly, when the recipient address (`to`) has code, this function only attempts to call {ERC1363-approveAndCall}
     * once without retrying, and relies on the returned value to be true.
     *
     * Reverts if the returned value is other than `true`.
     */
    function approveAndCallRelaxed(IERC1363 token, address to, uint256 value, bytes memory data) internal {
        if (to.code.length == 0) {
            forceApprove(token, to, value);
        } else if (!token.approveAndCall(to, value, data)) {
            revert SafeERC20FailedOperation(address(token));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     *
     * This is a variant of {_callOptionalReturnBool} that reverts if call fails to meet the requirements.
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        uint256 returnSize;
        uint256 returnValue;
        assembly ("memory-safe") {
            let success := call(gas(), token, 0, add(data, 0x20), mload(data), 0, 0x20)
            // bubble errors
            if iszero(success) {
                let ptr := mload(0x40)
                returndatacopy(ptr, 0, returndatasize())
                revert(ptr, returndatasize())
            }
            returnSize := returndatasize()
            returnValue := mload(0)
        }

        if (returnSize == 0 ? address(token).code.length == 0 : returnValue != 1) {
            revert SafeERC20FailedOperation(address(token));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     *
     * This is a variant of {_callOptionalReturn} that silently catches all reverts and returns a bool instead.
     */
    function _callOptionalReturnBool(IERC20 token, bytes memory data) private returns (bool) {
        bool success;
        uint256 returnSize;
        uint256 returnValue;
        assembly ("memory-safe") {
            success := call(gas(), token, 0, add(data, 0x20), mload(data), 0, 0x20)
            returnSize := returndatasize()
            returnValue := mload(0)
        }
        return success && (returnSize == 0 ? address(token).code.length > 0 : returnValue == 1);
    }
}

// File: @openzeppelin/contracts/utils/Context.sol


// OpenZeppelin Contracts (last updated v5.0.1) (utils/Context.sol)

pragma solidity ^0.8.20;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    function _contextSuffixLength() internal view virtual returns (uint256) {
        return 0;
    }
}

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts (last updated v5.0.0) (access/Ownable.sol)

pragma solidity ^0.8.20;


/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * The initial owner is set to the address provided by the deployer. This can
 * later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    /**
     * @dev The caller account is not authorized to perform an operation.
     */
    error OwnableUnauthorizedAccount(address account);

    /**
     * @dev The owner is not a valid owner account. (eg. `address(0)`)
     */
    error OwnableInvalidOwner(address owner);

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the address provided by the deployer as the initial owner.
     */
    constructor(address initialOwner) {
        if (initialOwner == address(0)) {
            revert OwnableInvalidOwner(address(0));
        }
        _transferOwnership(initialOwner);
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        if (owner() != _msgSender()) {
            revert OwnableUnauthorizedAccount(_msgSender());
        }
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby disabling any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        if (newOwner == address(0)) {
            revert OwnableInvalidOwner(address(0));
        }
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// File: @openzeppelin/contracts/security/ReentrancyGuard.sol


// OpenZeppelin Contracts (last updated v4.9.0) (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Returns true if the reentrancy guard is currently set to "entered", which indicates there is a
     * `nonReentrant` function in the call stack.
     */
    function _reentrancyGuardEntered() internal view returns (bool) {
        return _status == _ENTERED;
    }
}

// File: LibertyFinancialChain/LiberttFinancial/genesispool.sol


pragma solidity ^0.8.20;





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
