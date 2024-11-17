pragma solidity ^0.8.20;
// src/interfaces/ITrade.sol
interface ITrade {
    event TradeExecuted(
        address indexed user,
        address indexed tokenIn,
        address indexed tokenOut,
        uint256 amountIn,
        uint256 amountOut
    );
    
    function executeTrade(
        string memory dexName,
        address tokenIn,
        address tokenOut,
        uint256 amountIn,
        uint256 amountOutMin,
        uint256 deadline,
        address trader
    ) external returns (uint256 amountOut);
}