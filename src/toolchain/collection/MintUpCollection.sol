// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "erc721a-upgradeable/ERC721AUpgradeable.sol";
import "erc721a-upgradeable/IERC721AUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts/utils/Base64.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract MintUpCollection is
    Initializable,
    ERC721AUpgradeable,
    OwnableUpgradeable,
    ReentrancyGuardUpgradeable
{
    struct MintConfig {
        uint256 maxSupply;
        uint256 maxMint;
        uint64 price;
        uint256 startTime;
        uint256 endTime;
        uint8 imageType;
    }

    uint8 internal constant IMAGE_TYPE_SINGLE = 0;
    uint8 internal constant IMAGE_TYPE_MULIT = 1;
    uint256 public constant BASIS_POINTS = 10000;
    uint256 public constant PROTOCOL_FEE = 500;
    address internal constant MINT_UP_ADMIN =
        0xE6d884c5195Aa6187b554E542DEaDcF0C91a431a;

    string public baseURI;
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
        string memory name,
        string memory symbol,
        bytes calldata extendData
    ) public initializerERC721A initializer {
        __ERC721A_init(name, symbol);
        __Ownable_init(initialOwner);

        _initInfo(extendData);
    }

    function _initInfo(bytes calldata extendData) internal {
        uint256 startTime = block.timestamp;
        string memory baseUri;
        uint256 maxSupply;
        uint256 maxMint;
        uint64 price;
        uint256 endTime;
        uint8 imageType;

        (baseUri, maxSupply, maxMint, price, endTime, imageType) = abi.decode(
            extendData,
            (string, uint256, uint256, uint64, uint256, uint8)
        );

        if (endTime > 0) {
            require(endTime > startTime, "Invalid time");
        }

        baseURI = baseUri;

        mintConfig = MintConfig(
            maxSupply,
            maxMint,
            price,
            startTime,
            endTime,
            imageType
        );
    }

    function mint(
        uint256 amount
    ) external payable nonReentrant isEOA isTimeValid {
        address account = msg.sender;

        require(msg.value >= mintConfig.price * amount, "insufficient balance");

        if (mintConfig.maxSupply > 0) {
            require(
                mintConfig.maxSupply >= amount + totalSupply(),
                "Over max supply"
            );
        }

        if (mintConfig.maxMint > 0) {
            require(
                amount + _numberMinted(account) <= mintConfig.maxMint,
                "Over mint limit"
            );
        }

        _safeMint(account, amount);
        _transferValue();
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function tokenURI(
        uint256 tokenId
    ) public view override returns (string memory) {
        require(_exists(tokenId), "Token not exist");

        string memory imageURI;

        if (mintConfig.imageType == IMAGE_TYPE_SINGLE) {
            imageURI = baseURI;
        }

        if (mintConfig.imageType == IMAGE_TYPE_MULIT) {
            imageURI = string.concat(
                baseURI,
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
