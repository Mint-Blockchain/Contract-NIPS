//SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "erc721a-upgradeable/ERC721AUpgradeable.sol";

contract ERC721AExample is
    Initializable,
    OwnableUpgradeable,
    ERC721AUpgradeable
{
    string public _baseUri;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(
        address initialOwner,
        string memory name,
        string memory symbol,
        bytes calldata extendData
    ) public initializerERC721A initializer {
        __ERC721A_init(name, symbol);
        __Ownable_init(initialOwner);
        _initInfo(extendData);
    }

    function _baseURI() internal view override returns (string memory) {
        return _baseUri;
    }

    function mint(address to, uint256 quantity) external {
        _safeMint(to, quantity);
    }

    function _initInfo(bytes calldata extendData) internal {
        _baseUri = abi.decode(extendData, (string));
    }
}
