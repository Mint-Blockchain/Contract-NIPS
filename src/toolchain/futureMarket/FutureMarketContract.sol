// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "./FutureMarketCommonStorage.sol";
import "@openzeppelin/contracts/utils/Base64.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721EnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

contract FutureMarketContract is
    Initializable,
    ERC721EnumerableUpgradeable,
    OwnableUpgradeable,
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
        address _creator,
        uint32 _startTime,
        uint32 _endTime,
        uint32 _allocationTime
    ) external initializer {
        __ERC721_init(_name, "FM");
        __Ownable_init(_creator);

        startTime = _startTime;
        endTime = _endTime;
        allocationTime = _allocationTime;
    }

    function bet(uint256 _amount, uint256 _solution) external {
        require(block.timestamp >= startTime, "Haven't started yet");
        require(block.timestamp <= endTime, "Already over");

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
        uint256 tokenId = _nextTokenId++;
        _mint(sender, tokenId);

        totalAmounts += _amount;
        solutionAmounts[_solution] += _amount;
        solutionNumber[_solution]++;
        tokenSolution[tokenId] = _solution;
        tokenAmounts[tokenId] = _amount;

        emit Bet(sender, address(this), tokenId, _amount, _solution);
    }

    function allocateSolution(
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
                uint256 _winnerAmounts
            ) = calculateRewards(correctSolution);

            platformAmounts = _platformAmounts;
            ownerAmounts = _ownerAmounts;
            winnerAmounts = _winnerAmounts;

            if (platformAmounts > 0) {
                usdtToken.safeTransfer(PLATFORM_ADDRESS, platformAmounts);
            }
            if (ownerAmounts > 0) {
                usdtToken.safeTransfer(owner(), ownerAmounts);
            }
        }

        correctSolutionStatus = true;
        emit AllocateSolution(sender, _solution);
    }

    function forecastTokenIdRewards(
        uint256 _tokenId
    ) external view returns (uint256 _rewards) {
        _requireOwned(_tokenId);

        require(
            correctSolutionStatus == false,
            "The Solution have been announced"
        );

        uint256 _solution = tokenSolution[_tokenId];

        (, , uint256 _winnerAmounts) = calculateRewards(_solution);

        _rewards =
            (tokenAmounts[_tokenId] * _winnerAmounts) /
            solutionAmounts[_solution];
    }

    function forecastNewInvestRewards(
        uint256 _amount,
        uint256 _solution
    ) external view returns (uint256 _rewards) {
        require(
            correctSolutionStatus == false,
            "The Solution have been announced"
        );
        (, , uint256 _winnerAmounts) = calculateRewards(_solution);
        uint256 _newSolutionAmounts = solutionAmounts[_solution] + _amount;
        _winnerAmounts += _amount;

        _rewards = (_amount / _newSolutionAmounts) * _winnerAmounts;
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
                allCorrectAmounts += tokenAmounts[_tokenId];
            }
        }
        _rewards =
            (allCorrectAmounts * winnerAmounts) /
            solutionAmounts[correctSolution];
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
                allCanAmounts += tokenAmounts[_tokenId];
            }
        }
        _rewards =
            (allCanAmounts * winnerAmounts) /
            solutionAmounts[correctSolution];
    }

    function claimRewards() external {
        address sender = _msgSender();
        uint256 _rewards = calculateCanClaimedRewards();

        usdtToken.safeTransfer(sender, _rewards);

        winnerClaimedAmounts[sender] += _rewards;
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
            uint256 _winnerAmounts
        )
    {
        require(
            _solution == A_SOLUTION || _solution == B_SOLUTION,
            "Invalid _solution"
        );
        uint256 _loseSolutionAmounts = totalAmounts - solutionAmounts[_solution];
        _platformAmounts = (_loseSolutionAmounts * 2) / 100;
        _ownerAmounts = (_loseSolutionAmounts * 3) / 100;
        _winnerAmounts =
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
                            Strings.toString(tokenAmounts[_tokenId]),
                            '"}'
                        )
                    )
                )
            );
    }
}
