// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts/proxy/Clones.sol";
import {FutureMarketContract} from "./FutureMarketContract.sol";

contract FutureMarketFactoryContract is OwnableUpgradeable, UUPSUpgradeable {
    address public implementationAddress;

    event FutureMarketCollectionCreated(
        address indexed owner,
        address indexed collectionAddress,
        uint32 startTime,
        uint32 endTime,
        uint32 allocationTime
    );


    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(address _implementation) external initializer {
        __Ownable_init(_msgSender());
        __UUPSUpgradeable_init();

        require(
            _implementation != address(0),
            "_implementation can't be zero address"
        );

        implementationAddress = _implementation;
    }

    function createFutureMarketCollection(
        string calldata name,
        uint32 _startTime,
        uint32 _endTime,
        uint32 _allocationTime
    ) external {
        require(_endTime > _startTime, "Invalid time");
        require(_allocationTime > _endTime, "Invalid time");

        bytes32 salt = keccak256(
            abi.encode(_msgSender(), name, block.timestamp)
        );

        address collection = Clones.cloneDeterministic(
            implementationAddress,
            salt
        );
        address sender = _msgSender();
        (bool success, bytes memory returnData) = collection.call(
            abi.encodeCall(
                FutureMarketContract.initialize,
                (name, sender, _startTime, _endTime, _allocationTime)
            )
        );
        if (!success) {
            assembly {
                revert(add(returnData, 32), mload(returnData))
            }
        }

        emit FutureMarketCollectionCreated(
            sender,
            collection,
            _startTime,
            _endTime,
            _allocationTime
        );
    }

    function _authorizeUpgrade(
        address newImplementation
    ) internal override onlyOwner {}

    function setImplementationAddress(
        address _implementationAddress
    ) external onlyOwner {
        require(
            _implementationAddress != address(0),
            "_implementationAddress can't be zero address"
        );
        implementationAddress = _implementationAddress;
    }
}
