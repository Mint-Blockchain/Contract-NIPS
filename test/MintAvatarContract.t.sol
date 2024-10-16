// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/toolchain/MintAvatarContract.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import {Upgrades} from "openzeppelin-foundry-upgrades/Upgrades.sol";

contract TestMintAvatarContractt is Test {
    address constant OWNER_ADDRESS = 0xC565FC29F6df239Fe3848dB82656F2502286E97d;

    address private proxy;
    MintAvatarContract private instance;

    function setUp() public {
        console.log("=======setUp============");
        proxy = Upgrades.deployUUPSProxy(
            "MintAvatarContract.sol", abi.encodeCall(MintAvatarContract.initialize, OWNER_ADDRESS)
        );
        console.log("uups proxy -> %s", proxy);

        instance = MintAvatarContract(proxy);
        assertEq(instance.owner(), OWNER_ADDRESS);

        address implAddressV1 = Upgrades.getImplementationAddress(proxy);
        console.log("impl proxy -> %s", implAddressV1);
    }

    function testMint() public {
        console.log("testMint");
        // vm.prank(OWNER_ADDRESS);

        vm.startPrank(OWNER_ADDRESS);
        string memory name = unicode"x😁x";
        string memory url = "http://aabb/xxx.jpg";
        uint256 tokenId = instance.mint(name, url);
        assertEq(tokenId, 1, string.concat("tokenId != 1, ", Strings.toString(tokenId)));
        string memory tokenUri = instance.tokenURIJSON(tokenId);
        assertEq(tokenUri, unicode'{"name": "x😁x", "image": "http://aabb/xxx.jpg"}', "tokenUri not match");
        vm.stopPrank();
    }
}
