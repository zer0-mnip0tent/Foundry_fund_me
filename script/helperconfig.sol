// SPDX-License-Identifier: MIT

// 1. deploy mocks when we are on a local anvil chain
// 2. keep track of contract address across different chains
// 3. sepolia eth/usd
// 4. mainnet eth/usd

pragma solidity ^0.8.0;

import {Script} from "forge-std/Script.sol";
import {MockV3Aggregator} from "../test/MOCKS/mockV3Aggregator.sol";

contract helperconfig is Script {
    // if we are on a local anvil chain we deploy mocks else we use the real pricefeed address
    networkconfig public activeNetworkConfig;

    struct networkconfig {
        address pricefeed; // ETH/USD pricefeeed adderess
    }

    uint8 public constant DECIMALS = 8;
    int256 public constant INITIAL_PRICE = 2000e8;

    constructor() {
        if (block.chainid == 11155111) {
            activeNetworkConfig = getsepoliaethconfig();
        } else if (block.chainid == 1) {
            activeNetworkConfig = getmainnetethconfig();
        } else {
            activeNetworkConfig = getanvilethconfig();
        }
    }

    function getsepoliaethconfig() public pure returns (networkconfig memory) {
        // price feed address

        networkconfig memory sepoliaconfig = networkconfig({pricefeed: 0x694AA1769357215DE4FAC081bf1f309aDC325306});
        return sepoliaconfig;
    }

    function getanvilethconfig() public returns (networkconfig memory) {
        if (activeNetworkConfig.pricefeed != address(0)) {
            return activeNetworkConfig;
        }
        vm.startBroadcast();
        MockV3Aggregator mockpricefeed = new MockV3Aggregator(DECIMALS, INITIAL_PRICE);
        vm.stopBroadcast();

        networkconfig memory anvilconfig = networkconfig({pricefeed: address(mockpricefeed)});

        return anvilconfig;
    }

    function getmainnetethconfig() public pure returns (networkconfig memory) {
        networkconfig memory ethconfig = networkconfig({pricefeed: 0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419});
        return ethconfig;

        // price feed address
    }
}
