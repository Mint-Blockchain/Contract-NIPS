//SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/interfaces/IERC165.sol";
import "@openzeppelin/contracts/interfaces/IERC721.sol";
import "./../lib/erc4907/ERC4907.sol";

contract ERC4907Example is Initializable, OwnableUpgradeable, ERC4907 {

    string public _baseUri;
    uint256 private _nextTokenId;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(
        address initialOwner,
        string memory name,
        string memory symbol,
        bytes calldata extendData
    ) public initializer {
        __ERC721_init(name, symbol);
        __Ownable_init(initialOwner);
        _initInfo(extendData);
    }

    function _initInfo(bytes calldata extendData) internal {
        _baseUri = abi.decode(extendData, (string));
    }

    function mint(address to) external {
        uint256 tokenId = ++_nextTokenId;
        _safeMint(to, tokenId);
    }

    function _baseURI() internal view override returns (string memory) {
        return _baseUri;
    }
}