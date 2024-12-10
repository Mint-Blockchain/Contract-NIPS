// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "erc721a-upgradeable/ERC721AUpgradeable.sol";
import "erc721a-upgradeable/IERC721AUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts/utils/Base64.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./MintUpCollectionCommonStorage.sol";

contract MintUpCollection is
    MintUpCollectionCommonStorage,
    Initializable,
    ERC721AUpgradeable,
    OwnableUpgradeable,
    ReentrancyGuardUpgradeable
{
    MintConfig public mintConfig;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    modifier isEOA() {
        require(tx.origin == msg.sender, "Invalid caller");
        _;
    }

    modifier isTimeValid() {
        require(block.timestamp > mintConfig.startTime, "Mint not start");

        if (mintConfig.endTime > 0) {
            require(block.timestamp < mintConfig.endTime, "Mint finished");
        }

        _;
    }

    function initialize(
        address initialOwner,
        MintConfig calldata _mintConfig
    ) public initializerERC721A initializer {
        __ERC721A_init(_mintConfig.name, _mintConfig.symbol);
        __Ownable_init(initialOwner);

        _initInfo(_mintConfig);
    }

    function _initInfo(MintConfig calldata _mintConfig) internal {
        if (_mintConfig.endTime > 0) {
            require(
                _mintConfig.endTime > _mintConfig.startTime,
                "Invalid time"
            );
        }
        mintConfig = _mintConfig;
    }

    function mint(
        uint256 amount
    ) external payable nonReentrant isEOA isTimeValid {
        address account = msg.sender;

        require(msg.value >= mintConfig.price * amount, "insufficient balance");

        if (mintConfig.maxSupply > 0) {
            require(
                mintConfig.maxSupply >=
                    amount + _nextTokenId() - _startTokenId(),
                "Over max supply"
            );
        }

        if (mintConfig.maxMint > 0) {
            require(
                mintConfig.maxMint >= amount + _numberMinted(account),
                "Over mint limit"
            );
        }

        _safeMint(account, amount);
        _transferValue();
    }

    function _baseURI() internal view override returns (string memory) {
        return mintConfig.baseURI;
    }

    function tokenURI(
        uint256 tokenId
    ) public view override returns (string memory) {
        require(_exists(tokenId), "Token not exist");

        string memory imageURI;

        if (mintConfig.imageType == IMAGE_TYPE_SINGLE) {
            imageURI = mintConfig.baseURI;
        }

        if (mintConfig.imageType == IMAGE_TYPE_MULIT) {
            imageURI = string.concat(
                mintConfig.baseURI,
                Strings.toString(tokenId),
                ".png"
            );
        }

        return
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    Base64.encode(
                        abi.encodePacked(
                            '{"name":"',
                            name(),
                            " #",
                            Strings.toString(tokenId),
                            '","image":"',
                            imageURI,
                            '"}'
                        )
                    )
                )
            );
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function _sendValue(address to, uint256 amount) private {
        (bool success, ) = payable(to).call{value: amount}("");
        require(success, "Send value failed");
    }

    function _transferValue() private {
        if (mintConfig.price <= 0) {
            return;
        }
        uint256 total = msg.value;
        uint256 fees = (total * PROTOCOL_FEE) / BASIS_POINTS;
        _sendValue(MINT_UP_ADMIN, fees);
        _sendValue(owner(), total - fees);
    }
}
