// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;
import {priceconverter} from "./price_converter.sol";
import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";

contract fundme {
    using priceconverter for uint256;

    // using constant , immutable to reduce the gas cost
    // with connstant data type use only CAPS to reuce teh gas cost

    uint256 public constant MINIMUMUSD = 5e18;
    AggregatorV3Interface private s_pricefeed;
    address[] private s_funders;
    mapping(address funder => uint256 amountfunded) private s_addresstoamountfunded;

    address private immutable i_owner;

    constructor(address pricefeed) {
        i_owner = msg.sender;
        s_pricefeed = AggregatorV3Interface(pricefeed);
    }

    function fund() public payable {
        //allow users to send $
        //allow users to send a minimum number of eth

        // 1e18 = 1000000000000000000 = 1ETH
        require(msg.value.getconversionrate(s_pricefeed) >= MINIMUMUSD, "didn't send enough eth");
        s_funders.push(msg.sender);
        s_addresstoamountfunded[msg.sender] = s_addresstoamountfunded[msg.sender] + msg.value;
    }

    function getversion() public view returns (uint256) {
        // address
        // ABI
        return s_pricefeed.version();
    }

    function withdraw() public only0wner {
        // ONE WAY TO MAKE ONLY THE OWNER WITHDRAW THE FUNDS

        //require(msg.sender == i_owner , "YOU ARE NOT THE OWNER OF THIS ADDRESS");

        for (uint256 funderindex = 0; funderindex < s_funders.length; funderindex++) {
            address funder = s_funders[funderindex];
            s_addresstoamountfunded[funder] = 0;
        }

        // resetting the funders array

        s_funders = new address[](0);

        // withdrawing the funds

        // transfer
        //payable(msg.sender).transfer(address(this).balance);

        // send
        // bool sendsuccess = payable(msg.sender).send(address(this).balance);
        // require(sendsuccess, "Send Failed");

        // call

        (bool callsuccess,) = payable(msg.sender).call{value: address(this).balance}("");
        require(callsuccess, "Call Failed");
    }

    function cheaperwithdraw() public only0wner {
        uint256 funderslength = s_funders.length;

        for (uint256 funderindex = 0; funderindex < funderslength; funderindex++) {
            address funder = s_funders[funderindex];
            s_addresstoamountfunded[funder] = 0;
        }

        s_funders = new address[](0);

        (bool callsuccess,) = payable(msg.sender).call{value: address(this).balance}("");
        require(callsuccess, "Call Failed");
    }

    modifier only0wner() {
        require(msg.sender == i_owner, "NOT THE OWNER OF THIS ADDRESS");
        _;
    }

    // what will happem if someone sends ETH to this contract without calling the fund function

    receive() external payable {
        fund();
    }

    fallback() external payable {
        fund();
    }

    /**
     * View / Pure functions (getters)
     *
     */
    function getaddresstoamountfunded(address fundingaddress) external view returns (uint256) {
        return s_addresstoamountfunded[fundingaddress];
    }

    function getfunder(uint256 index) external view returns (address) {
        return s_funders[index];
    }

    function getowner() external view returns (address) {
        return i_owner;
    }
}
