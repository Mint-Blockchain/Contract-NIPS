// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./RedPacketCommon.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721EnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Base64.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";


contract RedPacketContract is 
    RedPacketCommon,
    ERC721EnumerableUpgradeable, 
    OwnableUpgradeable, 
    ReentrancyGuardUpgradeable, 
    UUPSUpgradeable 
{

    IERC20 public constant USDT = IERC20(0xED85184DC4BECf731358B2C63DE971856623e056); 
    uint256 public constant RED_PACKET_MIN_AMOUNT = 10 ** 4; 
    address internal constant RED_PACKET_SIGNER_ADDRESS = 0x30Ad9B9F4b7399fdaD7B913f41B55Fe84aBC22eF; 

    string public RED_PACKET_COVER_URI = "";
    string public RED_PACKET_GRABBED_COVER_URI = "";

    PacketType public packetType;     
    PacketMode public packetMode;     
    uint256 public totalAmount;       
    uint256 public totalPackets;      
    uint256 public remainingAmount;   
    uint256 public remainingPackets;  
    uint32 public expiration;      

    bytes32 internal RED_PACKET_DOMAIN_SEPARATOR;
    bytes32 internal password;      
    bytes internal whitelist; 
    mapping(uint256 => uint256) internal grabbedAmounts; 
    
    event RedPacketGrab(address indexed claimer, uint256 indexed tokenId, uint256 amount);
    event RedPacketWithdraw(address indexed claimer, uint256 indexed tokenId, uint256 amount);
    event RedPacketRefund(address indexed claimer, uint256 remainingAmount, uint256 remainingPackets);

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(
        string calldata _name,
        string calldata _symbol,
        PacketType _packetType,
        PacketMode _packetMode,
        uint256 _totalAmount,
        uint256 _totalPackets,
        uint32 _expiration,
        bytes32 _password,
        bytes calldata _whitelist,
        address _initialOwner
    ) public initializer {
        __ERC721_init(_name, _symbol);
        __Ownable_init(_initialOwner);
        __ReentrancyGuard_init();
        __UUPSUpgradeable_init();

        require(_packetType == PacketType.Normal || _packetType == PacketType.Password || _packetType == PacketType.Whitelist, "Invalid packet type");
        require(_packetMode == PacketMode.Equal || _packetMode == PacketMode.Lucky, "Invalid packet mode");
        require(_totalAmount >= _totalPackets * RED_PACKET_MIN_AMOUNT, "Insufficient total amount");
        if (_packetMode == PacketMode.Equal) {
            require(_totalAmount % _totalPackets == 0, "totalAmount not divisible by totalPackets");
        }
        require(_totalPackets > 0, "Invalid red packet count");
        require(_expiration >= block.timestamp, "Invalid expiration time");

        if (_packetType == PacketType.Password) {
            require(_password != bytes32(0), "No password set");
        }
        if (_packetType == PacketType.Whitelist) {
            require(_whitelist.length > 0, "No whitelist set");
        }

        packetType = _packetType;
        packetMode = _packetMode;
        totalAmount = _totalAmount;
        totalPackets = _totalPackets;
        remainingAmount = _totalAmount;
        remainingPackets = _totalPackets;
        expiration = _expiration;
        password = _password;
        whitelist = _whitelist;

        RED_PACKET_DOMAIN_SEPARATOR = _computeDomainSeparator();
    }

    function grabRedPacket(
        bytes32 _info,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) external nonReentrant {

        require(tx.origin == msg.sender, "Contracts are not allowed");
        require(expiration >= block.timestamp, "Expired");
        require(remainingPackets > 0, "All packets grabbed");
        require(balanceOf(msg.sender) == 0, "Grabbed");
        if (packetType == PacketType.Password) {
            require(_verifySigner(msg.sender, _info, _v, _r, _s) == RED_PACKET_SIGNER_ADDRESS, "Invalid signature");
        }
        if (packetType == PacketType.Whitelist) {
            require(_verifySigner(msg.sender, _info, _v, _r, _s) == RED_PACKET_SIGNER_ADDRESS, "Invalid signature");
        }
        if (remainingPackets == totalPackets) {
            require(USDT.balanceOf(address(this)) >= totalAmount, "No balance deposit");
        }

        uint256 amount = _calculateRedPacketAmount();
        require(remainingAmount >= amount, "No enough funds");

        uint256 tokenId = totalSupply() + 1;
        grabbedAmounts[tokenId] = amount;
        remainingAmount -= amount;
        remainingPackets -= 1;

        _mint(msg.sender, tokenId);

        emit RedPacketGrab(msg.sender, tokenId, amount);
    }

    function withdrawAmount(uint256 tokenId) external nonReentrant {
        require(ownerOf(tokenId) == msg.sender, "Not NFT owner");

        uint256 amount = grabbedAmounts[tokenId];
        require(amount > 0, "Already claimed or no funds");

        grabbedAmounts[tokenId] = 0;
        SafeERC20.safeTransfer(USDT, msg.sender, amount);

        emit RedPacketWithdraw(msg.sender, tokenId, amount);
    }

    function _calculateRedPacketAmount() internal view returns (uint256) {
        if (packetMode == PacketMode.Equal) {
            return totalAmount / totalPackets;
        } else {
            return _randomAmount(remainingAmount, remainingPackets);
        }
    }

    function _randomAmount(uint256 _remainingAmount, uint256 _remainingPackets) internal view returns (uint256) {
        require(_remainingAmount >= RED_PACKET_MIN_AMOUNT * _remainingPackets, "Remaining amount too low");

        if (_remainingPackets == 1) {
            return _remainingAmount;
        }

        uint256 max = (_remainingAmount * 2) / _remainingPackets;
        uint256 random = uint256(
            keccak256(abi.encodePacked(blockhash(block.number - 1), blockhash(block.number - 2), block.timestamp, block.prevrandao, msg.sender))
        );

        uint256 red = random % max;
        red = red < RED_PACKET_MIN_AMOUNT ? RED_PACKET_MIN_AMOUNT : red;
        if (_remainingAmount < red + (_remainingPackets - 1) * RED_PACKET_MIN_AMOUNT) {
            red = _remainingAmount - (_remainingPackets - 1) * RED_PACKET_MIN_AMOUNT;
        }

        return red;
    }
    
    function getGrabbedAmount(uint256 tokenId) public view returns (uint256)  {
        _requireOwned(tokenId);
        return grabbedAmounts[tokenId];
    }

    function getWhitelist() public view returns (bytes memory) {
        return whitelist;
    }
    
    function getPasswordHash() public view returns (bytes32)  {
        return password;
    }
    
    function refund() public onlyOwner {
        uint256 _remainingAmount = remainingAmount;
        require(_remainingAmount > 0, "No balance");
        require(expiration < block.timestamp, "Not expired yet");
        
        remainingAmount = 0;
        SafeERC20.safeTransfer(USDT, msg.sender, _remainingAmount);

        emit RedPacketRefund(msg.sender, _remainingAmount, remainingPackets);
    }
    
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        _requireOwned(tokenId);
        uint256 _amount = grabbedAmounts[tokenId];
        return 
            string(
                abi.encodePacked(
                    'data:application/json;base64,',
                    Base64.encode(
                        abi.encodePacked(
                            '{"name":"',
                            name(),
                            ' #' ,
                            Strings.toString(tokenId),
                            '","image":"',
                            _amount > 0 ? RED_PACKET_GRABBED_COVER_URI : RED_PACKET_COVER_URI,
                            '","amount":"',
                            _amount,
                            '"}'
                        )
                    )
                )
            );
    }

    function _verifySigner(
        address _recipient,
        bytes32 _info,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) internal view returns (address _signer) {
        _signer = ECDSA.recover(
            keccak256(
                abi.encodePacked(
                    "\x19\x01",
                    RED_PACKET_DOMAIN_SEPARATOR,
                    keccak256(
                        abi.encode(
                            keccak256("RedPacket(address recipient, bytes32 _info)"),
                            _recipient,
                            _info
                        )
                    )
                )
            ), _v, _r, _s
        );
    }

    function _computeDomainSeparator() internal view returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    keccak256(
                        "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
                    ),
                    keccak256(bytes("RedPacketContract")),
                    keccak256("1"),
                    block.chainid,
                    address(this)
                )
            );
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}
}