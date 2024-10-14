//SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "./../lib/erc4400/IEIP721Consumable.sol";

contract ERC4400Example is
    Initializable,
    ERC721Upgradeable,
    OwnableUpgradeable,
    IEIP721Consumable
{
    string public _baseUri;
    uint256 private _nextTokenId;
    mapping(uint256 => address) _tokenConsumers;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(
        address initialOwner,
        string memory name,
        string memory symbol,
        bytes calldata extendData
    ) public initializer {
        __ERC721_init(name, symbol);
        __Ownable_init(initialOwner);
        _initInfo(extendData);
    }

    function consumerOf(uint256 _tokenId) external view returns (address) {
        _requireOwned(_tokenId);
        return _tokenConsumers[_tokenId];
    }

    function changeConsumer(address _consumer, uint256 _tokenId) external {
        address owner = _requireOwned(_tokenId);
        address sender = msg.sender;
        require(
            sender == owner ||
                sender == getApproved(_tokenId) ||
                isApprovedForAll(owner, sender),
            "ERC721Consumable: changeConsumer caller is not owner nor approved"
        );
        _changeConsumer(owner, _consumer, _tokenId);
    }

    function _changeConsumer(
        address _owner,
        address _consumer,
        uint256 _tokenId
    ) internal {
        _tokenConsumers[_tokenId] = _consumer;
        emit ConsumerChanged(_owner, _consumer, _tokenId);
    }

    function transferFrom(
        address _from,
        address _to,
        uint256 _tokenId
    ) public override {
        address owner = _requireOwned(_tokenId);
        address sender = msg.sender;
        require(
            sender == owner,
            "ERC721Consumable: only onwer can do transfer"
        );

        super.transferFrom(_from, _to, _tokenId);
        _changeConsumer(_from, address(0), _tokenId);
    }

    function _baseURI() internal view override returns (string memory) {
        return _baseUri;
    }
    function supportsInterface(
        bytes4 interfaceId
    ) public view override returns (bool) {
        return
            interfaceId == type(IEIP721Consumable).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    function _initInfo(bytes calldata extendData) internal {
        _baseUri = abi.decode(extendData, (string));
    }

    function mint(address to) external {
        uint256 tokenId = ++_nextTokenId;
        _safeMint(to, tokenId);
    }
}
