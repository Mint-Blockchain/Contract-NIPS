//SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @dev the ERC-165 identifier for this interface is 0xf140be0d.
 */
interface IERC5007 /* is IERC721 */ {
    /**
     * @dev Returns the start time of the NFT as a UNIX timestamp.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function startTime(uint256 tokenId) external view returns (uint64);
    
    /**
     * @dev Returns the end time of the NFT as a UNIX timestamp.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function endTime(uint256 tokenId) external view returns (uint64);

}