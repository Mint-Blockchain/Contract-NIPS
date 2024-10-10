// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/token/common/ERC2981Upgradeable.sol";

contract ERC2981Example is
    Initializable,
    ERC721Upgradeable,
    OwnableUpgradeable,
    ERC2981Upgradeable
{
    uint256 private _nextTokenId;
    string public _baseUri;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(
        address initialOwner,
        string memory name,
        string memory symbol,
        address royaltyReceiver,
        uint96 feeNumerator,
        bytes calldata extendData
    ) public initializer {
        __ERC721_init(name, symbol);
        __Ownable_init(initialOwner);

        _setDefaultRoyalty(royaltyReceiver, feeNumerator);
        _initInfo(extendData);
    }

    function _baseURI() internal view override returns (string memory) {
        return _baseUri;
    }

    function mint(address to) external {
        uint256 tokenId = ++_nextTokenId;
        _safeMint(to, tokenId);
    }

    function _initInfo(bytes calldata extendData) internal {
        _baseUri = abi.decode(extendData, (string));
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721Upgradeable, ERC2981Upgradeable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

}