// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

abstract contract MintUpCollectionCommonStorage {
    struct MintConfig {
        string name;
        string symbol;
        string baseURI;
        uint256 maxSupply;
        uint256 maxMint;
        uint64 price;
        uint256 startTime;
        uint256 endTime;
        uint8 imageType;
    }

    uint8 internal constant IMAGE_TYPE_SINGLE = 0;
    uint8 internal constant IMAGE_TYPE_MULIT = 1;
    uint256 public constant BASIS_POINTS = 10000;
    uint256 public constant PROTOCOL_FEE = 500;
    address internal constant MINT_UP_ADMIN =
        0xE6d884c5195Aa6187b554E542DEaDcF0C91a431a;
}
