pragma solidity ^0.8.20;

interface IDEXAdapter {
    function executeSwap(
        address tokenIn,
        address tokenOut,
        uint256 amountIn,
        uint256 amountOutMin,
        uint256 deadline,
        address recipient
    ) external returns (uint256 amountOut);

    function getDEXName() external pure returns (string memory);
    function getRouter() external view returns (address);
}