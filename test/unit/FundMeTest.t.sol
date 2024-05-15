// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {Test, console} from "forge-std/Test.sol";
import {FundMe} from "../../src/FundMe.sol";            //the ".." stands for going down in the directory//
import {DeployFundMe} from "../../script/DeployFundMe.s.sol";

contract FundMeTest is Test{

    address USER = makeAddr("user"); //makeAddr : foundry cheat code that will give us an address to simulate the transactions for our tests 
    uint256 constant SEND_VALUE = 0.1 ether;
    uint256 constant STARTING_BALANCE = 10 ether;
    uint256 constant GAS_PRICE = 1;

    FundMe fundMe; 
    function setUp() external{ //setup is runned before every test
        //fundMe = new FundMe(); 
        DeployFundMe deployFundMe = new DeployFundMe();
        fundMe = deployFundMe.run(); //run returns a FundMe contract
        vm.deal(USER, STARTING_BALANCE); //will give the starting balance to the user address (foundry cheat code)
    }
    function testMinimumDollarIsFive() public view {
        assertEq(fundMe.MINIMUM_USD(), 5e18); //in those tests we have access to the assertEq functions that just test if the two inputs are equals
    }

    function testOwnerIsMsgSender() public view {
        console.log(fundMe.getOwner());
        console.log(msg.sender);
        assertEq(fundMe.getOwner(), msg.sender);
    }

    function testPriceFeedVersionIsAccurate() public view {
        uint256 version = fundMe.getVersion();
        assertEq(version, 4);
    }

    function testFundFailsWithoutEnoughETH() public{
        vm.expectRevert(); //with this magic keyword the test will pass only if the next line reverts. WARNING THOSE TEST ONLY WORK WITH FOUNDRY AND IN THE TESTS
        fundMe.fund(); //send 0 value that is less that the 5$ dollar minimum
    }
    function testFundUpdatesFundedDataStructure() public{
        vm.prank(USER); //prank : foundry magic keyword : will make that the next tx is sent by USER 
        fundMe.fund{value: SEND_VALUE}();
        uint256 amountFunded = fundMe.getAdressToAmountFunded(USER);
        assertEq(amountFunded, SEND_VALUE);
    }

    function testAddsFunderToArrayOfFunders() public {
        vm.prank(USER);
        fundMe.fund{value: SEND_VALUE}();

        address funder = fundMe.getFunder(0);
        assertEq(funder, USER);
    }

    modifier funded(){
        vm.prank(USER);
        fundMe.fund{value: SEND_VALUE}();
        _;
    }

    function testOnlyOwnerCanWithdraw() public funded{
        vm.prank(USER);
        vm.expectRevert();//the vm lines skipp each other for their instructions
        fundMe.withdraw();
    }

    function testWithdrawWithASingleFunder() public funded{
        //Arrange
        uint256 startingOwnerBalance = fundMe.getOwner().balance;
        uint256 startingFundMeBalance = address(fundMe).balance;
        
        //Act
        //uint256 gasStart = gasleft(); //gasleft : built in function in solidity that tells you how much gas is left in your transaction call
        //vm.txGasPrice(GAS_PRICE); // foundry cheat code : sets the gas price to GAS_PRICE
        vm.prank(fundMe.getOwner()); //makes that the next tx is done by the owner
        fundMe.withdraw();

        //uint256 gasEnd = gasleft();
        //uint256 gasUsed = (gasStart - gasEnd) * tx.gasprice; //tx.gasprice is a built in function in solidity that tells you the current gas price
        
        //Assert
        uint256 endingOwnerBalance = fundMe.getOwner().balance;
        uint256 endingFundMeBalance = address(fundMe).balance;
        assertEq(endingFundMeBalance, 0);
        assertEq(startingFundMeBalance + startingOwnerBalance, endingOwnerBalance);
    }

    function testWithdrawFromMultipleFunders() public funded {
        // Arrange
        uint160 numberOfFunders = 10; //uint160 so that we can do address(numberOfFunders)
        uint160 startingFunderIndex = 1; //start with 1 because address(0) reverts sometimes
        for(uint160 i = startingFunderIndex; i < numberOfFunders; i++){
            hoax(address(i), SEND_VALUE); //hoax creates an adress and fund it (prank and deal in one comment) foundry cheat code [address(i) creates a blank address]
            fundMe.fund{value: SEND_VALUE}();
        }

        uint256 startingOwnerBalance = fundMe.getOwner().balance;
        uint256 startingFundMeBalance = address(fundMe).balance;

        // Act
        vm.startPrank(fundMe.getOwner());
        fundMe.withdraw();
        vm.stopPrank(); //every tx between the start and stop prank is made by the address that you give

        // Assert
        assert(address(fundMe).balance == 0);
        assert(startingFundMeBalance + startingOwnerBalance == fundMe.getOwner().balance);
    }

        function testWithdrawFromMultipleFundersCheaper() public funded {
        // Arrange
        uint160 numberOfFunders = 10; //uint160 so that we can do address(numberOfFunders)
        uint160 startingFunderIndex = 1; //start with 1 because address(0) reverts sometimes
        for(uint160 i = startingFunderIndex; i < numberOfFunders; i++){
            hoax(address(i), SEND_VALUE); //hoax creates an adress and fund it (prank and deal in one comment) foundry cheat code [address(i) creates a blank address]
            fundMe.fund{value: SEND_VALUE}();
        }

        uint256 startingOwnerBalance = fundMe.getOwner().balance;
        uint256 startingFundMeBalance = address(fundMe).balance;

        // Act
        vm.startPrank(fundMe.getOwner());
        fundMe.cheaperWithdraw();
        vm.stopPrank(); //every tx between the start and stop prank is made by the address that you give

        // Assert
        assert(address(fundMe).balance == 0);
        assert(startingFundMeBalance + startingOwnerBalance == fundMe.getOwner().balance);
    }
}