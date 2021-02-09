pragma solidity 0.6.12;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";


contract BatchTransfer is Ownable {
	using SafeERC20 for IERC20;

	function batchTransfer(IERC20 erc20, address[] calldata addrs, uint[] calldata values) external onlyOwner {
		require( addrs.length == values.length, "number of addresses and valued were mismatched.");
		for(uint i=0; i<addrs.length; i++ ) {
			erc20.safeTransferFrom(msg.sender, addrs[i], values[i]);
		}
	}
}
