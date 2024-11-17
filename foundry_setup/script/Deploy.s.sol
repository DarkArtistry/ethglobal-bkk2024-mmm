// script/Deploy.s.sol
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "forge-std/console2.sol";
import "../src/Trade.sol";
import "../src/Stash.sol";
import "../src/Pool.sol";
import "../src/Sales.sol";
import "../src/adapters/UniswapV3Adapter.sol";

contract DeployScript is Script {
    // Amount to deal and deposit
    uint256 constant LINK_AMOUNT = 10 * 10**18; // 10 LINK

    // Network-specific router addresses
    mapping(uint256 => address) public uniswapRouters;

    // Network-specific WHALE addresses
    mapping(uint256 => address) public WHALES;

    // Network-specific TOKEN addresses
    mapping(uint256 => address) public LINK_ADDRESSES;
    mapping(uint256 => address) public USDC_ADDRESSES;

    function setUp() public {
        // Initialize router addresses
        uniswapRouters[1] = 0xE592427A0AEce92De3Edee1F18E0157C05861564;  // Ethereum
        uniswapRouters[137] = 0xE592427A0AEce92De3Edee1F18E0157C05861564;  // Polygon

        // Initialize WHALE addresses
        WHALES[1] = 0x28C6c06298d514Db089934071355E5743bf21d60;  // Ethereum
        WHALES[137] = 0x191c10Aa4AF7C30e871E70C95dB0E4eb77237530;  // Polygon

        LINK_ADDRESSES[1] = 0x514910771AF9Ca656af840dff83E8264EcF986CA;  // Ethereum
        LINK_ADDRESSES[137] = 0x53E0bca35eC356BD5ddDFebbD1Fc0fD03FaBad39;  // Polygon

        USDC_ADDRESSES[1] = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;  // Ethereum
        USDC_ADDRESSES[137] = 0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174;  // Polygon
    }

    function run() public {
        
        // Get private key from environment
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);

        // Get current nonce from chain
        uint64 currentNonce = vm.getNonce(deployer);
        console.log("Current nonce:", currentNonce);
        
        // Use this nonce
        vm.setNonce(deployer, currentNonce);
        
        // Get uniswapRouter address for current network
        address uniswapRouter = uniswapRouters[block.chainid];
        require(uniswapRouter != address(0), "Network not supported");

        vm.startBroadcast(deployerPrivateKey);

        // Deploy core contracts
        Sales sales = new Sales();
        Stash stash = new Stash(address(0)); // Initial pool address is 0
        Trade trade = new Trade(
            address(stash),
            address(0), // Initial pool address is 0
            address(sales)
        );
        Pool pool = new Pool(
            address(stash),
            address(trade),
            address(sales)
        );

        // Update pool addresses
        stash.updatePool(address(pool));
        trade.updatePool(address(pool));

        // Deploy Uniswap adapter
        UniswapV3Adapter uniswapAdapter = new UniswapV3Adapter(
            uniswapRouter,
            address(pool)
        );

        // Add Uniswap adapter to Trade contract
        trade.addDEXAdapter("Uniswap V3", address(uniswapAdapter));

        // Log deployed addresses
        console2.log("Deployed contracts:");
        console2.log("Sales:", address(sales));
        console2.log("Stash:", address(stash));
        console2.log("Trade:", address(trade));
        console2.log("Pool:", address(pool));
        console2.log("UniswapV3Adapter:", address(uniswapAdapter));
        vm.stopBroadcast();

    }
}