// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/proxy/Clones.sol";
import "./RedPacketCommon.sol";
import { RedPacketContract } from "./RedPacketContract.sol";

contract RedPacketFactoryContract is RedPacketCommon, OwnableUpgradeable, UUPSUpgradeable {

    address public implementationAddress;

    event RedPacketCreated(
        address indexed owner, 
        address indexed collectionAddress, 
        string name, 
        RedPacketType redPacketType,
        RedPacketMode redPacketMode,  
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

    function createRedPacketCollection(RedPacket calldata redPacket) external {

        bytes32 salt = keccak256(abi.encode(_msgSender(), redPacket.name, block.timestamp));
        address collection = Clones.cloneDeterministic(implementationAddress, salt);
        (bool success, bytes memory returnData) = collection.call(abi.encodeCall(
            RedPacketContract.initialize, redPacket));
        if (!success) {
            assembly {
                revert(add(returnData, 32), mload(returnData))
            }
        }

        require(USDT.allowance(address(this), collection) >= redPacket.totalAmount, 'Not enough USDT deposit');
        SafeERC20.safeTransfer(USDT, collection, redPacket.totalAmount);
        emit RedPacketCreated(_msgSender(), collection, redPacket.name, redPacket.redPacketType, redPacket.redPacketMode, redPacket.totalAmount, redPacket.totalPackets, redPacket.expiration, redPacket.password, redPacket.whitelist);
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