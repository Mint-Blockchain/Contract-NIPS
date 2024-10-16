//SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "erc721a-upgradeable/ERC721AUpgradeable.sol";

contract ERC2309Example is Initializable, ERC721AUpgradeable, OwnableUpgradeable {

    string public _baseUri;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(address initialOwner, string memory name, string memory symbol, bytes calldata extendData) initializerERC721A initializer public {
        __ERC721A_init(name, symbol);
        __Ownable_init(initialOwner);
        _initInfo(extendData);
    }

    function _initInfo(bytes calldata extendData) internal {
        _baseUri = abi.decode(extendData, (string));
    }
    
    /**
     * @dev Mint a batch of tokens of length `quantity` for `to`.
     */
    function mintConsecutive(address to, uint256 quantity) external {
        _mintERC2309(to, quantity);
    }

    function _baseURI() internal view override returns (string memory) {
        return _baseUri;
    }
}