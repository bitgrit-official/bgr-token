pragma solidity 0.6.12;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/**
 * @dev GRtoken
 *
 * Specs
 *   - token: ERC20
 *   - name: bitgrit token
 *   - symbol: BGR
 *   - initial supply: 750,000,000
 *   - total supply: 750,000,000
 *   - decimals: 18
 *   - mintable: no
 *   - burnable: no
 */
contract GRToken is ERC20 {

    string constant _name = "bitgrit token";
    string constant _symbol = "BGR";
    uint256 constant _initialSupply = 750000000 * ( 10 ** 18);

    constructor() public ERC20(_name, _symbol) {
        _mint(msg.sender, _initialSupply);
    }
}
