// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "./../lib/erc5484/IERC5484.sol";

contract ERC5484Example is
    Initializable,
    ERC721Upgradeable,
    OwnableUpgradeable,
    IERC5484
{
    uint256 private _nextTokenId;
    string public _baseUri;
    mapping(uint256 => BurnAuth) private tokenBurnAuths;

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

    function mint(address _to, BurnAuth _burnAuth) external {
        uint256 _tokenId = ++_nextTokenId;
        mintByTokenId(_to, _burnAuth, _tokenId);
    }

    function mintByTokenId(
        address _to,
        BurnAuth _burnAuth,
        uint256 _tokenId
    ) public {
        _safeMint(_to, _tokenId);
        _onIssued(address(0), _to, _tokenId, _burnAuth);
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        revert("ERC5484: non-transferable token");
    }

    function burn(uint256 _tokenId) public {
        require(_isAuthorizedToBurn(_tokenId), "ERC5484: sender cannot burn");

        _burn(_tokenId);
        
        delete tokenBurnAuths[_tokenId];
    }

    function burnAuth(
        uint256 _tokenId
    ) external view override returns (BurnAuth) {
        return _getBurnAuth(_tokenId);
    }

    function _onIssued(
        address _from,
        address _to,
        uint256 _tokenId,
        BurnAuth _burnAuth
    ) internal {
        tokenBurnAuths[_tokenId] = _burnAuth;

        emit Issued(_from, _to, _tokenId, _burnAuth);
    }

    function _getBurnAuth(uint256 _tokenId) private view returns (BurnAuth) {
        require(_ownerOf(_tokenId) != address(0), "ERC5484: invalid tokenId");
        return tokenBurnAuths[_tokenId];
    }

    function _isAuthorizedToBurn(uint256 _tokenId) private view returns (bool) {
        BurnAuth burnAuthorization = _getBurnAuth(_tokenId);

        return
            (msg.sender == owner() &&
                (burnAuthorization == BurnAuth.IssuerOnly ||
                    burnAuthorization == BurnAuth.Both)) ||
            (msg.sender == ownerOf(_tokenId) &&
                (burnAuthorization == BurnAuth.OwnerOnly ||
                    burnAuthorization == BurnAuth.Both));
    }

    function _baseURI() internal view override returns (string memory) {
        return _baseUri;
    }

    function _initInfo(bytes calldata extendData) internal {
        _baseUri = abi.decode(extendData, (string));
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override returns (bool) {
        return
            interfaceId == type(IERC5484).interfaceId ||
            super.supportsInterface(interfaceId);
    }
}
