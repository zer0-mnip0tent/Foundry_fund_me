// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Test, console} from "forge-std/Test.sol";
import {fundme} from "../src/fundme.sol";
import {deployfundme} from "../script/deployfundme.sol";

contract fundmetest is Test {
    fundme fundmecontract;

    address user = makeAddr("user");
    uint256 constant SEND_VALUE = 10e18;
    uint256 constant STARTING_BALANCE = 100 ether;

    modifier funded() {
        vm.prank(user); // next tx will be sent by user
        fundmecontract.fund{value: SEND_VALUE}();
        _;
    }

    function setUp() external {
        // US -> fundmetest -> fundme
        //  fundmecontract = new fundme();
        deployfundme deployfundmecontract = new deployfundme();
        fundmecontract = deployfundmecontract.run();
        vm.deal(user, STARTING_BALANCE);
    }

    function testminimumdollarisfive() public {
        assertEq(fundmecontract.MINIMUMUSD(), 5e18);
    }

    function testifownerismsgsender() public {
        assertEq(fundmecontract.getowner(), msg.sender);
    }

    function testgetversion() public {
        uint256 version = fundmecontract.getversion();
        console.log("version is ", version);
    }

    function testfundfailswithoutenougheth() public {
        vm.expectRevert(); // the next line should fail
        fundmecontract.fund();
    }

    function testfundupdatesfundeddatastructure() public funded {
        assertEq(fundmecontract.getaddresstoamountfunded(user), SEND_VALUE);
    }

    function testaddfundertoarrayoffunders() public funded {
        assertEq(fundmecontract.getfunder(0), user);
    }

    function testonlyownercanwithdraw() public funded {
        vm.expectRevert();
        vm.prank(user);
        fundmecontract.withdraw();
    }

    function testwithdrawwithasinglefunder() public funded {
        // arrange

        uint256 StartingOwnerBalance = fundmecontract.getowner().balance;
        uint256 StaringContarctBalance = address(fundmecontract).balance;

        //act

        vm.prank(fundmecontract.getowner());
        fundmecontract.withdraw();

        //assert
        uint256 EndingOwnerBalance = fundmecontract.getowner().balance;
        uint256 EndingContractBalance = address(fundmecontract).balance;

        assertEq(EndingContractBalance, 0);
        assertEq(StartingOwnerBalance + StaringContarctBalance, EndingOwnerBalance);
    }

    function testwithdrawwithmultiplefunders() public funded {
        // arrange
        uint160 numberoffunders = 10;
        uint160 startingfunderindex = 1;
        for (uint160 i = startingfunderindex; i < numberoffunders; i++) {
            // using hoax to create a new address and fund it with 10 ether

            hoax(address(i), SEND_VALUE);
            fundmecontract.fund{value: SEND_VALUE}();
        }

        //act

        uint256 StartingOwnerBalance = fundmecontract.getowner().balance;
        uint256 StaringContarctBalance = address(fundmecontract).balance;

        vm.startPrank(fundmecontract.getowner());
        fundmecontract.withdraw();
        vm.stopPrank();

        //assert

        assert(address(fundmecontract).balance == 0);
        assert(StartingOwnerBalance + StaringContarctBalance == fundmecontract.getowner().balance);
    }

    function testcheaperwithdrawwithmultiplefunders() public funded {
        // arrange
        uint160 numberoffunders = 10;
        uint160 startingfunderindex = 1;
        for (uint160 i = startingfunderindex; i < numberoffunders; i++) {
            // using hoax to create a new address and fund it with 10 ether

            hoax(address(i), SEND_VALUE);
            fundmecontract.fund{value: SEND_VALUE}();
        }

        //act

        uint256 StartingOwnerBalance = fundmecontract.getowner().balance;
        uint256 StaringContarctBalance = address(fundmecontract).balance;

        vm.startPrank(fundmecontract.getowner());
        fundmecontract.cheaperwithdraw();
        vm.stopPrank();

        //assert

        assert(address(fundmecontract).balance == 0);
        assert(StartingOwnerBalance + StaringContarctBalance == fundmecontract.getowner().balance);
    }
}
