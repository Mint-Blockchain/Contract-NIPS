// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/toolchain/MintInscriptionContract.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import {Upgrades} from "openzeppelin-foundry-upgrades/Upgrades.sol";

contract TestMintInscriptionContractt is Test {
    address constant OWNER_ADDRESS = 0xC565FC29F6df239Fe3848dB82656F2502286E97d;

    address private proxy;
    MintInscriptionContract private instance;

    function setUp() public {
        console.log("=======setUp============");
        proxy = Upgrades.deployUUPSProxy(
            "MintInscriptionContract.sol", abi.encodeCall(MintInscriptionContract.initialize, OWNER_ADDRESS)
        );
        console.log("uups proxy -> %s", proxy);

        instance = MintInscriptionContract(proxy);
        assertEq(instance.owner(), OWNER_ADDRESS);

        address implAddressV1 = Upgrades.getImplementationAddress(proxy);
        console.log("impl proxy -> %s", implAddressV1);
    }

    function testMint() public {
        console.log("testMint");
        // vm.prank(OWNER_ADDRESS);

        vm.startPrank(OWNER_ADDRESS);
        string memory name = unicode"x😁x";
        string memory contentId = "aaaaaaaaabbbbbbb";
        uint256 tokenId = instance.mint(name, contentId);
        assertEq(tokenId, 1, string.concat("tokenId != 1, ", Strings.toString(tokenId)));
        string memory tokenUri = instance.tokenURIJSON(tokenId);
        assertEq(tokenUri, unicode'{"name": "x😁x", "inscription": "aaaaaaaaabbbbbbb"}', "tokenUri not match");
        vm.stopPrank();
    }
}
