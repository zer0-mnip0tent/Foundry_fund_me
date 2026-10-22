// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import {Script} from "forge-std/Script.sol";
import {fundme} from "../src/fundme.sol";
import {helperconfig} from "./helperconfig.sol";

contract deployfundme is Script {
    function run() external returns (fundme) {
        // before broadcast -> not a real transaction
        helperconfig helperconfigcontract = new helperconfig();
        address ethusdpricefeed = helperconfigcontract.activeNetworkConfig();

        // after startbroadcast -> a real transaction
        vm.startBroadcast();
        fundme fundmecontract = new fundme(ethusdpricefeed);
        vm.stopBroadcast();
        return fundmecontract;
    }
}
