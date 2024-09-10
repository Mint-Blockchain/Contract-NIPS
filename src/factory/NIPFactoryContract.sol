//SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts/proxy/Clones.sol";
import "../examples/ERC721Example.sol";

contract NIPFactoryContract is ERC721Upgradeable, OwnableUpgradeable, UUPSUpgradeable {

    mapping(uint256 => address) public implementationTypes;

    event NFTCollectionCreated(address indexed owner, address indexed collectionAddress, bytes32 collectionId, uint256 collectionType, string name, string symbol);

    error InvalidCaller();

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(
        address _implementationERC721,
        address _implementationERC721A,
        address _implementationERC1155,
        address _implementationERC404,
        address _implementationERC2309,
        address _implementationERC2981,
        address _implementationERC4400,
        address _implementationERC4906,
        address _implementationERC4907,
        address _implementationERC5007
    ) initializer external {
        __ERC721_init("NIPS Owner", "NIPOwner");
        __Ownable_init(_msgSender());
        __UUPSUpgradeable_init();

        require(_implementationERC721 != address(0), "_implementationERC721 can't be zero address");
        require(_implementationERC721A != address(0), "_implementationERC721A can't be zero address");
        require(_implementationERC1155 != address(0), "_implementationERC1155 can't be zero address");
        require(_implementationERC404 != address(0), "_implementationERC404 can't be zero address");
        require(_implementationERC2309 != address(0), "_implementationERC2309 can't be zero address");

        require(_implementationERC2981 != address(0), "_implementationERC2981 can't be zero address"); 
        require(_implementationERC4400 != address(0), "_implementationERC4400 can't be zero address");
        require(_implementationERC4906 != address(0), "_implementationERC4906 can't be zero address");
        require(_implementationERC4907 != address(0), "_implementationERC4907 can't be zero address");
        require(_implementationERC5007 != address(0), "_implementationERC5007 can't be zero address");

        implementationTypes[0] = _implementationERC721;
        implementationTypes[1] = _implementationERC721A;
        implementationTypes[2] = _implementationERC1155;
        implementationTypes[3] = _implementationERC404;
        implementationTypes[4] = _implementationERC2309;
        
        implementationTypes[5] = _implementationERC2981;
        implementationTypes[6] = _implementationERC4400;
        implementationTypes[7] = _implementationERC4906;
        implementationTypes[8] = _implementationERC4907;
        implementationTypes[9] = _implementationERC5007;
    }

    function createNFTCollection(
        string memory _name,
        string memory _symbol,
        bytes32 _colectionId,
        uint256 _collectionType
    ) external returns (address) {
        checkCaller(_colectionId);
        require(implementationTypes[_collectionType] != address(0), "Invalid collectionType");

        address collection = Clones.cloneDeterministic(implementationTypes[_collectionType], _colectionId);

        if (_collectionType == 0) {
            (bool success, bytes memory returnData) = collection.call(abi.encodeCall(
            ERC721Example.initialize, (_msgSender(), _name, _symbol)));
            if (!success) {
                assembly {
                    revert(add(returnData, 32), mload(returnData))
                }
            }
        }
        emit NFTCollectionCreated(msg.sender, collection, _colectionId, _collectionType, _name, _symbol);
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