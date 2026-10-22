// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;
import {Script, console} from "forge-std/Script.sol";
import {DevOpsTools} from "lib/foundry-devops/src/DevOpsTools.sol";
import {fundme} from "../src/fundme.sol";

contract funding_fundme is Script {
    uint256 constant SEND_VALUE = 0.01 ether;

    function funding_to_fundme(address mostrecentlydeployed) public {
        fundme(payable(mostrecentlydeployed)).fund{value: SEND_VALUE}();

        console.log("Funded fundme contract with %s", SEND_VALUE);
    }

    function run() external {
        address mostrecentlydeployed = DevOpsTools.get_most_recent_deployment(
            "fundme",
            block.chainid
        );
        vm.startBroadcast();
        funding_to_fundme(mostrecentlydeployed);
        vm.stopBroadcast();
    }
}

contract withdraw_fundme is Script {
    function withdrawing_from_fundme(address mostrecentlydeployed) public {
        vm.startBroadcast();
        fundme(payable(mostrecentlydeployed)).withdraw();
        vm.stopBroadcast();
    }

    function run() external {
        address mostrecentlydeployed = DevOpsTools.get_most_recent_deployment(
            "fundme",
            block.chainid
        );
        vm.startBroadcast();
        withdrawing_from_fundme(mostrecentlydeployed);
        vm.stopBroadcast();
    }
}

// fund
// withdraw
