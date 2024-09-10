//SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/console.sol";
import "forge-std/Script.sol";
import {Upgrades} from "openzeppelin-foundry-upgrades/Upgrades.sol";
import "../src/factory/NIPFactoryContract.sol";

contract NIPFactoryContractScript is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        address factoryProxy = Upgrades.deployUUPSProxy(
            "NIPFactoryContract.sol",
            abi.encodeCall(NIPFactoryContract.initialize,
            (0x68C6998e579551e3c84d2Fea4C0a8875dd3E16FC, 0xB8C1f3268520c9ADe36Ed136B921246723eAe9b6,0xB8C1f3268520c9ADe36Ed136B921246723eAe9b6,0xB8C1f3268520c9ADe36Ed136B921246723eAe9b6,0xB8C1f3268520c9ADe36Ed136B921246723eAe9b6,
            0xB8C1f3268520c9ADe36Ed136B921246723eAe9b6,0xB8C1f3268520c9ADe36Ed136B921246723eAe9b6,0xB8C1f3268520c9ADe36Ed136B921246723eAe9b6,0xB8C1f3268520c9ADe36Ed136B921246723eAe9b6,0xB8C1f3268520c9ADe36Ed136B921246723eAe9b6))
        );
        console.log("factoryProxy -> %s", factoryProxy);

        vm.stopBroadcast();
    }
}