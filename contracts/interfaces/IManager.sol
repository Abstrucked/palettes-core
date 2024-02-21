// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface IManager {
    function setPaletteRecord(uint256 paletteId, address _contractAddress, uint256 _tokenId, bytes calldata signature) external;
    function getPalette(uint256 tokenId) external view returns (string[8] memory);
    function getPaletteId(uint256 tokenId, address _contractAddress) external view returns (uint256);
    function isPaletteOwner(uint256 paletteId, address signer) external view returns (bool);
}