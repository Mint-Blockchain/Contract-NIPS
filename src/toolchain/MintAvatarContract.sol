// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract MintAvatarContract is Initializable, ERC721Upgradeable, OwnableUpgradeable, UUPSUpgradeable {
    struct TokenMetadata {
        string name;
        // 0 -> on-chain-text, 1 -> textFile, 2 -> jpg, 3 -> png, 4 -> svg, 5 -> gif, 6 -> mp4
        uint8 contentType;
        string content;
        bool exists;
    }

    string public _baseUri;
    uint256 public _nextTokenId;

    mapping(uint256 tokenId => TokenMetadata) public _metadatas;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(address initialOwner) external initializer {
        __ERC721_init("MintAvatar", "MA");
        __Ownable_init(initialOwner);
        __UUPSUpgradeable_init();
    }

    function mint(string memory name, uint8 contentType, string memory content) external returns (uint256) {
        address sender = _msgSender();
        uint256 tokenId = ++_nextTokenId;
        _mint(sender, tokenId);
        _metadatas[tokenId] = TokenMetadata(name, contentType, content, true);
        return tokenId;
    }

    function setBaseURI(string calldata uri) external onlyOwner {
        _baseUri = uri;
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        TokenMetadata memory metadata = _metadatas[tokenId];
        require(metadata.exists, string(abi.encodePacked("tokenURI: ", Strings.toString(tokenId), " not found.")));
        if (metadata.contentType == 0) {
            // on-chain-text
            return metadata.content;
        } else {
            return string.concat(_baseUri, metadata.content);
        }
    }

    function getName(uint256 tokenId) external view returns (string memory) {
        TokenMetadata memory metadata = _metadatas[tokenId];
        require(metadata.exists, string(abi.encodePacked("getName: ", Strings.toString(tokenId), " not found.")));
        return metadata.name;
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}
}
