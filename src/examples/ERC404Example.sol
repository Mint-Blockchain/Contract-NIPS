//SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "../lib/erc404/ERC404.sol";

contract ERC404Example is ERC404, OwnableUpgradeable {

    string public _baseUri;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(address initialOwner, string memory name, string memory symbol, bytes calldata extendData) initializer public {
        __Ownable_init(initialOwner);
        __ERC404_init(name, symbol, 18, 1);
        _initInfo(extendData);
    }

    function mint(uint numberOfTokens) external {
        _mintERC20(_msgSender(), numberOfTokens * units);
    }

    function _initInfo(bytes calldata extendData) internal {
        _baseUri = abi.decode(extendData, (string));
    }

    function tokenURI(
        uint256 tokenId
    ) public view override returns (string memory) {
        require(ownerOf(tokenId) != address(0), "Invalid tokenId");
        return string.concat(_baseUri,Strings.toString(tokenId - ID_ENCODING_PREFIX));
    }
}