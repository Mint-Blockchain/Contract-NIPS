//SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts-upgradeable/token/ERC1155/ERC1155Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

contract ERC1155Example is Initializable, ERC1155Upgradeable, OwnableUpgradeable {

    string public name;
    string public symbol;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    // see https://eips.ethereum.org/EIPS/eip-1155#metadata
    // Used as the URI for all token types by relying on ID substitution, e.g. https://token-cdn-domain/{id}.json
    function initialize(address initialOwner, string memory _name, string memory _symbol, 
            bytes calldata extendData) initializer public {
        name = _name;
        symbol = _symbol;
        __ERC1155_init(abi.decode(extendData, (string)));
        __Ownable_init(initialOwner);
    }

    function mint(address to, uint256 id, uint256 value, bytes memory data) external 
    {
        _mint(to, id, value, data);
    }

    function mintBatch(address to, uint256[] memory ids, uint256[] memory values, bytes memory data) external
    {
        _mintBatch(to, ids, values, data);
    }

}