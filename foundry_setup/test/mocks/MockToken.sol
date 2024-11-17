// mocks/MockToken.sol
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract MockToken is ERC20 {
    constructor(
        string memory name,
        string memory symbol,
        uint8 decimals,
        uint256 supply
    ) ERC20(name, symbol) {
        _mint(msg.sender, supply);
    }
}