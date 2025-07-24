// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

interface IUsePalette {
    event PaletteSet(uint256 indexed tokenId, uint256 indexed paletteId);

    function setPalette(
        uint256 tokenId,
        uint256 paletteId,
        bytes calldata signature
    ) external;

    function getPalette(
        uint256 tokenId
    ) external view returns (string[8] memory);

    // function getRGBPalette(
    //     uint256 tokenId
    // ) external view returns (uint24[8] memory);

    function isPaletteSet(uint256 tokenId) external view returns (bool);

    function getSetPaletteId(uint256 tokenId) external view returns (uint256);
}
