// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Base64.sol";

contract MintTwitterContract is
    Initializable,
    ERC721Upgradeable,
    OwnableUpgradeable,
    UUPSUpgradeable
{
    struct TokenMetadata {
        string twitter;
        string url;
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
        __ERC721_init("MintTwitter", "MT");
        __Ownable_init(initialOwner);
        __UUPSUpgradeable_init();
    }

    function mint(
        string memory twitter,
        string memory url
    ) external returns (uint256) {
        require(bytes(twitter).length < 1024, "twitter max size is 1kb");
        require(bytes(url).length < 1024, "url max size is 1kb");
        address sender = _msgSender();
        uint256 tokenId = ++_nextTokenId;
        _safeMint(sender, tokenId);
        _metadatas[tokenId] = TokenMetadata(twitter, url, true);
        return tokenId;
    }

    function setBaseURI(string calldata uri) external onlyOwner {
        _baseUri = uri;
    }

    function tokenURI(
        uint256 tokenId
    ) public view override returns (string memory) {
        return
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    Base64.encode(bytes(tokenURIJSON(tokenId)))
                )
            );
    }

    function tokenURIJSON(uint256 tokenId) public view returns (string memory) {
        TokenMetadata memory metadata = _metadatas[tokenId];
        require(
            metadata.exists,
            string(
                abi.encodePacked(
                    "tokenURI: ",
                    Strings.toString(tokenId),
                    " not found."
                )
            )
        );
        return
            string(
                abi.encodePacked(
                    "{",
                    '"twitter_id": "',
                    metadata.twitter,
                    '", "image": "',
                    metadata.url,
                    '"',
                    "}"
                )
            );
    }

    function _authorizeUpgrade(
        address newImplementation
    ) internal override onlyOwner {}
}
