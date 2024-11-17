// src/interfaces/IStash.sol
pragma solidity ^0.8.20;

interface IStash {
    event TokenDeposited(address indexed user, address indexed token, uint256 amount);
    event TokenWithdrawn(address indexed user, address indexed token, uint256 amount);
    event BalanceDeducted(address indexed user, address indexed token, uint256 amount);
    event TokenAdded(address indexed token);
    event TokenRemoved(address indexed token);
    
    function depositToken(address token, uint256 amount) external;
    function withdrawToken(address token, uint256 amount) external;
    function balanceOf(address user, address token) external view returns (uint256);
    function deductBalance(address user, address token, uint256 amount) external;
    function addBalance(address user, address token, uint256 amount) external;
    function getSupportedTokens() external view returns (address[] memory);
    function isTokenSupported(address token) external view returns (bool);
}