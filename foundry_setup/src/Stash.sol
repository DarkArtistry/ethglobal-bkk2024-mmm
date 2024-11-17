// src/Stash.sol
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "forge-std/console.sol";
import "./interfaces/IStash.sol";
import "./interfaces/IPool.sol";

contract Stash is IStash, Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    // Token balances: user => token => amount
    mapping(address => mapping(address => uint256)) private _balances;
    
    // List of supported tokens
    address[] public supportedTokens;
    mapping(address => bool) public isSupported;
    
    IPool public pool;
    
    constructor(address _pool) Ownable(msg.sender) {
        pool = IPool(_pool);
    }
    
    // Modifier to check if token is supported
    modifier onlySupportedToken(address token) {
        require(isSupported[token], "Token not supported");
        _;
    }
    
    // Admin functions to manage supported tokens
    function addSupportedToken(address token) external onlyOwner {
        require(!isSupported[token], "Token already supported");
        
        if (token == address(0)) {
            // Special case for ETH
            isSupported[token] = true;
            supportedTokens.push(token);
            emit TokenAdded(token);
        } else {
            // For ERC20 tokens
            console.log("Token Supply: ", token);
            console.log("Token Supply: ", IERC20(token).totalSupply());

            require(IERC20(token).totalSupply() >= 0, "Invalid ERC20 token");
            isSupported[token] = true;
            supportedTokens.push(token);
            emit TokenAdded(token);
        }
    }

    function removeSupportedToken(address token) external onlyOwner {
        require(isSupported[token], "Token not supported");
        
        isSupported[token] = false;
        
        // Remove from supportedTokens array
        for (uint i = 0; i < supportedTokens.length; i++) {
            if (supportedTokens[i] == token) {
                supportedTokens[i] = supportedTokens[supportedTokens.length - 1];
                supportedTokens.pop();
                break;
            }
        }
        
        emit TokenRemoved(token);
    }
    
    // View functions
    function getSupportedTokens() external view override returns (address[] memory) {
        return supportedTokens;
    }
    
    function isTokenSupported(address token) external view override returns (bool) {
        return isSupported[token];
    }
    
    function balanceOf(address user, address token) external view override returns (uint256) {
        return _balances[user][token];
    }

    function updatePool(address _pool) external onlyOwner {
        require(_pool != address(0), "Invalid pool address");
        pool = IPool(_pool);
    }

    // Main functions
    function depositToken(address token, uint256 amount) 
        external 
        override 
        nonReentrant 
        onlySupportedToken(token) 
    {
        require(amount > 0, "Zero amount");
        
        // Transfer tokens from user to this contract
        IERC20(token).safeTransferFrom(msg.sender, address(this), amount);
        
        // Update user balance
        _balances[msg.sender][token] += amount;
        
        // Transfer tokens to pool
        IERC20(token).safeIncreaseAllowance(address(pool), amount);  // Changed from safeApprove to safeIncreaseAllowance
        pool.receiveFundsERC20(token, amount);
        
        emit TokenDeposited(msg.sender, token, amount);
    }
    
    function withdrawToken(address token, uint256 amount)
        external
        override
        nonReentrant
        onlySupportedToken(token)
    {
        require(amount > 0, "Zero amount");
        require(_balances[msg.sender][token] >= amount, "Insufficient balance");
        
        // Update user balance
        _balances[msg.sender][token] -= amount;
        
        // Request tokens from pool
        pool.withdrawFundsERC20(token, amount);
        
        // Transfer tokens to user
        IERC20(token).safeTransfer(msg.sender, amount);
        
        emit TokenWithdrawn(msg.sender, token, amount);
    }
    
    function deductBalance(address user, address token, uint256 amount) 
        external 
        override 
        onlySupportedToken(token) 
    {
        require(msg.sender == address(pool), "Only pool can deduct");
        require(_balances[user][token] >= amount, "Insufficient balance");
        
        _balances[user][token] -= amount;
        emit BalanceDeducted(user, token, amount);
    }
    
    function addBalance(address user, address token, uint256 amount) 
        external 
        override 
        onlySupportedToken(token) 
    {
        require(msg.sender == address(pool), "Only pool can add");
        _balances[user][token] += amount;
    }
    
    // Emergency functions
    function emergencyWithdraw(address token) external onlyOwner {
        uint256 balance = IERC20(token).balanceOf(address(this));
        if (balance > 0) {
            IERC20(token).safeTransfer(owner(), balance);
        }
    }
}