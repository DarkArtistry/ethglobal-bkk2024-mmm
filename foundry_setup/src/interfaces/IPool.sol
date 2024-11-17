// src/interfaces/IPool.sol
pragma solidity ^0.8.20;
import "./IDEXAdapter.sol";
interface IPool {
    event FundsReceived(address indexed token, uint256 amount);
    event FundsWithdrawn(address indexed token, uint256 amount);
    
    function executeSwapWithAdapter(IDEXAdapter adapter, address tokenIn, address tokenOut, uint256 amountIn, uint256 amountOutMin, uint256 deadline, address trader) external returns (uint256 amountOut);
    function receiveFundsERC20(address token, uint256 amount) external;
    function withdrawFundsERC20(address token, uint256 amount) external;
    function provideLiquidity(address pool, address token, uint256 amount) external;
    function removeLiquidity(address pool, address token, uint256 amount) external;
}