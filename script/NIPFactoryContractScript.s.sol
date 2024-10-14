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

        address[] memory implementations = new address[](11);
        implementations[0] = 0x317331D72e15CE600666A61d86bd6BAA6203163E;
        implementations[1] = 0x3FaE6e07420e8147776A47Ae29df744A2E95d004;
        implementations[2] = 0x12f435157D5acB0C3b0D516353a83D9a2fcc38a9;
        implementations[3] = 0xFe1Df3Cf2f352Fd78c20064259f5e286980644a7;
        implementations[4] = 0xe25b67A6B7D00abe1028bF2cDFCE4e95dA1e56c5;

        implementations[5] = 0x70b3D23F1FCd89A58437bf0533dc81a6ce6D0135;
        implementations[6] = 0x28dB1808983C21804C5FE7892E2D054D28A251e5;
        implementations[7] = 0x0D5462271500a41c18a20C93841D9a51f22C7CdF;
        implementations[8] = 0x5dd4B23e9124DeFcbe001dB7C36ccE93ab338957;
        implementations[9] = 0x020734ee21b44374653cC1E2f62013454F084b76;
        implementations[10] = 0x5C777cA6479321b3B51c60C3704FB79ea788CA16;



        address factoryProxy = Upgrades.deployUUPSProxy(
            "NIPFactoryContract.sol",
            abi.encodeCall(NIPFactoryContract.initialize, implementations)
        );
        console.log("factoryProxy -> %s", factoryProxy);


        // Upgrades.upgradeProxy(
        //     0xe85aCeF13Ca64Ca7b42622eAd50da6FE9928B18E,
        //     "NIPFactoryContract.sol",
        //     ""
        // );
        vm.stopBroadcast();
    }
}