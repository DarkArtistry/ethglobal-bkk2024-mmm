// src/Sales.sol
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./interfaces/ISales.sol";

contract Sales is ISales, Ownable, ReentrancyGuard {
    IERC20 public mvmToken;
    
    // Distribution cycle tracking
    uint256 public currentCycle;
    uint256 public lastDistributionTime;
    uint256 public distributionCooldown = 24 hours;
    uint256 public minimumDistributionAmount = 0.1 ether;

    // Holder tracking
    mapping(address => mapping(address => uint256)) public commissions; // token => trader => commission
    mapping(address => mapping(address => uint256)) public lastClaimedCycle; // token => trader => cycle
    mapping(address => mapping(uint256 => uint256)) public cycleCommission; // token => cycle => commission
    mapping(address => mapping(uint256 => uint256)) public cycleTotalSupply; // token => cycle => total supply
    
    // Accumulated commissions
    mapping(address => uint256) public accumulatedCommission; // token => accumulated commission
    
    constructor() Ownable(msg.sender) {}
    
    receive() external payable {
        accumulatedCommission[address(0)] += msg.value; // Ether
        emit CommissionReceived(msg.sender, msg.value);
    }
    
    function receiveCommission(
        address token, 
        address trader, 
        uint256 commission
    ) external payable override nonReentrant {
        require(commission > 0, "Zero commission");
        require(trader != address(0), "Invalid trader address");
        
        // Update commission tracking
        commissions[token][trader] += commission;
        accumulatedCommission[token] += commission;
        cycleCommission[token][currentCycle] += commission;
        
        emit CommissionReceived(trader, commission);
    }
    
    function withdrawCommission(address token) external override onlyOwner {
        uint256 balance = accumulatedCommission[token];
        require(balance > 0, "No commission to withdraw");
        accumulatedCommission[token] = 0;
        if (token == address(0)) {
            (bool success, ) = owner().call{value: balance}("");
            require(success, "Transfer failed");
        } else {
            IERC20(token).transfer(owner(), balance);
        }

        emit CommissionWithdrawn(token, balance);
    }
}