// test/System.t.sol
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/Stash.sol";
import "../src/Pool.sol";
import "../src/Trade.sol";
import "../src/Sales.sol";
import "../src/MVM.sol";

contract SystemTest is Test {
    Stash public stash;
    Pool public pool;
    MVMToken public mvm;
    Trade public trade;
    Sales public sales;
    address public user;

    function setUp() public {
        user = makeAddr("user");
        vm.deal(user, 100000 ether);

        // Deploy contracts in correct order
        mvm = new MVMToken(100000000000000000000000000000000);
        console.log("MVM Token Address:", address(mvm));

        sales = new Sales();
        
        // First deploy stash with temporary pool address
        stash = new Stash(address(0));
        console.log("Stash Address:", address(stash));
        
        // Mint MVM tokens to user
        mvm.mint(user, 1000 ether);
        console.log("Minted tokens to user:", mvm.balanceOf(user));
        
        // Add supported tokens to stash
        try stash.addSupportedToken(address(mvm)) {
            emit log("MVM token added successfully");
        } catch Error(string memory reason) {
            emit log(reason);
        }

        // Deploy trade with correct addresses
        trade = new Trade(
            address(stash),
            address(0), // temporary pool address
            address(sales)
        );

        // Now deploy pool with correct addresses
        pool = new Pool(address(stash), address(trade), address(sales));
        console.log("Pool Address:", address(pool));

        // Update stash's pool address
        stash.updatePool(address(pool));
        console.log("Updated Stash's Pool Address");

        // Update trade's pool address
        trade.updatePool(address(pool));
        console.log("Updated Trade's Pool Address");
    }

    function testDeposit() public {
        uint256 depositAmount = 1 ether;
        
        vm.startPrank(user);
        
        // Log initial state
        console.log("Initial user MVM balance:", mvm.balanceOf(user));
        console.log("Initial stash balance:", stash.balanceOf(user, address(mvm)));
        
        // Approve stash to spend tokens
        mvm.approve(address(stash), depositAmount);
        console.log("Approved stash to spend tokens");
        
        // Make deposit
        stash.depositToken(address(mvm), depositAmount);
        console.log("Deposit completed");
        
        // Verify final state
        assertEq(stash.balanceOf(user, address(mvm)), depositAmount, "Deposit amount mismatch");
        assertEq(mvm.balanceOf(address(pool)), depositAmount, "Pool should have the tokens");
        vm.stopPrank();
    }

    function testWithdraw() public {
        uint256 depositAmount = 1 ether;
        uint256 withdrawAmount = 0.5 ether;
        
        vm.startPrank(user);
        
        // First approve and deposit
        mvm.approve(address(stash), depositAmount);
        stash.depositToken(address(mvm), depositAmount);
        
        // Verify deposit
        assertEq(stash.balanceOf(user, address(mvm)), depositAmount, "Deposit failed");
        
        // Then withdraw
        stash.withdrawToken(address(mvm), withdrawAmount);
        
        // Verify withdrawal
        assertEq(stash.balanceOf(user, address(mvm)), depositAmount - withdrawAmount, "Withdrawal amount mismatch");
        vm.stopPrank();
    }

    function testFailWithdrawTooMuch() public {
        uint256 depositAmount = 1 ether;
        
        vm.startPrank(user);
        mvm.approve(address(stash), depositAmount);
        stash.depositToken(address(mvm), depositAmount);
        
        // Try to withdraw more than deposited (should fail)
        stash.withdrawToken(address(mvm), 2 ether);
        vm.stopPrank();
    }

    function testBalanceChecks() public {
        uint256 depositAmount = 1 ether;
        
        vm.startPrank(user);
        
        // Check initial balance
        uint256 initialBalance = mvm.balanceOf(user);
        console.log("Initial MVM balance:", initialBalance);
        
        // Approve and deposit
        mvm.approve(address(stash), depositAmount);
        stash.depositToken(address(mvm), depositAmount);
        
        // Check balances after deposit
        assertEq(mvm.balanceOf(user), initialBalance - depositAmount, "User balance not decreased");
        assertEq(stash.balanceOf(user, address(mvm)), depositAmount, "Stash balance not increased");
        assertEq(mvm.balanceOf(address(pool)), depositAmount, "Pool didn't receive tokens");
        
        vm.stopPrank();
    }
}