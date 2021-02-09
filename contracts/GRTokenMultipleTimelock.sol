pragma solidity 0.6.12;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";

import "./IAdminController.sol";


contract GRTokenMultipleTimelock {
    using SafeERC20 for IERC20;

    event Created (
        uint256 indexed id,
        address beneficiary,
        uint256 amount, 
        uint256 releaseTime
    );

    event Released (
        uint256 indexed id,
        address beneficiary,
        uint256 amount
    );

    event Deleted (
        uint256 indexed id
    );

    event Updated (
        uint256 indexed id,
        address beneficiary,
        uint256 amount, 
        uint256 releaseTime
    );

    // Lock elements
    struct Lock {
        address beneficiary;
        bool isReleased;
        uint256 amount;
        uint256 releaseTime;
    }

    // Locks (id => Lock)
    mapping (uint256 => Lock) private _locks; 

    // GR token
    IERC20 private _grToken;

    // Admin Controller
    IAdminController private _adminController;

    /**
     * @dev Check permission of administrator. Implementation is within the AdminController contract.
     * Data will be used for future extension.
     */
    modifier onlyAdmin(bytes memory data) {
        require(_adminController.isAdmin(msg.sender, data), "Caller is not the Admin");
        _;
    }


    /**
     * @dev Constuctor
     * 
     * Arguments:
     *  - grToken_: Contract address of GR token
     *  - adminController_: Contract address of AdminController
     */    
    constructor(IERC20 grToken_, IAdminController adminController_) public {
        _grToken = grToken_;
        _adminController = adminController_;
    }

    /**
     * @dev Change the Admin Controller Contract.
     * 
     * The target controller must implement IAdminController interface to check whether the caller is admin or not.
     */    
    function setAdminContoller(IAdminController adminController_, bytes memory data) public onlyAdmin(data) {
        _adminController = adminController_;
    }

    /**
     * @dev Create new lock.
     * 
     * Arguments
     *   - id: identifier of the lock. Any locks must have different id.
     *   - beneficiary: address where the token will be transfered when the lock is released.
     *   - amount: amount of the token to be transfered
     *   - releaseTime: Until this time, lock cannot be released. Specify in unixtime.
     */
    function lock(uint256 id, address beneficiary, uint256 amount, uint256 releaseTime, bytes memory data) public onlyAdmin(data) {
        // Argument validations
        _validateLockParameters(beneficiary, amount, releaseTime);
        require(!_isLockExists(id), "Token lock already exists");

        // Transfer the specified amount of token to this contract
        _grToken.safeTransferFrom(msg.sender, address(this), amount);

        // Save lock information
        // isReleased is set to false
        _locks[id] = Lock(beneficiary, false, amount, releaseTime);

        // Emit create event
        emit Created(id, beneficiary, amount, releaseTime);
    }

    /**
     * @dev Release the designated lock.
     * Once release succeed, locked amount is transfered to the recipient which specified in the lock.
     * Anyone can release any locks, but current timestamp must exceed the release time of the target lock
     */
    function release(uint256 id) public {
        // Argument validations
        require(_isLockExists(id), "Token lock does not exist");
        require(!_isReleased(id), "Specified lock has already been released");

        Lock storage currentLock = _locks[id];

        // Check whether current timestamp must exceed the release time of the target lock 
        require(block.timestamp >= currentLock.releaseTime, "current time is before release time");

        // Lock status update
        currentLock.isReleased = true;

        // Transfer token to the specified recipient
        _transferGrToken(currentLock.beneficiary, currentLock.amount);

        // Emit release event
        emit Released(id, currentLock.beneficiary, currentLock.amount);
    }

    /**
     * @dev Change the designated lock.
     * Compare between new amount and current amount, and then transfer the difference to the appropriate address.
     *
     * OnlyAdmin can execute the function
     */
    function change(uint256 id, address newBeneficiary, uint256 newAmount, uint256 newReleaseTime, bytes memory data) public onlyAdmin(data) {
        // Argument validations
        require(_isLockExists(id), "Token lock does not exist");
        require(!_isReleased(id), "Specified lock has already been released");
        _validateLockParameters(newBeneficiary, newAmount, newReleaseTime);

        Lock storage currentLock = _locks[id];

        // Compare between new amount and current amount.
        if (newAmount > currentLock.amount) {
            // Additional token must be transfered to this contract because new amount is greater than current amount.
            _grToken.safeTransferFrom(msg.sender, address(this), newAmount - currentLock.amount);
        } else if (newAmount < currentLock.amount) {
            // Additional token must be transfered to the admin because new amount is less than current amount.
            _transferGrToken(msg.sender, currentLock.amount - newAmount);
        }

        // Save lock information
        _locks[id] = Lock(newBeneficiary, false, newAmount, newReleaseTime);

        // Emit update event
        emit Updated(id, newBeneficiary, newAmount, newReleaseTime);
    }

    /**
     * @dev Remove the designated lock.
     *
     * OnlyAdmin can execute the function
     */
    function remove(uint256 id, bytes memory data) public onlyAdmin(data) {
        // Argument validations
        require(_isLockExists(id), "Token lock does not exist");
        require(!_isReleased(id), "Specified lock has already been released");

        // Transfer removed amount to the msg.sender
        _transferGrToken(msg.sender, _locks[id].amount);

        // Delete lock object
        // After the deletion, _locks[id].beneficiary will be address(0).
        delete(_locks[id]);

        // Emit delete event
        emit Deleted(id);
    }

    /**
     * @dev View the designated Lock
     */
    function lockOf(uint256 id) public view returns (uint256, address, uint256, uint256, bool) {
        require(_isLockExists(id), "Token lock does not exist");
        return (
            id,
            _locks[id].beneficiary,
            _locks[id].amount,
            _locks[id].releaseTime,
            _locks[id].isReleased
        );
    }


    // =================================
    //       Private functions
    // =================================

    /**
     * @dev Transfer designated amount of GRtoken to designated recipient from this contract.
     * If this contract do not have sufficient balance to transfer, transaction will be reverted.
     */
    function _transferGrToken(address recipient, uint256 amount) private {
        _grToken.safeTransfer(recipient, amount);
    }

    /**
     * @dev Check whether the designated Lock exists or not.
     * If exists, return true.
     */
    function _isLockExists(uint256 id) private view returns (bool) {
        return _locks[id].beneficiary != address(0); 
    }

    /**
     * @dev Check whether the designated Lock is already released or not.
     * If already released, return true.
     */
    function _isReleased(uint256 id) private view returns (bool) {
        return _locks[id].isReleased;
    }

    /**
     * @dev Check whether this contract has sufficient token balance for token transfer
     */
    function _hasSufficientBalance(uint256 amount) private view returns (bool) {
        return _grToken.balanceOf(address(this)) >= amount;
    }

    /**
     * @dev Lock parameters validation
     */
    function _validateLockParameters(address beneficiary, uint256 amount, uint256 releaseTime) private view {
        require(beneficiary != address(0), "Could not specify Zero address as a beneficiary");
        require(amount != 0, "Could not specify 0 as a amount to be locked");
        require(releaseTime >= block.timestamp, "Could not specify 0 as release time");
    }
}
