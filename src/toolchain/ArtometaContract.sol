// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Base64.sol";

contract ArtometaContract is Initializable, ERC721Upgradeable, OwnableUpgradeable, UUPSUpgradeable {

    struct ArtometaMetadata {
        string name;
        string description;
        string url;
        bool exists;
    }

    uint256 public _nextTokenId;

    mapping(uint256 tokenId => ArtometaMetadata) public _metadatas;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(address initialOwner) external initializer {
        __ERC721_init("Artometa", "ARP");
        __Ownable_init(initialOwner);
        __UUPSUpgradeable_init();
    }

    function mint(
        string memory name, 
        string memory description,
        string memory url
    ) external returns (uint256) {
        require(bytes(name).length > 0, "name can not be empty");
        require(bytes(description).length > 0, "description can not be empty");
        require(bytes(url).length > 0, "url can not be empty");
        address sender = _msgSender();
        uint256 tokenId = ++_nextTokenId;
        _safeMint(sender, tokenId);
        _metadatas[tokenId] = ArtometaMetadata(name, description, url, true);
        return tokenId;
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        return string(
            abi.encodePacked(
                    "data:application/json;base64,", Base64.encode(bytes(tokenURIJSON(tokenId)))
            )
        );
    }

    function tokenURIJSON(uint256 tokenId) public view returns (string memory) {
        ArtometaMetadata memory metadata = _metadatas[tokenId];
        require(metadata.exists, string(abi.encodePacked("tokenURI #", Strings.toString(tokenId), " not found.")));
        return string(
            abi.encodePacked(
                "{", '"name": "', metadata.name, 
                '", "description": "', metadata.description, 
                '", "image": "', metadata.url, 
                '"', "}"
            )
        );
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}
}
