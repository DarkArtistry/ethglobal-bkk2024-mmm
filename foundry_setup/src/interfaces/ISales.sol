pragma solidity ^0.8.20;
// src/interfaces/ISales.sol
interface ISales {
    event CommissionReceived(address indexed trader, uint256 amount);
    event CommissionWithdrawn(address indexed token, uint256 amount);
    
    function receiveCommission(address token, address trader, uint256 commission) external payable;
    function withdrawCommission(address token) external;
}