// SPDX-License-Identifier: MIT
// 1. Deploy mocks when we are on a local anvil chain
//2. keep track of contract address accross different chains
pragma solidity ^0.8.18;

import {Script} from "forge-std/Script.sol";
import {MockV3Aggregator} from "../test/mocks/MockV3Aggregator.sol";

contract HelperConfig is Script{ //has to be a script because we use the vm keyword at some point  
    
    NetworkConfig public activeNetworkConfig;
    
    uint8 public constant DECIMALS = 8;
    int256 public constant INITIAL_PRICE = 2000e8;
    
    struct NetworkConfig {
    address priceFeed; //ETH USD price feed address
   }

   constructor(){
        if(block.chainid == 11155111) { //Sepolia's chain Id is 11155111
            activeNetworkConfig = getSepoliaEthConfig();
        }
        else if(block.chainid == 1) {
            activeNetworkConfig = getMainnetEthConfig();
        }
        else {
            activeNetworkConfig = getOrCreateAnvilEthConfig();
        }
   }
   
    function getSepoliaEthConfig() public pure returns (NetworkConfig memory){ //we have to use the memory keyword because it is a special object
        NetworkConfig memory sepoliaConfig = NetworkConfig(0x694AA1769357215DE4FAC081bf1f309aDC325306);
        return sepoliaConfig;
    }

    function getOrCreateAnvilEthConfig() public returns (NetworkConfig memory) {
        //1.deploy the mocks (a mock is a contract that we own "kinda like a fake contract")
        //2.Return the mock address
        if(activeNetworkConfig.priceFeed != address(0)){
            return activeNetworkConfig;
        } //in case if the price feed has already been set up

        vm.startBroadcast(); //as we deploy this mock we can not have this function as a pure function anymore
        MockV3Aggregator mockPriceFeed = new MockV3Aggregator(DECIMALS, INITIAL_PRICE);
        vm.stopBroadcast();

        NetworkConfig memory anvilConfig = NetworkConfig({priceFeed : address(mockPriceFeed)});
        return anvilConfig;
    }


    function getMainnetEthConfig() public pure returns (NetworkConfig memory){ //we have to use the memory keyword because it is a special object
        NetworkConfig memory ethConfig = NetworkConfig(0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419);
        return ethConfig;
    }
}