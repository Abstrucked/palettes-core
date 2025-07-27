// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IStorage {
    event PaletteRecordSet(
        uint256 indexed paletteId,
        address indexed contractAddress,
        uint256 indexed tokenId
    );
    struct PaletteRecord {
        address contractAddress;
        uint256 tokenId;
    }

    //    function getPaletteRecord(uint256 tokenId, address _contractAddress) external view returns (uint256);
    function getPaletteId(
        uint256 tokenId,
        address _contractAddress
    ) external view returns (uint256);

    function setPaletteRecord(
        uint256 paletteId,
        address _contractAddress,
        uint256 _tokenId
    ) external;
}
