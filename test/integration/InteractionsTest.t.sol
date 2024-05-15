// SPDX-License-Identifier: MIT

//So, the point of the FundFundMe script is not to test functionality but to provide a convenient way to fund a FundMe contract programmatically, outside the scope of testing. It's a separation of concerns: the script handles operational tasks, while the test contract focuses on verifying the correctness of the FundMe contract's behavior.


pragma solidity ^0.8.18;

import {Test, console} from "forge-std/Test.sol";
import {FundMe} from "../../src/FundMe.sol";            //the ".." stands for going down in the directory//
import {DeployFundMe} from "../../script/DeployFundMe.s.sol";
import {FundFundMe} from "../../script/Interactions.s.sol";
import {WithdrawFundMe} from "../../script/Interactions.s.sol";


contract InteractionsTest is Test{
    address USER = makeAddr("user"); //makeAddr : foundry cheat code that will give us an address to simulate the transactions for our tests 
    uint256 constant SEND_VALUE = 0.1 ether;
    uint256 constant STARTING_BALANCE = 10 ether;
    uint256 constant GAS_PRICE = 1;

    FundMe fundMe; 
   
   
    function setUp() external{
        DeployFundMe deploy = new DeployFundMe();
        fundMe = deploy.run(); 
        vm.deal(USER, STARTING_BALANCE); 
    }

    function testUserCanFundInteractions() public { //this time we are checking if the funding works
        uint256 preUserBalance = address(USER).balance;
        uint256 preOwnerBalance = address(fundMe.getOwner()).balance;

        // Using vm.prank to simulate funding from the USER address
        vm.prank(USER);
        fundMe.fund{value: SEND_VALUE}();

        WithdrawFundMe withdrawFundMe = new WithdrawFundMe();
        withdrawFundMe.withdrawFundMe(address(fundMe));

        uint256 afterUserBalance = address(USER).balance;
        uint256 afterOwnerBalance = address(fundMe.getOwner()).balance;

        assert(address(fundMe).balance == 0);
        assertEq(afterUserBalance + SEND_VALUE, preUserBalance);
        assertEq(preOwnerBalance + SEND_VALUE, afterOwnerBalance);

    }
}