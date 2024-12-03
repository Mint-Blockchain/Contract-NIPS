// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Base64.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "./IMetadataRenderer.sol";

contract MetadataRenderer is IMetadataRenderer, Ownable {

    string private name;
    string private description;

    constructor(
        string memory _defaultName,
        string memory _description
    ) Ownable(_msgSender()) {
        name = _defaultName;
        description = _description;
    }

    function tokenURI(
        uint256 tokenID
    ) external view override returns (string memory) {
        return
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    Base64.encode(bytes(tokenURIJSON(tokenID)))
                )
            );
    }

    function tokenURIJSON(uint256 tokenID) public view returns (string memory) {
        return
            string(
                abi.encodePacked(
                    "{",
                    '"name": "',
                    name,
                    " #",
                    Strings.toString(tokenID),
                    '",',
                    '"description": "',
                    description,
                    '",',
                    '"owner": "',
                    Strings.toHexString(ERC721Upgradeable(msg.sender).ownerOf(tokenID)),
                    '"}'
                )
            );
    }

    function setName(string calldata _newName) external onlyOwner {
        name = _newName;
    }

    function setDescription(string calldata _description) external onlyOwner {
        description = _description;
    }
    
}