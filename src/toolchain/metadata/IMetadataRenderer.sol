// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IMetadataRenderer {
    function tokenURI(uint256 tokenID) external view returns (string memory);
}
