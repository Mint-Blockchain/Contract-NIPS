// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "./RedPacketCommon.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts/proxy/Clones.sol";
import { RedPacketContract } from "./RedPacketContract.sol";

contract RedPacketFactoryContract is RedPacketCommon, OwnableUpgradeable, UUPSUpgradeable {

    address public implementationAddress;

    event RedPacketCreated(
        address indexed owner, 
        address indexed collectionAddress, 
        string name, 
        string symbol,
        PacketType packetType,
        PacketMode packetMode,  
        uint256 totalAmount,
        uint256 totalPackets,
        uint32 expiration,
        bytes32 password,
        bytes whitelist
    );

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(
        address _implementationAddress
    ) initializer external {
        __Ownable_init(_msgSender());
        __UUPSUpgradeable_init();

        require(_implementationAddress != address(0), "_implementationAddress can't be zero address"); 

        implementationAddress = _implementationAddress;
    }

    function createRedPacketCollection(
        string calldata _name,
        string calldata _symbol,
        PacketType _packetType,
        PacketMode _packetMode,
        uint256 _totalAmount,
        uint256 _totalPackets,
        uint32 _expiration,
        bytes32 _password,
        bytes calldata _whitelist
    ) external {

        bytes32 salt = keccak256(abi.encode(_msgSender(), _name, _symbol, block.timestamp));
        address collection = Clones.cloneDeterministic(implementationAddress, salt);
        (bool success, bytes memory returnData) = collection.call(abi.encodeCall(
            RedPacketContract.initialize, (_name, _symbol, _packetType, _packetMode, _totalAmount, _totalPackets, _expiration, _password, _whitelist, _msgSender())));
        if (!success) {
            assembly {
                revert(add(returnData, 32), mload(returnData))
            }
        }

        emit RedPacketCreated(_msgSender(), collection, _name, _symbol, _packetType, _packetMode, _totalAmount, _totalPackets, _expiration, _password, _whitelist);
    }

    function setImplementationAddress(address _implementationAddress) external onlyOwner {
        require(_implementationAddress != address(0), "_implementationAddress can't be zero address"); 
        implementationAddress = _implementationAddress;
    }

    function _authorizeUpgrade(address newImplementation)
        internal
        onlyOwner
        override
    {}
}