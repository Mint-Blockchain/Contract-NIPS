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

        address[] memory implementations = new address[](10);
        implementations[0] = 0x760E18B4240792B2Dd9A9ec706d6f413dF339A28;
        implementations[1] = 0x68C6998e579551e3c84d2Fea4C0a8875dd3E16FC;
        implementations[2] = 0x68C6998e579551e3c84d2Fea4C0a8875dd3E16FC;
        implementations[3] = 0x68C6998e579551e3c84d2Fea4C0a8875dd3E16FC;
        implementations[4] = 0x68C6998e579551e3c84d2Fea4C0a8875dd3E16FC;

        implementations[5] = 0x68C6998e579551e3c84d2Fea4C0a8875dd3E16FC;
        implementations[6] = 0x68C6998e579551e3c84d2Fea4C0a8875dd3E16FC;
        implementations[7] = 0x68C6998e579551e3c84d2Fea4C0a8875dd3E16FC;
        implementations[8] = 0x68C6998e579551e3c84d2Fea4C0a8875dd3E16FC;
        implementations[9] = 0x68C6998e579551e3c84d2Fea4C0a8875dd3E16FC;



        address factoryProxy = Upgrades.deployUUPSProxy(
            "NIPFactoryContract.sol",
            abi.encodeCall(NIPFactoryContract.initialize, implementations)
        );
        console.log("factoryProxy -> %s", factoryProxy);

        vm.stopBroadcast();
    }
}