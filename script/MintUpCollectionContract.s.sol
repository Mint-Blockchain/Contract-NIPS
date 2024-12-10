// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "forge-std/console.sol";
import "forge-std/Script.sol";
import {Upgrades} from "openzeppelin-foundry-upgrades/Upgrades.sol";
import "../src/toolchain/collection/MintUpCollectionFactoryContract.sol";

contract MintUpCollectionContractScript is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        address contractAddress = vm.envAddress("CONTRACT_ADDRESS");

        address uupsProxy = Upgrades.deployUUPSProxy(
            "MintUpCollectionFactoryContract.sol",
            abi.encodeCall(
                MintUpCollectionFactoryContract.initialize,
                (contractAddress)
            )
        );

        console.log("uupsProxy deploy at %s", uupsProxy);

        vm.stopBroadcast();
    }
}
