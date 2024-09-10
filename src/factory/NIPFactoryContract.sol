//SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts/proxy/Clones.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

import "../examples/ERC721Example.sol";

contract NIPFactoryContract is ERC721Upgradeable, OwnableUpgradeable, UUPSUpgradeable {

    mapping(uint256 => address) public implementationTypes;

    event NFTCollectionCreated(address indexed owner, address indexed collectionAddress, uint256 collectionType, string name, string symbol);

    error InvalidCaller();

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(
        address[] memory _implementations
    ) initializer external {
        __ERC721_init("NIPS Owner", "NIPOwner");
        __Ownable_init(_msgSender());
        __UUPSUpgradeable_init();
        for (uint i = 0; i < _implementations.length; i++) {
            implementationTypes[i+1] = _implementations[i];
        }
    }

    function createNFTCollection(
        string memory _name,
        string memory _symbol,
        uint256 _collectionType,
        bytes calldata _extendData
    ) external returns (address) {
        require(implementationTypes[_collectionType] != address(0), "Invalid collectionType");

        address sender = _msgSender();
        bytes32 salt = keccak256(abi.encode(sender, _name, _symbol, block.timestamp));
        address collection = Clones.cloneDeterministic(implementationTypes[_collectionType], salt);

        if (_collectionType == 0) {
            (bool success, bytes memory returnData) = collection.call(abi.encodeCall(
            ERC721Example.initialize, (sender, _name, _symbol, _extendData)));
            if (!success) {
                assembly {
                    revert(add(returnData, 32), mload(returnData))
                }
            }
        }
        emit NFTCollectionCreated(msg.sender, collection, _collectionType, _name, _symbol);
        return collection;
    }

    function checkCaller(bytes32 salt) internal view {
        if (address(bytes20(salt)) != msg.sender) {
            revert InvalidCaller();
        }
    }



    function _authorizeUpgrade(address newImplementation)
        internal
        onlyOwner
        override
    {}
}