// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {Test, console} from "forge-std/Test.sol";
import {FundMe} from "../../src/FundMe.sol";
import {DeployFundMe} from "../../script/DeployFundMe.s.sol";
import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

contract FundMeTest is Test {
    FundMe fundMe;

    address USER = makeAddr("user");
    uint256 constant SEND_VALUE = 0.1 ether;
    uint256 constant STARTING_BALANCE = 10 ether;
    uint256 constant GAS_PRICE = 1;

    // setup always start first
    function setUp() external {
        // us -> fundMeTest -> FundMe
        // fundMe = new FundMe(0x694AA1769357215DE4FAC081bf1f309aDC325306);
        DeployFundMe deployFundMe = new DeployFundMe();
        // if we do this, the deployer is now msg.sender again since vm.startBroadcast() is us
        fundMe = deployFundMe.run();
        vm.deal(USER, STARTING_BALANCE);
    }

    function testMinimumDollarIsFive() public {
        // console.log("Hellow World");
        assertEq(fundMe.minimumUSD(), 5e18);
    }

    function testOwnerIsMsgSender() public{
        // console.log(fundMe.i_owner());
        // console.log(msg.sender);
        assertEq(fundMe.getOwner(), msg.sender);
    }

    /*
        What can we do to work with addresses outside our system?
        1. Unit
            -> Testing a specific part of our code
        2. Integration
            -> Testing how our code works with other parts of our code
        3. Forked
            -> Testing our code on a simulated real environment
        4. Staging
            -> Testing our code in a real environment that is not production``
    */

    function testPriceFeedVersion() public{
        uint256 version = fundMe.getVersion();
        assertEq(version, 4);
    }

    function testFUndFailWithoutEnoughEth() public{
        vm.expectRevert(); // this will expect the next line to fail
        fundMe.funds();
    }

    function testFundUpdatesFundedDataStructure() public{
        vm.prank(USER); // the next Transaction will be sent by suer
        fundMe.funds{value: SEND_VALUE}();
        
        // uint256 amountFunded = fundMe.getAddressToAmountFunded(msg.sender); // msg.sender is not the one who call fund, thus test fails
        uint256 amountFunded = fundMe.getAddressToAmountFunded(USER); 
        assertEq(amountFunded, 0.1 ether);
    }

    function testAddsFunderToArray() public{
        vm.prank(USER);
        fundMe.funds{value: SEND_VALUE}();

        address funder = fundMe.getFunder(0);
        assertEq(funder, USER);
    }

    modifier funded(){
        vm.prank(USER);
        fundMe.funds{value: SEND_VALUE}();
        _;
    }

    function testOnlyOwnerCanWithdraw() public funded{
        vm.expectRevert();
        vm.prank(USER);
        fundMe.withdraw();
    }

    function testWithdrawWithASingleFunder() public funded{
        // Arrange
        uint256 startingOwnerBalance = fundMe.getOwner().balance;
        uint256 staritingFundMeBalance = address(fundMe).balance;
    
        // Act
        uint256 gasStart = gasleft();
        vm.txGasPrice(GAS_PRICE);
        vm.prank(fundMe.getOwner());
        fundMe.withdraw();
        
        uint256 gasEnd = gasleft();
        uint256 gasUsed = (gasStart - gasEnd) * tx.gasprice;
        console.log(gasUsed);

        // Assert
        uint256 endingOwnerBalance = fundMe.getOwner().balance;
        uint256 endingFundMeBalance = address(fundMe).balance;
        assertEq(staritingFundMeBalance + startingOwnerBalance, endingOwnerBalance);
    }
    
    function testWithdrawWithMultipleFunders() public funded{
        // Arrange
        uint160 numberOfFunders = 10;
        uint160 startingFunderIndex = 1;
        for(uint160 i = startingFunderIndex; i < numberOfFunders; i++){
            // vm.deal and vm.prank cna be combined using hoax
            hoax(address(i), SEND_VALUE);
            fundMe.funds{value: SEND_VALUE}();
        }

        uint256 startingOwnerBalance = fundMe.getOwner().balance;
        uint256 staritingFundMeBalance = address(fundMe).balance;

        // Act
        vm.startPrank(fundMe.getOwner());
        fundMe.withdraw();
        vm.stopPrank();

        // Assert
        assert(address(fundMe).balance == 0);
        assertEq(staritingFundMeBalance + startingOwnerBalance, fundMe.getOwner().balance);
    }

    function testWithdrawWithMultipleFundersCheaper() public funded{
        // Arrange
        uint160 numberOfFunders = 10;
        uint160 startingFunderIndex = 1;
        for(uint160 i = startingFunderIndex; i < numberOfFunders; i++){
            // vm.deal and vm.prank cna be combined using hoax
            hoax(address(i), SEND_VALUE);
            fundMe.funds{value: SEND_VALUE}();
        }

        uint256 startingOwnerBalance = fundMe.getOwner().balance;
        uint256 staritingFundMeBalance = address(fundMe).balance;

        // Act
        vm.startPrank(fundMe.getOwner());
        fundMe.cheaperWithdraw();
        vm.stopPrank();

        // Assert
        assert(address(fundMe).balance == 0);
        assertEq(staritingFundMeBalance + startingOwnerBalance, fundMe.getOwner().balance);
    }

}