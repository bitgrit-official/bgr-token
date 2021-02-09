pragma solidity 0.6.12;

/**
 * @dev Interface of AdminContoller Contract
 *
 * AdminController must be implement isAdmin() function to return the caller is admin ot not as boolean value.
 * If the caller is the admin, then return true. If not, return false.
 */
interface IAdminController {

    /**
     * @dev Return the caller is admin ot not as boolean value.
     * Second argument is expected to be used for future extension.
     */
    function isAdmin(address caller, bytes memory data) external view returns (bool);
}