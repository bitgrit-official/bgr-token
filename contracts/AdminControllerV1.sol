pragma solidity 0.6.12;

import "@openzeppelin/contracts/access/AccessControl.sol";

import "./IAdminController.sol";

/**
 * @dev AdminContoller
 *
 * This contract expects to be called from {GRTokenMultipleTimelock} Contract 
 * to check whether the caller(msg.sender) is Admin or not.
 * 
 * See also {GRTokenMultipleTimelock-onlyAdmin} modifier
 *
 * Note: This contract is based on {AccessControl} Contract from openzeppelin lirbaries.
 */
contract AdminControllerV1 is AccessControl, IAdminController{

    // Admin role selector
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    
    /**
     * @dev Automatically setup a RoleAdmin and Role by using {AccessControl}.
     * Note that msg.sender become the first admin.
     */
    constructor () public {
        _setRoleAdmin(ADMIN_ROLE, ADMIN_ROLE);
        _setupRole(ADMIN_ROLE, msg.sender);
    }

    /** 
     * @dev Check the caller is admin or not.
     * Argument "bytes data" will be used for future extension and is not used for now.
     */
    function isAdmin(address caller, bytes memory data) public override view returns (bool) {
        return hasRole(ADMIN_ROLE, caller);
    }

    /**
     * @dev Get the number of admin role member
     */
    function getAdminRoleMemberCount() public view returns (uint256) {
        return getRoleMemberCount(ADMIN_ROLE);
    }

    /**
     * @dev Get the admin address at designated index.
     */
    function getAdminRoleMemberAt(uint256 index) public view returns (address) {
        return getRoleMember(ADMIN_ROLE, index);
    }

    /**
     * @dev Grant admin role to the account. Only current admin can call this function.
     *
     * Note: grantRole() checks the caller is admin or not in the function.
     */
    function grantAdminRole(address account) public {
        grantRole(ADMIN_ROLE, account);
    }

    /**
     * @dev Revoke the account from admin role. Only current admin can call this function.
    *  Admin cannot revoke its own admin status to ensure there is at least one admin.
     *
     * Note: revokeRole() checks the caller is admin or not in the function.
     */
    function revokeAdminRole(address account) public {
        require(
            account != msg.sender, 
            "an admin cannot revoke its own admin status"
        );
        revokeRole(ADMIN_ROLE, account);
    }

}