// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./../lib/erc7765/IERC7765.sol";

contract ERC7765Example is
    Initializable,
    ERC721Upgradeable,
    IERC7765,
    OwnableUpgradeable
{
    string public _baseUri;
    uint256 private _nextTokenId;

    uint256 public constant PRIVILEGE_ID = 1;

    mapping(uint256 tokenId => address to) public tokenPrivilegeAddress;
    mapping(address to => uint256[] tokenIds) public addressPrivilegedUsedToken;

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

    function exercisePrivilege(
        address _to,
        uint256 _tokenId,
        uint256 _privilegeId,
        bytes calldata
    ) external override {
        _requireOwned(_tokenId);
        require(PRIVILEGE_ID == _privilegeId, "Invalid _privilegeId");
        tokenPrivilegeAddress[_tokenId] = _to;
        addressPrivilegedUsedToken[_to].push(_tokenId);

        emit PrivilegeExercised(_msgSender(), _to, _tokenId, _privilegeId);
    }

    function isExercisable(
        address,
        uint256 _tokenId,
        uint256 _privilegeId
    ) external view override returns (bool _exercisable) {
        _requireOwned(_tokenId);
        require(PRIVILEGE_ID == _privilegeId, "Invalid _privilegeId");
        return tokenPrivilegeAddress[_tokenId] == address(0);
    }

    function isExercised(
        address _to,
        uint256 _tokenId,
        uint256 _privilegeId
    ) external view override returns (bool _exercised) {
        _requireOwned(_tokenId);
        require(PRIVILEGE_ID == _privilegeId, "Invalid _privilegeId");
        return
            tokenPrivilegeAddress[_tokenId] != address(0) &&
            tokenPrivilegeAddress[_tokenId] == _to;
    }

    function hasBeenExercised(
        uint256 _tokenId,
        uint256 _privilegeId
    ) external view returns (bool _exercised) {
        _requireOwned(_tokenId);
        require(PRIVILEGE_ID == _privilegeId, "Invalid _privilegeId");
        return tokenPrivilegeAddress[_tokenId] != address(0);
    }

    function getPrivilegeIds(
        uint256 _tokenId
    ) external view returns (uint256[] memory privilegeIds) {
        _requireOwned(_tokenId);
        privilegeIds = new uint256[](1);
        privilegeIds[0] = PRIVILEGE_ID;
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public view override returns (bool) {
        return
            interfaceId == type(IERC7765).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    function _baseURI() internal view override returns (string memory) {
        return _baseUri;
    }
    function _initInfo(bytes calldata extendData) internal {
        _baseUri = abi.decode(extendData, (string));
    }

    function mint(address to) external {
        uint256 tokenId = ++_nextTokenId;
        _safeMint(to, tokenId);
    }
}
