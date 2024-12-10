// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts/proxy/Clones.sol";
import {MintUpCollection} from "./MintUpCollection.sol";
import "./MintUpCollectionCommonStorage.sol";

contract MintUpCollectionFactoryContract is
    MintUpCollectionCommonStorage,
    OwnableUpgradeable,
    UUPSUpgradeable
{
    address public implementationAddress;

    event NFTCollectionCreated(
        address indexed owner,
        address indexed collectionAddress,
        string name,
        string symbol
    );

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(address _implementationAddress) external initializer {
        __Ownable_init(_msgSender());
        __UUPSUpgradeable_init();

        require(
            _implementationAddress != address(0),
            "_implementationAddress can't be zero address"
        );

        implementationAddress = _implementationAddress;
    }

    function createNFTCollection(
        MintConfig calldata _mintConfig
    ) external returns (address) {
        address sender = _msgSender();
        bytes32 salt = keccak256(
            abi.encode(
                sender,
                _mintConfig.name,
                _mintConfig.symbol,
                block.timestamp
            )
        );
        address collection = Clones.cloneDeterministic(
            implementationAddress,
            salt
        );

        (bool success, bytes memory returnData) = collection.call(
            abi.encodeCall(MintUpCollection.initialize, (sender, _mintConfig))
        );

        if (!success) {
            assembly {
                revert(add(returnData, 32), mload(returnData))
            }
        }

        emit NFTCollectionCreated(
            sender,
            collection,
            _mintConfig.name,
            _mintConfig.symbol
        );

        return collection;
    }

    function setImplementationAddress(
        address _implementationAddress
    ) external onlyOwner {
        require(
            _implementationAddress != address(0),
            "_implementationAddress can't be zero address"
        );
        implementationAddress = _implementationAddress;
    }

    function _authorizeUpgrade(
        address newImplementation
    ) internal override onlyOwner {}
}
