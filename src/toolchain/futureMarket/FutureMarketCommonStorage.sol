// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

abstract contract FutureMarketCommonStorage {

    uint32 public startTime;
    uint32 public endTime;
    uint32 public allocationTime;

    event Bet(
        address indexed recipient,
        address indexed collection,
        uint256 indexed tokenId,
        uint256 amount,
        uint256 solution
    );

    event CorrectSolution(
        address indexed recipient,
        uint256 solution
    );

    event ClaimRewards(
        address indexed recipient,
        uint256 claimedAmount
    );

    uint256 public constant A_SOLUTION = 1;
    uint256 public constant B_SOLUTION = 2;

    uint256 public correctSolution;
    string public correctSolutionDesc;
    bool public correctSolutionStatus;

    uint256 public totalAmounts;

    uint256 public platformAmounts;
    uint256 public ownerAmounts;
    uint256 public winnerAllocationAmounts;

    mapping(uint256 solution => uint256 amounts) public solutionAmounts;
    mapping(uint256 solution => uint256 counts) public solutionNumber;

    mapping(uint256 tokenId => uint256 solution) public tokenSolution;
    mapping(uint256 tokenId => uint256 amounts) public tokenAmounts;

    mapping(uint256 tokenId => bool) public rewardsClaimed;
    mapping(address winner => uint256 amounts) public winnerClaimedAmounts;

    string public constant BASE_URI = "";
    address public constant PLATFORM_ADDRESS =
        0xC565FC29F6df239Fe3848dB82656F2502286E97d;
    address public constant USDT_ADDRESS =
        0x05D032ac25d322df992303dCa074EE7392C117b9;
    address public constant COMMITTEE_ADDRESS =
        0x05D032ac25d322df992303dCa074EE7392C117b9;
}
