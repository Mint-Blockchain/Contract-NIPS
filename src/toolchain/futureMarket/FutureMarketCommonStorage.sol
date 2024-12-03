// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;


abstract contract FutureMarketCommonStorage {

    struct InvestTimeConfig {
        uint32 startTime;
        uint32 endTime;
        uint32 allocationTime;
    }
    InvestTimeConfig public investTimeConfig;

    event FutureMarket(
        address indexed recipient,
        address indexed collection,
        uint256 indexed tokenId,
        uint256 amount,
        Solution solution
    );

    event CorrectSolution(
        address indexed recipient,
        address indexed collection,
        Solution solution
    );

    event ClaimRewards(
        address indexed recipient,
        address indexed collection,
        uint256 claimedAmount
    );

    string public baseURI;
    

    address public factoryAddress;

    bool public activate;
    bool public aActivate;
    bool public bActivate;

    enum Solution {
        Empty,
        ASolution,
        BSolution
    }
    Solution public correctSolution;
    string public correctSolutionDesc;
    bool public correctSolutionStatus;

    uint256 public totalAmounts;
    uint256 public aSolutionAmounts;
    uint256 public bSolutionAmounts;

    uint256 public correctSolutionAmounts;
    uint256 public platformAmounts;
    uint256 public ownerAmounts;
    uint256 public winnerAllocationAmounts;

    mapping(Solution solution => uint256[] tokenIdArr) public buySolutionToken;
    mapping(uint256 tokenId => Solution solution) public buySolution;
    mapping(uint256 tokenId => uint256 amounts) public buyAmouns;

    mapping(uint256 tokenId => bool) public rewardsClaimed;
    mapping(uint256 tokenId => uint256 amounts) public winRewardsAmouns;

    address public constant PLATFORM =
        0xC565FC29F6df239Fe3848dB82656F2502286E97d;
    address public constant USDT_ADDRESS =
        0x05D032ac25d322df992303dCa074EE7392C117b9;
    address public constant COMMITTEE_ADDRESS =
        0x05D032ac25d322df992303dCa074EE7392C117b9;

   
}
