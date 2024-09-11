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
        uint8 contentType;
        string contentId;
        bool exists;
    }

    string public _mediaURI;
    string public _textURI;
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

    function mint(string memory name, uint8 contentType, string memory contentId) external returns (uint256) {
        address sender = _msgSender();
        uint256 tokenId = ++_nextTokenId;
        _mint(sender, tokenId);
        _metadatas[tokenId] = TokenMetadata(name, contentType, contentId, true);
        return tokenId;
    }

    function setTextURI(string calldata uri) external onlyOwner {
        _textURI = uri;
    }

    function setMediaURI(string calldata uri) external onlyOwner {
        _mediaURI = uri;
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        TokenMetadata memory metadata = _metadatas[tokenId];
        require(metadata.exists, string(abi.encodePacked("tokenURI: ", Strings.toString(tokenId), " not found.")));
        if (metadata.contentType == 1) {
            return string.concat(_textURI, metadata.contentId);
        } else {
            return string.concat(_mediaURI, metadata.contentId);
        }
    }

    function getName(uint256 tokenId) external view returns (string memory) {
        TokenMetadata memory metadata = _metadatas[tokenId];
        require(metadata.exists, string(abi.encodePacked("getName: ", Strings.toString(tokenId), " not found.")));
        return metadata.name;
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}
}
