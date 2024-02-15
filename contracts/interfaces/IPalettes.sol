// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;


interface IPalettes {
    /// Color struct definition
    struct RGBColor {
        uint8 r;
        uint8 g;
        uint8 b;
    }

    struct PaletteRecord {
        address contractAddress;
        uint256 tokenId;
    }

    struct WebPalette {
        string[8] colors;
    }

    struct RGBPalette {
        RGBColor[8] colors;
    }



    /// @dev Returns the the seed for a specific token.
    function getSeed(uint256) external view returns (bytes32);

    /// @dev Returns the RBG color palette for a specific token.
    function rgbPalette(uint256) external view returns (RGBPalette memory);

    /// @dev Returns the hex color palette for a specific token.
    function webPalette(uint256) external view returns (WebPalette memory);

    /// @dev Returns the SVG image of the color palette for a specific token.
    function svg(uint256) external view returns(string memory);

}
