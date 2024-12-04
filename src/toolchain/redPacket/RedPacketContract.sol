// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./RedPacketCommon.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Base64.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";


contract RedPacketContract is RedPacketCommon, ERC721Upgradeable, OwnableUpgradeable {

    RedPacketType public redPacketType;     
    RedPacketMode public redPacketMode;     
    uint256 public totalAmount;       
    uint256 public totalPackets;      
    uint256 public remainingAmount;   
    uint256 public remainingPackets;  
    uint32 public expiration;      

    uint256 private _nextTokenId;
    bytes32 internal RED_PACKET_DOMAIN_SEPARATOR;
    bytes32 internal password;      
    bytes internal whitelist; 
    mapping(uint256 => uint256) internal grabbedTokenId; 
    mapping(address => uint256) internal grabbedAddress; 
    mapping(uint256 => uint256) internal withdrawnTokenId; 
    
    event RedPacketGrab(address indexed claimer, uint256 indexed tokenId, uint256 amount, uint256 remainingAmount, uint256 remainingPackets);
    event RedPacketWithdraw(address indexed claimer, uint256 indexed tokenId, uint256 amount);
    event RedPacketRefund(address indexed claimer, uint256 remainingAmount, uint256 remainingPackets);

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(RedPacket calldata redPacket) external {
        
        __ERC721_init(redPacket.name, "RP");
        __Ownable_init(redPacket.initialOwner);

        require(redPacket.redPacketType == RedPacketType.Normal || redPacket.redPacketType == RedPacketType.Password || redPacket.redPacketType == RedPacketType.Whitelist, "Invalid packet type");
        require(redPacket.redPacketMode == RedPacketMode.Equal || redPacket.redPacketMode == RedPacketMode.Lucky, "Invalid packet mode");
        require(redPacket.totalAmount >= redPacket.totalPackets * RED_PACKET_MIN_AMOUNT, "Insufficient total amount");
        require(redPacket.totalPackets > 0, "Invalid red packet count");
        if (redPacket.redPacketMode == RedPacketMode.Equal) {
            require(redPacket.totalAmount % redPacket.totalPackets == 0, "totalAmount not divisible by totalPackets");
            require(redPacket.totalAmount % RED_PACKET_MIN_AMOUNT == 0, "totalAmount not divisible by RED_PACKET_MIN_AMOUNT");
        }
        require(redPacket.expiration >= block.timestamp, "Invalid expiration time");

        if (redPacket.redPacketType == RedPacketType.Password) {
            require(redPacket.password != bytes32(0), "No password set");
        }
        if (redPacket.redPacketType == RedPacketType.Whitelist) {
            require(redPacket.whitelist.length > 0, "No whitelist set");
        }

        redPacketType = redPacket.redPacketType;
        redPacketMode = redPacket.redPacketMode;
        totalAmount = redPacket.totalAmount;
        totalPackets = redPacket.totalPackets;
        remainingAmount = redPacket.totalAmount;
        remainingPackets = redPacket.totalPackets;
        expiration = redPacket.expiration;
        password = redPacket.password;
        whitelist = redPacket.whitelist;

        RED_PACKET_DOMAIN_SEPARATOR = _computeDomainSeparator();
    }

    function grabRedPacket(
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) external {

        require(tx.origin == msg.sender, "Contracts are not allowed");
        require(expiration >= block.timestamp, "Expired");
        require(remainingPackets > 0, "All packets grabbed");
        require(grabbedAddress[msg.sender] == 0, "Grabbed");
        if (redPacketType == RedPacketType.Password) {
            require(_verifySigner(msg.sender, password, _v, _r, _s) == RED_PACKET_SIGNER_ADDRESS, "Invalid signature");
        }
        if (redPacketType == RedPacketType.Whitelist) {
            require(_verifySigner(msg.sender, bytes32(0), _v, _r, _s) == RED_PACKET_SIGNER_ADDRESS, "Invalid signature");
        }

        uint256 amount = _calculateRedPacketAmount();
        require(remainingAmount >= amount, "No enough funds");

        uint256 tokenId = ++_nextTokenId;
        grabbedTokenId[tokenId] = amount;
        grabbedAddress[msg.sender] = amount;
        remainingAmount -= amount;
        remainingPackets -= 1;

        _mint(msg.sender, tokenId);

        emit RedPacketGrab(msg.sender, tokenId, amount, remainingAmount, remainingPackets);
    }

    function withdrawAmount(uint256 tokenId) external {

        uint256 _amount = grabbedTokenId[tokenId];
        require(_amount > 0, "Not grabbed");
        require(ownerOf(tokenId) == msg.sender, "Not NFT owner");
        require(withdrawnTokenId[tokenId] == 0, "Already claimed");

        withdrawnTokenId[tokenId] = _amount; 
        SafeERC20.safeTransfer(USDT, msg.sender, _amount);

        emit RedPacketWithdraw(msg.sender, tokenId, _amount);
    }

    function _calculateRedPacketAmount() internal view returns (uint256) {
        if (redPacketMode == RedPacketMode.Equal) {
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

        uint256 max = ((_remainingAmount * 2) / _remainingPackets) / RED_PACKET_MIN_AMOUNT * RED_PACKET_MIN_AMOUNT;
        uint256 random = uint256(
            keccak256(abi.encodePacked(blockhash(block.number - 1), blockhash(block.number - 2), block.timestamp, block.prevrandao, msg.sender, _remainingPackets))
        );

        uint256 red = (random % max) / RED_PACKET_MIN_AMOUNT * RED_PACKET_MIN_AMOUNT;
        red = red < RED_PACKET_MIN_AMOUNT ? RED_PACKET_MIN_AMOUNT : red;
        if (red == max) {
            red -= RED_PACKET_MIN_AMOUNT;
        }
        if (_remainingAmount < red + (_remainingPackets - 1) * RED_PACKET_MIN_AMOUNT) {
            red = _remainingAmount - (_remainingPackets - 1) * RED_PACKET_MIN_AMOUNT;
        }

        return red;
    }
    
    function getGrabbedAmount(uint256 tokenId) public view returns (uint256)  {
        _requireOwned(tokenId);
        return grabbedTokenId[tokenId];
    }
    
    function getWithdrawnAmount(uint256 tokenId) public view returns (uint256)  {
        _requireOwned(tokenId);
        return withdrawnTokenId[tokenId];
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
        uint256 _amount = grabbedTokenId[tokenId];
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
}