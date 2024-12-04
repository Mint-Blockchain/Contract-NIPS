//SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "erc721a-upgradeable/ERC721AUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";

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
    }

    uint256 public constant BASIS_POINTS = 10000;
    uint256 public constant PROTOCOL_FEE = 500;
    address internal constant MINT_UP_ADMIN =
        0xE6d884c5195Aa6187b554E542DEaDcF0C91a431a;

    string public baseURI;
    MintConfig public mintConfig;

    error InvalidCaller();
    error InvalidTime();
    error MintNotStart();
    error MintFinished();
    error OverMaxLimit();
    error SendValueFailed();
    error OverLimit(address minter);
    error InsufficientBalance(address minter);

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
        __ERC721A_init(name, symbol);
        __Ownable_init(initialOwner);
        _initInfo(extendData);
    }

    modifier isEOA() {
        if (tx.origin != msg.sender) revert InvalidCaller();
        _;
    }

    modifier isTimeValid() {
        if (block.timestamp < mintConfig.startTime) {
            revert MintNotStart();
        }

        if (mintConfig.endTime > 0 && block.timestamp > mintConfig.endTime) {
            revert MintFinished();
        }
        _;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function _sendValue(address to, uint256 amount) private {
        (bool success, ) = payable(to).call{value: amount}("");
        if (!success) {
            revert SendValueFailed();
        }
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

    function mint(
        uint256 amount
    ) external payable nonReentrant isEOA isTimeValid {
        address account = msg.sender;

        if (msg.value < mintConfig.price * amount) {
            revert InsufficientBalance(account);
        }

        if (
            mintConfig.maxSupply > 0 &&
            amount + _totalMinted() > mintConfig.maxSupply
        ) {
            revert OverMaxLimit();
        }

        if (
            mintConfig.maxMint > 0 &&
            amount + _numberMinted(account) > mintConfig.maxMint
        ) {
            revert OverLimit(account);
        }

        _safeMint(account, amount);
        _transferValue();
    }

    function _initInfo(bytes calldata extendData) internal {
        uint256 startTime = block.timestamp;
        string memory baseUri;
        uint256 maxSupply;
        uint256 maxMint;
        uint64 price;
        uint256 endTime;

        (baseUri, maxSupply, maxMint, price, endTime) = abi.decode(
            extendData,
            (string, uint256, uint256, uint64, uint256)
        );

        if (startTime > endTime) {
            revert InvalidTime();
        }

        baseURI = baseUri;
        mintConfig = MintConfig(maxSupply, maxMint, price, startTime, endTime);
    }
}
