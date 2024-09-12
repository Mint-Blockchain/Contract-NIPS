//SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "./../lib/erc5007/IERC5007.sol";

contract ERC5007Example is Initializable, ERC721Upgradeable, OwnableUpgradeable, IERC5007 {
    
    struct TimeNftInfo {
        uint64 startTime;
        uint64 endTime;
        bool exist;
    }

    mapping(uint256 => TimeNftInfo) internal _timeNftMapping;


    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(address initialOwner, string memory name, string memory symbol, bytes calldata extendData) initializer public {
        __ERC721_init(name, symbol);
        __Ownable_init(initialOwner);
        _initInfo(extendData);
    }

    /**
     * @dev See {IERC5007-startTime}.
     */
    function startTime(uint256 tokenId)
        public
        view
        virtual
        override
        returns (uint64) {
        require(_timeNftMapping[tokenId].exist, "ERC5007: invalid tokenId");
        return _timeNftMapping[tokenId].startTime;
    }

    /**
     * @dev See {IERC5007-endTime}.
     */
    function endTime(uint256 tokenId)
        public
        view
        virtual
        override
        returns (uint64) {
        require(_timeNftMapping[tokenId].exist, "ERC5007: invalid tokenId");
        return _timeNftMapping[tokenId].endTime;
    }

    /**
     * @dev mint a new time NFT.
     *
     * Requirements:
     *
     * - `tokenId_` must not exist.
     * - `to_` cannot be the zero address.
     * - `endTime_` should be equal or greater than `startTime_`
     */
    function mintTimeNft(
        address to_,
        uint256 tokenId_,
        uint64 startTime_,
        uint64 endTime_
    ) internal virtual {
        require(endTime_ >= startTime_, 'ERC5007: invalid endTime');
        _safeMint(to_, tokenId_);
        TimeNftInfo storage info = _timeNftMapping[tokenId_];
        info.startTime = startTime_;
        info.endTime = endTime_;
    }

    function _initInfo(bytes calldata extendData) internal {
        
    }
}