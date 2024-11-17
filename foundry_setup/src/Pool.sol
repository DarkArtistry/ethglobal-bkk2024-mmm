// src/Pool.sol
pragma solidity ^0.8.20;

import "forge-std/console.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./interfaces/IPool.sol";
import "./interfaces/IStash.sol";
import "./interfaces/ITrade.sol";
import "./interfaces/ISales.sol";
import "./interfaces/IDEXAdapter.sol";

contract Pool is IPool, Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    IStash public stash;
    ITrade public trade;
    ISales public sales;
    uint256 public constant COMMISSION_BPS = 8; // 0.08%
    
    constructor(address _stash, address _trade, address _sales) Ownable(msg.sender) {
        stash = IStash(_stash);
        trade = ITrade(_trade);
        sales = ISales(_sales);
    }
    
    function receiveFundsERC20(address token, uint256 amount) external override {
        require(msg.sender == address(stash), "Only stash can deposit");
        require(amount > 0, "Zero amount");
        
        // Transfer tokens from stash to this contract
        IERC20(token).safeTransferFrom(msg.sender, address(this), amount);
        emit FundsReceived(token, amount);
    }

    function executeSwapWithAdapter(
        IDEXAdapter adapter,
        address tokenIn,
        address tokenOut,
        uint256 amountIn,
        uint256 amountOutMin,
        uint256 deadline,
        address trader
    ) external nonReentrant returns (uint256 amountOut) {
        require(msg.sender == address(trade), "Only trade contract");
        
        console.log("msg.sender: ", msg.sender);
        // Calculate commission
        uint256 commission = (amountIn * COMMISSION_BPS) / 10000;
        uint256 tradeAmount = amountIn - commission;

        // Transfer commission tokens to sales
        IERC20(tokenIn).safeTransfer(address(sales), commission);
        sales.receiveCommission(tokenIn, trader, commission);

        // Transfer the trade amount to the adapter/router
        IERC20(tokenIn).safeTransfer(address(adapter), tradeAmount);

        // Approve adapter to spend tokens
        IERC20(tokenIn).approve(address(adapter), 0); // Reset approval
        IERC20(tokenIn).approve(address(adapter), tradeAmount);

        // Execute swap through adapter
        amountOut = adapter.executeSwap(
            tokenIn,
            tokenOut,
            tradeAmount, // this should be less comimssion
            amountOutMin,
            deadline,
            address(this)  // Pool receives the tokens
        );
        
        // Add the received tokens to trader's balance
        stash.addBalance(trader, tokenOut, amountOut);

        // Deduct from stash
        stash.deductBalance(trader, tokenIn, amountIn);
        
        console.log("amountOut: ", amountOut);
        return amountOut;
    }

    function withdrawFundsERC20(address token, uint256 amount) external override {
        require(msg.sender == address(stash), "Only stash can withdraw");
        require(amount > 0, "Zero amount");
        
        // Check pool balance
        uint256 poolBalance = IERC20(token).balanceOf(address(this));
        require(poolBalance >= amount, "Insufficient pool balance");
        
        // Transfer tokens to stash
        IERC20(token).safeTransfer(msg.sender, amount);
        emit FundsWithdrawn(token, amount);
    }
    
    function provideLiquidity(address pool, address token, uint256 amount) 
        external 
        override 
        onlyOwner 
    {
        // Implement liquidity provision logic
    }
    
    function removeLiquidity(address pool, address token, uint256 amount) 
        external 
        override 
        onlyOwner 
    {
        // Implement liquidity removal logic
    }
    
    // Emergency functions
    function emergencyWithdraw(address token) external onlyOwner {
        uint256 balance = IERC20(token).balanceOf(address(this));
        if (balance > 0) {
            IERC20(token).safeTransfer(owner(), balance);
        }
    }
}