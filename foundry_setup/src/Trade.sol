pragma solidity ^0.8.20;
// src/Trade.sol
import "forge-std/console.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/ITrade.sol";
import "./interfaces/IStash.sol";
import "./interfaces/IPool.sol";
import "./interfaces/ISales.sol";
import "./interfaces/IDEXAdapter.sol";

contract Trade is ITrade, Ownable {
    // Mapping of DEX adapters
    mapping(string => IDEXAdapter) public dexAdapters;
    // List of supported DEXes
    string[] public supportedDEXes;

    IStash public stash;
    IPool public pool;
    ISales public sales;
    uint24 public constant poolFee = 3000;
    uint256 public constant COMMISSION_BPS = 8; // 0.08%

    event DEXAdapterAdded(string indexed dexName, address adapter);
    event DEXAdapterRemoved(string indexed dexName);
    
    constructor(
        address _stash,
        address _pool,
        address _sales
    ) Ownable(msg.sender) {
        stash = IStash(_stash);
        pool = IPool(_pool);
        sales = ISales(_sales);
    }

    function updatePool(address _pool) external onlyOwner {
        require(_pool != address(0), "Invalid pool address");
        pool = IPool(_pool);
    }

    // Admin functions to manage DEX adapters
    function addDEXAdapter(string memory dexName, address adapter) external onlyOwner {
        require(adapter != address(0), "Invalid adapter address");
        require(address(dexAdapters[dexName]) == address(0), "Adapter already exists");
        
        dexAdapters[dexName] = IDEXAdapter(adapter);
        supportedDEXes.push(dexName);

        emit DEXAdapterAdded(dexName, adapter);
    }

    function removeDEXAdapter(string memory dexName) external onlyOwner {
        require(address(dexAdapters[dexName]) != address(0), "Adapter doesn't exist");
        
        delete dexAdapters[dexName];
        
        // Remove from supported DEXes array
        for (uint i = 0; i < supportedDEXes.length; i++) {
            if (keccak256(bytes(supportedDEXes[i])) == keccak256(bytes(dexName))) {
                supportedDEXes[i] = supportedDEXes[supportedDEXes.length - 1];
                supportedDEXes.pop();
                break;
            }
        }
        
        emit DEXAdapterRemoved(dexName);
    }

    // View functions
    function getSupportedDEXes() external view returns (string[] memory) {
        return supportedDEXes;
    }
    
    // Execute trade on specific DEX
    function executeTrade(
        string memory dexName,
        address tokenIn,
        address tokenOut,
        uint256 amountIn,
        uint256 amountOutMin,
        uint256 deadline,
        address trader
    ) external override onlyOwner returns (uint256 amountOut) {
        require(address(dexAdapters[dexName]) != address(0), "DEX not supported");

        IDEXAdapter adapter = dexAdapters[dexName];
        
        // Request pool to execute the trade using specific DEX adapter
        amountOut = pool.executeSwapWithAdapter(
            adapter,
            tokenIn,
            tokenOut,
            amountIn,
            amountOutMin,
            deadline,
            trader
        );

        // Actual trade will be done by centralised owner
        
        emit TradeExecuted(
            trader,
            tokenIn,
            tokenOut,
            amountIn,
            amountOut
        );
        
        return amountOut;
    }
}