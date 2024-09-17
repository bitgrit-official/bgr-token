// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts ^5.0.0
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";

contract BGR is ERC20, ERC20Burnable, ERC20Permit {
    constructor() ERC20("BGR", "BGR") ERC20Permit("BGR") {
        _mint(msg.sender, 10000000000 * 10 ** decimals());
    }
}
