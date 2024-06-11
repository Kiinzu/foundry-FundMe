// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {PriceConverter} from "./PriceConverter.sol";
import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

error FundMe__NotOwner();

contract FundMe{
    using PriceConverter for uint256;

    mapping(address funder => uint256 amountFunded) private s_addressToAmountFunded;
    address[] private s_funders;

    address private immutable i_owner;
    uint256 public constant minimumUSD = 5e18; // to make decimals point same as Ether
    AggregatorV3Interface public s_priceFeed;

    constructor(address priceFeed) {
        i_owner = msg.sender; //deployer
        s_priceFeed = AggregatorV3Interface(priceFeed);
    }
    
    function funds() public payable{
        // require(getConversionRate(msg.value) >= minimumUSD, "Minimum deposit is 5$"); // 1 ETH = 1e18 = 1 000 000 000 000 000 000 
        require(msg.value.getConversionRate(s_priceFeed) >= minimumUSD, "Minimum deposit is 5 USD"); 
        // Without declaring the first paramter, msg.value will be the first parameter for uint256 ethAmount
        s_funders.push(msg.sender);
        s_addressToAmountFunded[msg.sender] += msg.value;
    }

    function cheaperWithdraw() public onlyOwner{
        uint256 fundersLength = s_funders.length;
        for(uint256 funderIndex = 0; funderIndex < fundersLength; funderIndex++){
            address funder = s_funders[funderIndex];
            s_addressToAmountFunded[funder] = 0;
        }
        s_funders = new address[](0);
        (bool callSuccess, /*bytes memory dataReturned*/) = payable(msg.sender).call{value: address(this).balance}("");
        require(callSuccess, "Transfer failed");
    }

    function withdraw() public onlyOwner{
        // for loop to reset all funders 
        for(uint256 funderIndex = 0; funderIndex < s_funders.length; funderIndex++){ /*Starting, ending, step amount*/
            address funder = s_funders[funderIndex];
            s_addressToAmountFunded[funder] = 0;
        } 
        //reset the array
        s_funders = new address[](0); // creating new array of funders starting with index 0
        //withdraw the funds
        // call, transfer, send
        // transfer - the simplest
        // we need the address to be payable address, unless it won't sent. it revers upon fail transaction
        // payable(msg.sender).transfer(address(this).balance);

        // Send
        // send will return bool, so it's better to make it this way in order to revert if the send fails.
        // bool sendSuccess = payable(msg.sender).send(address(this).balance);
        // require(sendSuccess, "Send failed");

        // Call
        // Most used 
        (bool callSuccess, /*bytes memory dataReturned*/) = payable(msg.sender).call{value: address(this).balance}("");
        require(callSuccess, "Transfer failed");
    }

    function getVersion() public view returns (uint256){
        return s_priceFeed.version();
    }

    modifier onlyOwner{
        // require(msg.sender == i_owner, "Only Owner can call this function!");
        if(msg.sender != i_owner){ revert FundMe__NotOwner(); }
        _;
    }

    receive() external payable {
        funds();
    }

    fallback() external payable {
        funds();
    }

    function getAddressToAmountFunded(
        address funder
    ) public view returns(uint256){
        return s_addressToAmountFunded[funder];
    }

    function getFunder(
        uint256 index
    ) external view returns(address){
        return s_funders[index];
    }

    function getOwner() external view returns(address){
        return i_owner;
    }

}