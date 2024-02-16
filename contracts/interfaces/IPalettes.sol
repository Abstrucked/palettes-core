// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;


interface IPalettes {
    // Events
//    event PaletteRecordSet(uint256 indexed paletteId, address indexed contractAddress, uint256 indexed tokenId);

    /// Color struct definition
    struct RGBColor {
        uint24 value;
    }

    struct PaletteRecord {
        address contractAddress;
        uint256 tokenId;
    }

//    struct WebPalette {
//        string[8] colors;
//    }

//    struct RGBPalette {
//        uint192 colors;
//    }



    /// @dev Returns the the seed for a specific token.
    function getSeed(uint256) external view returns (bytes32);

    /// @dev Returns the RBG color palette for a specific token.
//    function rgbPalette(uint256) external view returns (RGBPalette memory);

    /// @dev Returns the hex color palette for a specific token.
    function webPalette(uint256) external view returns (string[8] memory);

    /// @dev Returns the SVG image of the color palette for a specific token.
    function svg(uint256) external view returns(string memory);

}
