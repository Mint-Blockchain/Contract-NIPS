// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "./FutureMarketCommonStorage.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/utils/Base64.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721EnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

contract FutureMarketContract is
    Initializable,
    ERC721EnumerableUpgradeable,
    FutureMarketCommonStorage
{
    using SafeERC20 for IERC20;
    IERC20 public usdtToken =
        IERC20(0x05D032ac25d322df992303dCa074EE7392C117b9);

    uint256 private _nextTokenId;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(
        string calldata _name,
        string calldata _symbol,
        address _creator,
        uint32 _startTime,
        uint32 _endTime,
        uint32 _allocationTime
    ) external initializer {
        __ERC721_init(_name, _symbol);

        startTime = _startTime;
        endTime = _endTime;
        allocationTime = _allocationTime;
        creator = _creator;
    }

    modifier checkPublicPhase() {
        require(block.timestamp >= startTime, "Haven't started yet");
        require(block.timestamp <= endTime, "Already over");
        _;
    }

    function buy(uint256 _amount, uint256 _solution) external checkPublicPhase {
        require(_amount > 0, "Invalid amount");
        require(
            _solution == A_SOLUTION || _solution == B_SOLUTION,
            "Invalid _solution"
        );
        address sender = _msgSender();
        require(
            usdtToken.balanceOf(sender) >= _amount,
            "Insufficient USDT balance"
        );

        usdtToken.safeTransferFrom(sender, address(this), _amount);
        uint256 tokenId = ++_nextTokenId;
        _mint(sender, tokenId);

        totalAmounts += _amount;
        solutionAmounts[_solution] += _amount;
        solutionNumber[_solution]++;
        tokenSolution[tokenId] = _solution;
        tokenAmouns[tokenId] = _amount;

        emit FutureMarket(sender, address(this), tokenId, _amount, _solution);
    }

    function setCorrectSolution(
        uint256 _solution,
        string calldata _description
    ) external {
        require(
            _solution == A_SOLUTION || _solution == B_SOLUTION,
            "Invalid _solution"
        );

        require(block.timestamp >= allocationTime, "Event not completed");
        require(
            correctSolutionStatus == false,
            "Repetitive operation: The Solution have been announced"
        );

        address sender = _msgSender();
        require(sender == COMMITTEE_ADDRESS, "Invalid sender");

        correctSolution = _solution;
        correctSolutionDesc = _description;

        if (totalAmounts > 0) {
            (
                uint256 _platformAmounts,
                uint256 _ownerAmounts,
                uint256 _winnerAllocationAmounts
            ) = calculateRewards(correctSolution);

            platformAmounts = _platformAmounts;
            ownerAmounts = _ownerAmounts;
            winnerAllocationAmounts = _winnerAllocationAmounts;

            if (platformAmounts > 0) {
                usdtToken.safeTransfer(PLATFORM_ADDRESS, platformAmounts);
            }
            if (ownerAmounts > 0) {
                usdtToken.safeTransfer(creator, ownerAmounts);
            }
        }

        correctSolutionStatus = true;
        emit CorrectSolution(sender, _solution);
    }

    function forecastTokenIdCorrectRewards(
        uint256 _tokenId
    ) external view returns (uint256 _rewards) {
        _requireOwned(_tokenId);

        require(
            correctSolutionStatus == false,
            "The Solution have been announced"
        );

        uint256 _solution = tokenSolution[_tokenId];

        (, , uint256 _winnerAllocationAmounts) = calculateRewards(_solution);

        _rewards =
            (tokenAmouns[_tokenId] / solutionAmounts[_solution]) *
            _winnerAllocationAmounts;
    }

    function forecastNewInvestRewards(
        uint256 _amount,
        uint256 _solution
    ) external view returns (uint256 _rewards) {
        require(
            correctSolutionStatus == false,
            "The Solution have been announced"
        );
        (, , uint256 _winnerAllocationAmounts) = calculateRewards(_solution);

        _rewards =
            (_amount / solutionAmounts[_solution]) *
            _winnerAllocationAmounts;
    }
    function calculateAllRewards() external view returns (uint256 _rewards) {
        require(
            correctSolutionStatus,
            "The Solution haven't been announced yet"
        );
        address sender = _msgSender();
        uint256 holdNumber = balanceOf(sender);
        require(holdNumber > 0, "No token held");

        uint256 allCorrectAmounts;
        for (uint i = 0; i < holdNumber; i++) {
            uint256 _tokenId = tokenOfOwnerByIndex(sender, i);

            if (tokenSolution[_tokenId] == correctSolution) {
                allCorrectAmounts += tokenAmouns[_tokenId];
            }
        }
        _rewards =
            (allCorrectAmounts / solutionAmounts[correctSolution]) *
            winnerAllocationAmounts;
    }
    function calculateCanClaimedRewards()
        public
        view
        returns (uint256 _rewards)
    {
        require(
            correctSolutionStatus,
            "The Solution haven't been announced yet"
        );
        address sender = _msgSender();
        uint256 holdNumber = balanceOf(sender);
        require(holdNumber > 0, "No token held");

        uint256 allCanAmounts;
        for (uint i = 0; i < holdNumber; i++) {
            uint256 _tokenId = tokenOfOwnerByIndex(sender, i);

            if (
                !rewardsClaimed[_tokenId] &&
                tokenSolution[_tokenId] == correctSolution
            ) {
                allCanAmounts += tokenAmouns[_tokenId];
            }
        }
        _rewards =
            (allCanAmounts / solutionAmounts[correctSolution]) *
            winnerAllocationAmounts;
    }

    function claimRewards() external {
        address sender = _msgSender();
        uint256 _rewards = calculateCanClaimedRewards();

        usdtToken.safeTransfer(sender, _rewards);
        emit ClaimRewards(sender, _rewards);
    }

    function calculateRewards(
        uint256 _solution
    )
        internal
        view
        returns (
            uint256 _platformAmounts,
            uint256 _ownerAmounts,
            uint256 _winnerAllocationAmounts
        )
    {
        require(
            _solution == A_SOLUTION || _solution == B_SOLUTION,
            "Invalid _solution"
        );
        uint256 _errSolutionAmounts = totalAmounts - solutionAmounts[_solution];
        _platformAmounts = (_errSolutionAmounts * 2) / 100;
        _ownerAmounts = (_errSolutionAmounts * 3) / 100;
        _winnerAllocationAmounts =
            totalAmounts -
            _platformAmounts -
            _ownerAmounts;
    }

    function tokenURI(
        uint256 _tokenId
    ) public view override returns (string memory) {
        _requireOwned(_tokenId);

        return
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    Base64.encode(
                        abi.encodePacked(
                            '{"name":"',
                            name(),
                            " #",
                            Strings.toString(_tokenId),
                            '","image":"',
                            BASE_URI,
                             '","solution":"',
                            Strings.toString(tokenSolution[_tokenId]),
                              '","USDT":"',
                            Strings.toString(tokenAmouns[_tokenId]),
                            '"}'
                        )
                    )
                )
            );
    }
}
