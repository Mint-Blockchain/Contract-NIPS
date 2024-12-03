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
import "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

contract FutureMarketContract is
    Initializable,
    ERC721Upgradeable,
    FutureMarketCommonStorage,
    ReentrancyGuardUpgradeable
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
        string calldata name_,
        string calldata symbol_,
        bytes calldata packedData,
        bytes calldata information
    ) external initializer {
        __ERC721_init(name_, symbol_);

        __ReentrancyGuard_init();

        initInfo(information);
        initPublicTime(packedData);
        factoryAddress = msg.sender;
    }

    function initInfo(bytes calldata information) internal {
        baseURI = abi.decode(information, (string));
    }
    function initPublicTime(bytes calldata packedData) internal {
        (uint32 _startTime, uint32 _endTimeTime, uint32 _allocationTime) = abi
            .decode(packedData, (uint32, uint32, uint32));
        require(_endTimeTime > _startTime, "Invalid time");
        require(_allocationTime > _endTimeTime, "Invalid time");
        investTimeConfig.startTime = _startTime;
        investTimeConfig.endTime = _endTimeTime;
        investTimeConfig.allocationTime = _allocationTime;
    }

    modifier checkPublicPhase() {
        require(
            block.timestamp >= investTimeConfig.startTime,
            "Time is not up, please wait"
        );
        require(block.timestamp >= investTimeConfig.startTime, "Haven't started yet");
        require(block.timestamp <= investTimeConfig.endTime, "Already over");
        _;
    }

    function owner() public view returns (address) {
        return
            ERC721Upgradeable(factoryAddress).ownerOf(
                uint256(uint160(address(this)))
            );
    }

    function buy(
        uint256 _amount,
        Solution _solution
    ) external nonReentrant checkPublicPhase {
        require(_amount > 0, "Invalid amount");
        require(_solution != Solution.Empty, "Invalid _solution");
        address sender = _msgSender();
        require(
            usdtToken.balanceOf(sender) >= _amount,
            "Insufficient USDT balance"
        );

        usdtToken.safeTransferFrom(sender, address(this), _amount);
        uint256 tokenId = ++_nextTokenId;
        _mint(sender, tokenId);

        totalAmounts += _amount;
        if (_solution == Solution.ASolution) {
            aSolutionAmounts += _amount;
            aActivate = true;
        } else {
            bSolutionAmounts += _amount;
            bActivate = true;
        }
        buySolutionToken[_solution].push(tokenId);
        buySolution[tokenId] = _solution;
        buyAmouns[tokenId] = _amount;
        activate = true;

        emit FutureMarket(sender, address(this), tokenId, _amount, _solution);
    }
    function getSolutionAmounts(
        Solution _solution
    ) external view returns (uint256 _numbers, uint256 _amounts) {
        require(_solution != Solution.Empty, "Invalid _solution");

        _numbers = buySolutionToken[_solution].length;
        if (_solution == Solution.ASolution) {
            _amounts = aSolutionAmounts;
        } else {
            _amounts = bSolutionAmounts;
        }
    }

    function setCorrectSolution(
        Solution _solution,
        string calldata _description
    ) external {
        require(_solution != Solution.Empty, "Invalid _solution");

        require(
            block.timestamp >= investTimeConfig.allocationTime,
            "Event not completed"
        );
        require(
            correctSolutionStatus == false,
            "Repetitive operation: The Solution have been announced"
        );

        address sender = _msgSender();
        require(sender == COMMITTEE_ADDRESS, "Invalid sender");

        correctSolution = _solution;
        correctSolutionDesc = _description;

        if (activate) {
            allocationRewards();

            if (platformAmounts > 0) {
                usdtToken.safeTransfer(PLATFORM, platformAmounts);
            }
            if (ownerAmounts > 0) {
                usdtToken.safeTransfer(owner(), ownerAmounts);
            }
        }

        correctSolutionStatus = true;
        emit CorrectSolution(_msgSender(), address(this), _solution);
    }

    function allocationRewards() internal {
        (
            uint256 _platformAmounts,
            uint256 _ownerAmounts,
            uint256 _winnerAllocationAmounts,
            uint256 _correctSolutionAmounts
        ) = calculateWinnerRewards(correctSolution);
        platformAmounts = _platformAmounts;
        ownerAmounts = _ownerAmounts;
        winnerAllocationAmounts = _winnerAllocationAmounts;
        correctSolutionAmounts = _correctSolutionAmounts;

        if (winnerAllocationAmounts > 0) {
            uint256[] memory tokenIdArr = buySolutionToken[correctSolution];

            for (uint i = 0; i < tokenIdArr.length; i++) {
                uint256 tokenId = tokenIdArr[i];
                winRewardsAmouns[tokenId] =
                    (buyAmouns[tokenId] / correctSolutionAmounts) *
                    winnerAllocationAmounts;
            }
        }
    }

    function forecastTokenIdCorrectRewards(
        uint256 _tokenId
    ) external view returns (uint256 _rewards) {
        _requireOwned(_tokenId);
        require(
            correctSolutionStatus == false,
            "The Solution have been announced"
        );

        Solution _solution = buySolution[_tokenId];

        (
            ,
            ,
            uint256 _winnerAllocationAmounts,
            uint256 _correctSolutionAmounts
        ) = calculateWinnerRewards(_solution);

        _rewards =
            (buyAmouns[_tokenId] / _correctSolutionAmounts) *
            _winnerAllocationAmounts;
    }

    function forecastNewInvestRewards(
        uint256 _amount,
        Solution _solution
    ) external view returns (uint256 _rewards) {
        require(
            correctSolutionStatus == false,
            "The Solution have been announced"
        );
        (
            ,
            ,
            uint256 _winnerAllocationAmounts,
            uint256 _correctSolutionAmounts
        ) = calculateWinnerRewards(_solution);

        _rewards =
            (_amount / _correctSolutionAmounts) *
            _winnerAllocationAmounts;
    }
    function calculateAllRewards(
        uint256[] calldata _tokenIdArr
    ) external view returns (uint256 _rewards) {
        require(
            correctSolutionStatus,
            "The Solution haven't been announced yet"
        );
        require(activate, "Invalid operation");

        address sender = _msgSender();

        for (uint i = 0; i < _tokenIdArr.length; i++) {
            uint256 tokenId = _tokenIdArr[i];
            address tokenOwner = _requireOwned(tokenId);
            require(tokenOwner == sender, "Invalid tokenId");

            if (buySolution[tokenId] == correctSolution) {
                _rewards += winRewardsAmouns[tokenId];
            }
        }
    }
    function calculateAlreadyClaimedRewards(
        uint256[] calldata _tokenIdArr
    ) external view returns (uint256 _rewards) {
        require(
            correctSolutionStatus,
            "The Solution haven't been announced yet"
        );
        require(activate, "Invalid operation");

        address sender = _msgSender();

        for (uint i = 0; i < _tokenIdArr.length; i++) {
            uint256 tokenId = _tokenIdArr[i];
            address tokenOwner = _requireOwned(tokenId);
            require(tokenOwner == sender, "Invalid tokenId");

            if (
                rewardsClaimed[tokenId] &&
                buySolution[tokenId] == correctSolution
            ) {
                _rewards += winRewardsAmouns[tokenId];
            }
        }
    }

    function claimRewards(
        uint256[] calldata _tokenIdArr
    ) external nonReentrant {
        require(
            correctSolutionStatus,
            "The Solution haven't been announced yet"
        );
        require(activate, "Invalid operation");

        address sender = _msgSender();

        uint256 _rewards;
        for (uint i = 0; i < _tokenIdArr.length; i++) {
            uint256 tokenId = _tokenIdArr[i];
            address tokenOwner = _requireOwned(tokenId);
            require(tokenOwner == sender, "Invalid tokenId");

            if (
                !rewardsClaimed[tokenId] &&
                buySolution[tokenId] == correctSolution
            ) {
                _rewards += winRewardsAmouns[tokenId];

                rewardsClaimed[tokenId] = true;
            }
        }
        usdtToken.safeTransfer(sender, _rewards);
        emit ClaimRewards(sender, address(this), _rewards);
    }

    function calculateWinnerRewards(
        Solution _correctSolution
    )
        internal
        view
        returns (
            uint256 _platformAmounts,
            uint256 _ownerAmounts,
            uint256 _winnerAllocationAmounts,
            uint256 _correctSolutionAmounts
        )
    {
        if (aActivate && bActivate) {
            if (_correctSolution == Solution.ASolution) {
                _platformAmounts = (bSolutionAmounts * 2) / 100;
                _ownerAmounts = (bSolutionAmounts * 3) / 100;
                _winnerAllocationAmounts =
                    aSolutionAmounts +
                    bSolutionAmounts -
                    _platformAmounts -
                    _ownerAmounts;

                _correctSolutionAmounts = aSolutionAmounts;
            } else if (_correctSolution == Solution.BSolution) {
                _platformAmounts = (aSolutionAmounts * 2) / 100;
                _ownerAmounts = (aSolutionAmounts * 3) / 100;
                _winnerAllocationAmounts =
                    bSolutionAmounts +
                    aSolutionAmounts -
                    _platformAmounts -
                    _ownerAmounts;

                _correctSolutionAmounts = bSolutionAmounts;
            }
        } else if (!aActivate) {
            if (_correctSolution == Solution.ASolution) {
                _platformAmounts = (totalAmounts * 50) / 100;
                _ownerAmounts = (totalAmounts * 50) / 100;
            } else if (_correctSolution == Solution.BSolution) {
                _winnerAllocationAmounts = totalAmounts;
                _correctSolutionAmounts = totalAmounts;
            }
        } else if (!bActivate) {
            if (_correctSolution == Solution.ASolution) {
                _winnerAllocationAmounts = totalAmounts;
                _correctSolutionAmounts = totalAmounts;
            } else if (_correctSolution == Solution.BSolution) {
                _platformAmounts = (totalAmounts * 50) / 100;
                _ownerAmounts = (totalAmounts * 50) / 100;
            }
        }
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
                            baseURI,
                            '"}'
                        )
                    )
                )
            );
    }
}
