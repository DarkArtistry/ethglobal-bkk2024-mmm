pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "../interfaces/IDEXAdapter.sol";

contract UniswapV3Adapter is IDEXAdapter, Ownable {
    using SafeERC20 for IERC20;
    
    ISwapRouter public immutable swapRouter;

    // Fee tiers
    uint24 public constant UNISWAP_POOL_FEE_LOW = 500;    // 0.05%
    uint24 public constant UNISWAP_POOL_FEE_MEDIUM = 3000;  // 0.30%
    uint24 public constant UNISWAP_POOL_FEE_HIGH = 10000;   // 1.00%

    uint24 public constant poolFee = 3000;
    address public pool;

    // Mapping of token pair to preferred fee tier
    mapping(bytes32 => uint24) public pairFees;
    
    constructor(address _router, address _pool) Ownable(msg.sender) {
        swapRouter = ISwapRouter(_router);
        pool = _pool;
    }
    
    function setPairFee(
        address tokenA,
        address tokenB,
        uint24 fee
    ) external onlyOwner {
        require(
            fee == UNISWAP_POOL_FEE_LOW || 
            fee == UNISWAP_POOL_FEE_MEDIUM || 
            fee == UNISWAP_POOL_FEE_HIGH,
            "Invalid fee tier"
        );
        bytes32 pairHash = getPairHash(tokenA, tokenB);
        pairFees[pairHash] = fee;
    }

    function getPairHash(
        address tokenA,
        address tokenB
    ) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(
            tokenA < tokenB ? tokenA : tokenB,
            tokenA < tokenB ? tokenB : tokenA
        ));
    }

    function getPoolFee(
        address tokenIn,
        address tokenOut
    ) public view returns (uint24) {
        bytes32 pairHash = getPairHash(tokenIn, tokenOut);
        uint24 fee = pairFees[pairHash];
        // Return custom fee if set, otherwise medium fee
        return fee == 0 ? UNISWAP_POOL_FEE_MEDIUM : fee;
    }

    modifier onlyPool() {
        require(msg.sender == pool, "Only designated pool can call this function");
        _;
    }
    
    function executeSwap(
        address tokenIn,
        address tokenOut,
        uint256 amountIn,
        uint256 amountOutMin,
        uint256 deadline,
        address recipient
    ) external override onlyPool returns (uint256 amountOut) {
        // Approve router
        IERC20(tokenIn).approve(address(swapRouter), amountIn);
        
        ISwapRouter.ExactInputSingleParams memory params = ISwapRouter
            .ExactInputSingleParams({
                tokenIn: tokenIn,
                tokenOut: tokenOut,
                fee: poolFee,
                recipient: recipient,
                deadline: deadline,
                amountIn: amountIn,
                amountOutMinimum: amountOutMin,
                sqrtPriceLimitX96: 0
            });

        return swapRouter.exactInputSingle(params);
    }
    
    function getDEXName() external pure override returns (string memory) {
        return "Uniswap V3";
    }
    
    function getRouter() external view override returns (address) {
        return address(swapRouter);
    }
}