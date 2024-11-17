// test/System.t.sol
pragma solidity ^0.8.20;

import "forge-std/console.sol";
import "forge-std/Test.sol";
import "../src/Sales.sol";
import "../src/MVM.sol";

contract SalesUnitTest is Test {
    MVMToken public mvm;
    Sales public sales;
    address public user;

    // Declare the event
    event CommissionReceived(address indexed user, uint256 amount);

    function setUp() public {
        user = makeAddr("user");
        vm.deal(user, 100000 ether);

        // Deploy contracts in correct order
        mvm = new MVMToken(100000000000000000000000000000000);
        mvm.mint(address(this), 1 ether);
        console.log("MVM Token Address:", address(mvm));

        sales = new Sales();
    }

    function testReceiveComissionSuccess() public {
        uint256 commisionAmount = 1 ether;
        
        vm.startPrank(user);
        // Expect the CommissionReceived event to be emitted
        vm.expectEmit(true, true, true, true);
        emit CommissionReceived(user, commisionAmount);

        sales.receiveCommission(address(mvm), user, 1 ether);
        // Check that the commission amount has been recorded correctly
        assertEq(sales.commissions(address(mvm), user), commisionAmount);
        
        vm.stopPrank();
    }

    function testWithdrawCommissionNoCommissionError() public {
        vm.startPrank(address(this));
        vm.expectRevert("No commission to withdraw");
        sales.withdrawCommission(address(mvm));
        vm.stopPrank();
    }

    function testWithdrawCommissionSuccess() public {
        uint256 commisionAmount = 1 ether;
        vm.startPrank(address(this));

        // Mint MVM tokens to the Sales contract to simulate accumulated commissions
        mvm.transfer(address(sales), commisionAmount);

        
        // Expect the CommissionReceived event to be emitted
        vm.expectEmit(true, true, true, true);
        emit CommissionReceived(user, commisionAmount);
        sales.receiveCommission(address(mvm), user, 1 ether);

        sales.withdrawCommission(address(mvm));
        console.log("sales.accumulatedCommission(address(mvm)) : ", sales.accumulatedCommission(address(mvm)));

        console.log("mvm.balanceOf(address(this)) : ", mvm.balanceOf(address(this)));

        // Check that the commission amount has been recorded correctly
        assertEq(sales.accumulatedCommission(address(mvm)), 0);

        
        // Verify that address(this) has received the MVM tokens
        assertEq(mvm.balanceOf(address(this)), 100000000000000000000000000000000 + 1 ether);

        vm.stopPrank();
    }
}