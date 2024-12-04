// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

abstract contract RedPacketCommon {

    struct RedPacket {
        string name;
        RedPacketType redPacketType;
        RedPacketMode redPacketMode;
        uint256 totalAmount;
        uint256 totalPackets;
        uint32 expiration;
        bytes32 password;
        bytes whitelist;
        address initialOwner;
    }

    enum RedPacketType { Normal, Password, Whitelist }
    enum RedPacketMode { Equal, Lucky }
    
    IERC20 public constant USDT = IERC20(0xED85184DC4BECf731358B2C63DE971856623e056); 
    uint256 public constant RED_PACKET_MIN_AMOUNT = 10 ** 4; 
    address internal constant RED_PACKET_SIGNER_ADDRESS = 0x30Ad9B9F4b7399fdaD7B913f41B55Fe84aBC22eF; 

    string public RED_PACKET_COVER_URI = "";
    string public RED_PACKET_GRABBED_COVER_URI = "";
}