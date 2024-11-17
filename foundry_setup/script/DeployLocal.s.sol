// script/Deploy.s.sol
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "forge-std/StdJson.sol"; // Add this import at the top
import "../src/Trade.sol";
import "../src/Stash.sol";
import "../src/Pool.sol";
import "../src/Sales.sol";
import "../src/adapters/UniswapV3Adapter.sol";

contract DeployScript is Script {
    // Anvil's first account (default)
    address constant ANVIL_ACCOUNT = 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266;
    uint256 constant ANVIL_PRIVATE_KEY = 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80;
    
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
        uniswapRouters[42161] = 0xE592427A0AEce92De3Edee1F18E0157C05861564;  // Arbitrum
        uniswapRouters[10] = 0xE592427A0AEce92De3Edee1F18E0157C05861564;  // Optimism
        uniswapRouters[137] = 0xE592427A0AEce92De3Edee1F18E0157C05861564;  // Polygon
        uniswapRouters[8453] = 0x2626664c2603336E57B271c5C0b26F421741e481;   // Base Mainnet
        uniswapRouters[84532] = 0x2626664c2603336E57B271c5C0b26F421741e481;  // Base Sepolia
        uniswapRouters[11155111] = 0x3bFA4769FB09eefC5a80d6E87c3B9C650f7Ae48E; // Sepolia, Uniswap router2 address
        uniswapRouters[480] = 0x091AD9e2e6e5eD44c1c66dB50e49A601F9f36cF6; // WorldChain

        // Initialize WHALE addresses
        WHALES[1] = 0x28C6c06298d514Db089934071355E5743bf21d60;  // Ethereum
        WHALES[137] = 0x191c10Aa4AF7C30e871E70C95dB0E4eb77237530;  // Polygon
        WHALES[8453] = 0x8B36dDa844E2d3d3d7169f3EED7e251CaF3b48cF;   // Base Mainnet

        LINK_ADDRESSES[1] = 0x514910771AF9Ca656af840dff83E8264EcF986CA;  // Ethereum
        LINK_ADDRESSES[137] = 0x53E0bca35eC356BD5ddDFebbD1Fc0fD03FaBad39;  // Polygon
        LINK_ADDRESSES[8453] = 0x88Fb150BDc53A65fe94Dea0c9BA0a6dAf8C6e196;   // Base Mainnet

        USDC_ADDRESSES[1] = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;  // Ethereum
        USDC_ADDRESSES[137] = 0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174;  // Polygon
        USDC_ADDRESSES[8453] = 0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913;   // Base Mainnet
    }

    function run() public {
        // For local testing, set a specific block to start from
        uint256 startBlock = block.number;
        console.log("Starting block number:", startBlock);
        
        // Get private key from environment
        address deployer = vm.addr(ANVIL_PRIVATE_KEY);

        // Get current nonce
        uint64 nonce = vm.getNonce(deployer);
        console.log("Current nonce:", nonce);
        
        // Get uniswapRouter address for current network
        address uniswapRouter = uniswapRouters[block.chainid];
        require(uniswapRouter != address(0), "Network not supported");

        address WHALE = WHALES[block.chainid];
        address LINK = LINK_ADDRESSES[block.chainid];
        address USDC = USDC_ADDRESSES[block.chainid];

        vm.startPrank(WHALE);
        vm.deal(WHALE, 100 ether);
        vm.store(
            LINK,
            keccak256(abi.encode(ANVIL_ACCOUNT, uint256(0))),
            bytes32(uint256(LINK_AMOUNT))
        );
        // For ERC20 tokens, use dealTokens
        IERC20(LINK).transfer(ANVIL_ACCOUNT, LINK_AMOUNT);
        vm.stopPrank();
        console.log(WHALE.balance);

        vm.startBroadcast(ANVIL_PRIVATE_KEY);

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

        vm.stopBroadcast();

        // Log deployed addresses
        console.log("Deployed contracts:");
        console.log("Sales:", address(sales));
        console.log("Stash:", address(stash));
        console.log("Trade:", address(trade));
        console.log("Pool:", address(pool));
        console.log("UniswapV3Adapter:", address(uniswapAdapter));

        vm.startPrank(ANVIL_ACCOUNT);
        // Get contract instances
        IERC20 linkToken = IERC20(LINK);
        IERC20 usdcToken = IERC20(USDC);

        // Add supported tokens
        stash.addSupportedToken(LINK);
        stash.addSupportedToken(USDC);
        console.log("Added supported tokens");

        // Approve and deposit LINK
        linkToken.approve(address(stash), LINK_AMOUNT);
        stash.depositToken(LINK, LINK_AMOUNT);
        console.log("Deposited LINK tokens");
        uint256 deadline = block.timestamp + 15 minutes;
        trade.executeTrade("Uniswap V3", address(linkToken), address(usdcToken), 1000000000000000, 0, deadline, ANVIL_ACCOUNT);
        // Log final state
        console.log("Setup complete!");
        console.log("LINK balance in Stash:", stash.balanceOf(ANVIL_ACCOUNT, LINK));
        vm.stopPrank();

        // After deposit, log the event details explicitly
        console.log("Event emission block:", block.number);
        console.log("TokenDeposited event details:");
        console.log("- User:", ANVIL_ACCOUNT);
        console.log("- Token:", LINK);
        console.log("- Amount:", LINK_AMOUNT);

        // Save addresses to a JSON file in the allowed 'testdata' directory
        string memory json;

        json = vm.serializeAddress("deployed", "Sales", address(sales));
        json = vm.serializeAddress("deployed", "Stash", address(stash));
        json = vm.serializeAddress("deployed", "Trade", address(trade));
        json = vm.serializeAddress("deployed", "Pool", address(pool));
        json = vm.serializeAddress("deployed", "UniswapV3Adapter", address(uniswapAdapter));

        // Specify the path within the 'testdata' directory
        string memory path = "./testdata/deployed_contracts.json";
        vm.writeJson(json, path);
    }
}