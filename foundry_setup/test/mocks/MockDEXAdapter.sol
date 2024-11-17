// mocks/MockDEXAdapter.sol
pragma solidity ^0.8.20;

import "../../src/interfaces/IDEXAdapter.sol";

contract MockDEXAdapter is IDEXAdapter {
    function executeSwap(
        address,
        address,
        uint256 amountIn,
        uint256,
        uint256,
        address
    ) external override returns (uint256 amountOut) {
        // Mock swap implementation with 1% fee
        uint256 fee = (amountIn * 10) / 1000;
        return amountIn - fee;
    }

    function getDEXName() pure public returns (string memory) {
        return "MockDEX";
    }

    function getRouter() view public returns (address) {
        return address(this);
    }
}