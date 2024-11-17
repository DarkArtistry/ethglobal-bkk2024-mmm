// test/System.t.sol
pragma solidity ^0.8.20;

import "forge-std/console.sol";
import "forge-std/Test.sol";
import "../src/Sales.sol";
import "../src/Stash.sol";
import "../src/MVM.sol";

contract StashUnitTest is Test {
    MVMToken public mvm;
    Sales public sales;
    Stash public stash;
    address public user;

    // Declare the event
    event TokenAdded(address token);

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

        // Here we deploy the Stash contract with a temporary pool address
        stash = new Stash(user);
    }

    function testAddSupportedToken() public {
        vm.startPrank(address(this));

        stash.addSupportedToken(address(mvm));
        
        assertEq(stash.isTokenSupported(address(mvm)), true);
        vm.stopPrank();
    }
}