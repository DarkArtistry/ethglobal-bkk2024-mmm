// test/Trade.t.sol
pragma solidity ^0.8.20;

import "forge-std/console.sol";
import "forge-std/Test.sol";
import "../src/Trade.sol";
import "../src/Stash.sol";
import "../src/Pool.sol";
import "../src/Sales.sol";
import "../src/interfaces/IDEXAdapter.sol";
import "./mocks/MockToken.sol";
import "./mocks/MockDEXAdapter.sol";

contract TradeTest is Test {
    Trade public trade;
    Stash public stash;
    Pool public pool;
    Sales public sales;
    MockToken public tokenIn;
    MockToken public tokenOut;
    MockDEXAdapter public dexAdapter;
    address public owner;
    address public user;
    string public dexName = "MockDEX";
    uint256 public amountIn = 2 ether;
    uint256 public amountOutMin = 1 ether;
    uint256 public deadline;

    event DEXAdapterAdded(string indexed dexName, address adapter);
    event DEXAdapterRemoved(string indexed dexName);
    event TradeExecuted(
        address indexed user,
        address tokenIn,
        address tokenOut,
        uint256 amountIn,
        uint256 amountOut
    );

    function setUp() public {
        owner = address(this);
        user = address(0x123);
        vm.deal(owner, 100000 ether);
        vm.deal(user, 100000 ether);

        // Deploy mock tokens
        tokenIn = new MockToken("TokenIn", "TIN", 18, 1e24);
        tokenOut = new MockToken("TokenOut", "TOUT", 18, 1e24);

        // Deploy dependent contracts
        stash = new Stash(address(0));
        sales = new Sales();
        trade = new Trade(address(stash), address(0), address(sales));
        pool = new Pool(address(stash), address(trade), address(sales));

        // Update stash's pool address
        stash.updatePool(address(pool));

        // Update trade's pool address
        trade.updatePool(address(pool));

        vm.deal(address(pool), 100000 ether);
        // vm.deal(address(stash), 100000 ether);
        // vm.deal(address(pool), 100000 ether);
        // vm.deal(address(sales), 100000 ether);

        // Deploy a mock DEX adapter
        dexAdapter = new MockDEXAdapter();
        trade.addDEXAdapter(dexName, address(dexAdapter));

        // Add tokens to stash
        stash.addSupportedToken(address(tokenIn));
        stash.addSupportedToken(address(tokenOut));

        // Assign balances to user
        tokenIn.transfer(user, amountIn);
        vm.startPrank(user);
        tokenIn.approve(address(stash), amountIn);
        stash.depositToken(address(tokenIn), amountIn);
        vm.stopPrank();

        deadline = block.timestamp + 1 hours;
    }

    function testAddDEXAdapter() public {
        string memory newDexName = "AnotherDEX";
        address newDexAdapter = address(new MockDEXAdapter());

        vm.prank(owner);
        vm.expectEmit(true, true, true, true);
        emit DEXAdapterAdded(newDexName, newDexAdapter);

        trade.addDEXAdapter(newDexName, newDexAdapter);

        // Verify the adapter was added
        assertEq(address(trade.dexAdapters(newDexName)), newDexAdapter);
    }

    function testRemoveDEXAdapter() public {
        vm.prank(owner);
        vm.expectEmit(true, true, true, true);
        emit DEXAdapterRemoved(dexName);

        trade.removeDEXAdapter(dexName);

        // Verify the adapter was removed
        assertEq(address(trade.dexAdapters(dexName)), address(0));
    }

    function testExecuteTrade() public {
        vm.startPrank(address(this));

        uint256 userBalanceBefore = stash.balanceOf(user, address(tokenIn));
        console.log("userBalanceBefore : ", userBalanceBefore); // 2000000000000000000

        uint256 amountOut = trade.executeTrade(
            dexName,
            address(tokenIn),
            address(tokenOut),
            amountIn,
            amountOutMin,
            deadline,
            address(user)
        );

        // Verify the user's balance decreased
        uint256 userBalanceAfter = stash.balanceOf(user, address(tokenIn));

        console.log("userBalanceAfter: ", userBalanceAfter);
        console.log("userBalanceBefore - userBalanceAfter: ", userBalanceBefore - userBalanceAfter);
        console.log("amountIn: ", amountIn);
        assertEq(userBalanceBefore - userBalanceAfter, amountIn);

        vm.stopPrank();
    }

    function testUpdatePool() public {
        address newPool = address(new Pool(address(0), address(0), address(0)));

        vm.prank(owner);
        trade.updatePool(newPool);

        assertEq(address(trade.pool()), newPool);
    }
}