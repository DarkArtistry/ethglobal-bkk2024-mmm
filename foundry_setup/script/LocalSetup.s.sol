// script/LocalSetup.s.sol
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "forge-std/Test.sol";  // Added for vm.deal
import "../src/Stash.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract LocalSetupScript is Script {
    
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
        // Get private key from environment
        address deployer = vm.addr(ANVIL_PRIVATE_KEY);

        // Get current nonce
        uint64 nonce = vm.getNonce(deployer);
        console.log("Current nonce:", nonce);
        
        // Get uniswapRouter address for current network
        address uniswapRouter = uniswapRouters[block.chainid];
        require(uniswapRouter != address(0), "Network not supported");

        vm.startBroadcast(ANVIL_PRIVATE_KEY);

        vm.startPrank(ANVIL_ACCOUNT);
        // Get contract instances
        IERC20 linkToken = IERC20(LINK_ADDRESSES[block.chainid]);
        Stash stash = new Stash(address(0xD185B4846E5fd5419fD4D077dc636084BEfC51C0)); // Initial pool address is 0
        // Approve and deposit LINK
        linkToken.approve(address(0xD185B4846E5fd5419fD4D077dc636084BEfC51C0), LINK_AMOUNT);
        stash.depositToken(LINK_ADDRESSES[block.chainid], LINK_AMOUNT);
        console.log("Deposited LINK tokens");
        // uint256 deadline = block.timestamp + 15 minutes;
        vm.stopPrank();

        // Log final state
        console.log("LINK balance in Stash:", stash.balanceOf(ANVIL_ACCOUNT, LINK_ADDRESSES[block.chainid]));
    }
}