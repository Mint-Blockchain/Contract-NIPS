//SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

abstract contract NIPSERC721 is Initializable, ERC721Upgradeable, OwnableUpgradeable {

    uint256 public _nextTokenId;
    string public _baseUri;

    function initialize(address initialOwner, string memory name, string memory symbol, bytes calldata extendData) initializer public {
        _NIPSERC721_init(initialOwner, name, symbol);
        _initInfo(extendData);
    }


    function _NIPSERC721_init(address initialOwner, string memory name, string memory symbol) internal onlyInitializing {
        __ERC721_init(name, symbol);
        __Ownable_init(initialOwner);
    }


    function _baseURI() internal view override returns (string memory) {
        return _baseUri;
    }

    function mint(address to) external {
        uint256 tokenId = ++_nextTokenId;
        _safeMint(to, tokenId);
    }

    function _initInfo(bytes calldata extendData) internal virtual {}
}