// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;
import {Test, console} from "forge-std/Test.sol";
import {DevOpsTools} from "lib/foundry-devops/src/DevOpsTools.sol";
import {fundme} from "../../src/fundme.sol";
import {deployfundme} from "../../script/deployfundme.sol";
import {funding_fundme} from "../../script/interactions.s.sol";
import {withdraw_fundme} from "../../script/interactions.s.sol";

contract interactionTest is Test {
    fundme fundmecontract;

    address user = makeAddr("user");
    uint256 constant SEND_VALUE = 0.01 ether;
    uint256 constant STARTING_BALANCE = 100 ether;

    function setUp() external {
        deployfundme deployfundmecontract = new deployfundme();
        fundmecontract = deployfundmecontract.run();
        vm.deal(user, STARTING_BALANCE);
    }
    function testuser_can_fund_interactions() public {
        funding_fundme test_funder_contract = new funding_fundme();
        vm.deal(address(test_funder_contract), STARTING_BALANCE);
        test_funder_contract.funding_to_fundme(address(fundmecontract));

        withdraw_fundme test_withdraw_contract = new withdraw_fundme();
        test_withdraw_contract.withdrawing_from_fundme(address(fundmecontract));

        assertEq(address(fundmecontract).balance, 0);
    }
}
