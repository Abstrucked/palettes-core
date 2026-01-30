// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface IManager {
    function setPaletteRecord(
        uint256 paletteId,
        address _contractAddress,
        uint256 _tokenId,
        uint256 nonce,
        uint256 deadline,
        bytes calldata signature
    ) external;

    function getNonce(address account) external view returns (uint256);

    function getPalette(
        uint256 tokenId
    ) external view returns (string[8] memory);

    function getRGBPalette(
        uint256 tokenId
    ) external view returns (uint24[8] memory);

    function getPaletteId(
        uint256 tokenId,
        address _contractAddress
    ) external view returns (uint256);

    function isPaletteOwner(
        uint256 paletteId,
        address signer
    ) external view returns (bool);
}

