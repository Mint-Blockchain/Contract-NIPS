// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts/proxy/Clones.sol";
import {FutureMarketContract} from "./FutureMarketContract.sol";
import {IMetadataRenderer} from "../metadata/IMetadataRenderer.sol";

contract FutureMarketFactoryContract is
    ERC721Upgradeable,
    OwnableUpgradeable,
    UUPSUpgradeable
{
    mapping(uint256 => address) public implementationTypes;

    address public metadataRenderer;

    event FutureMarketCollectionCreated(
        address indexed owner,
        address indexed collectionAddress,
        bytes32 collectionId,
        uint256 collectionType,
        string name,
        string symbol
    );

    error InvalidCaller();

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(address _implementation) external initializer {
        __ERC721_init("FutureMarket Owner", "FMOwner");
        __Ownable_init(_msgSender());
        __UUPSUpgradeable_init();

        require(
            _implementation != address(0),
            "_implementation can't be zero address"
        );

        implementationTypes[0] = _implementation;
    }

    function createFutureMarketCollection(
        bytes32 collectionId,
        uint256 collectionType,
        string calldata name,
        string calldata symbol,
        bytes calldata packedData,
        bytes calldata information
    ) external {
        checkCaller(collectionId);
        require(
            implementationTypes[collectionType] != address(0),
            "Invalid collectionType"
        );
        address collection = Clones.cloneDeterministic(
            implementationTypes[collectionType],
            collectionId
        );

        (bool success, bytes memory returnData) = collection.call(
            abi.encodeCall(
                FutureMarketContract.initialize,
                (name, symbol, packedData, information)
            )
        );
        if (!success) {
            assembly {
                revert(add(returnData, 32), mload(returnData))
            }
        }

        _safeMint(msg.sender, uint256(uint160(collection)));
        emit FutureMarketCollectionCreated(
            msg.sender,
            collection,
            collectionId,
            collectionType,
            name,
            symbol
        );
    }

    function predictDeterministicAddress(
        bytes32 collectionId,
        uint256 collectionType
    ) external view returns (address) {
        return
            Clones.predictDeterministicAddress(
                implementationTypes[collectionType],
                collectionId,
                address(this)
            );
    }

    function checkCaller(bytes32 salt) internal view {
        if (address(bytes20(salt)) != msg.sender) {
            revert InvalidCaller();
        }
    }

    function _authorizeUpgrade(
        address newImplementation
    ) internal override onlyOwner {}

    function tokenURI(
        uint256 tokenId
    ) public view override returns (string memory) {
        _requireOwned(tokenId);
        return IMetadataRenderer(metadataRenderer).tokenURI(tokenId);
    }

    function setMetadataRenderer(address _metadataRenderer) external onlyOwner {
        require(
            _metadataRenderer != address(0),
            "_metadataRenderer can't be zero address"
        );
        metadataRenderer = _metadataRenderer;
    }

    function setImplementationAddress(
        uint256 collectionType,
        address _implementationAddress
    ) external onlyOwner {
        require(
            _implementationAddress != address(0),
            "_implementationAddress can't be zero address"
        );
        implementationTypes[collectionType] = _implementationAddress;
    }

}
