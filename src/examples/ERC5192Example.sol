// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "./../lib/erc5192/IERC5192.sol";

contract ERC5192Example is
    Initializable,
    ERC721Upgradeable,
    OwnableUpgradeable,
    IERC5192
{
    uint256 private _nextTokenId;
    string public _baseUri;
    mapping(uint256 => bool) private _lockedTokens;

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

    function _baseURI() internal view override returns (string memory) {
        return _baseUri;
    }

    function mint(address to) external {
        uint256 tokenId = ++_nextTokenId;
        _safeMint(to, tokenId);
        _lockToken(tokenId);
    }

    function _lockToken(uint256 tokenId) internal {
        require(_exists(tokenId), "ERC5192: Token does not exist");
        _lockedTokens[tokenId] = true;
        emit Locked(tokenId);
    }

    function _unlockToken(uint256 tokenId) internal {
        require(_exists(tokenId), "ERC5192: Token does not exist");
        require(_lockedTokens[tokenId], "ERC5192: Token is not locked");
        _lockedTokens[tokenId] = false;
        emit Unlocked(tokenId);
    }

    function unlockToken(uint256 tokenId) external onlyOwner {
        _unlockToken(tokenId);
    }

    function locked(uint256 tokenId) external view override returns (bool) {
        require(_exists(tokenId), "ERC5192: Query for nonexistent token");
        return _lockedTokens[tokenId];
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        require(!_lockedTokens[tokenId], "ERC5192: Token is locked");

        super.transferFrom(from, to, tokenId);
    }

    function burn(uint256 tokenId) public {
        _burn(tokenId);
        if (_lockedTokens[tokenId]) {
            delete _lockedTokens[tokenId];
        }
    }

    function _initInfo(bytes calldata extendData) internal {
        _baseUri = abi.decode(extendData, (string));
    }

    function _exists(uint256 tokenId) internal view returns (bool) {
        return _ownerOf(tokenId) != address(0);
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override returns (bool) {
        return
            interfaceId == type(IERC5192).interfaceId ||
            interfaceId == type(IERC165).interfaceId ||
            super.supportsInterface(interfaceId);
    }
}
