// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Utils} from "../libraries/Utils.sol";
import {Colors} from "../libraries/Colors.sol";
import {IPalettes} from "../contracts/interfaces/IPalettes.sol";

/**
 * @title PaletteRenderer
 * @dev Library for generating and rendering color palettes based on a seed value.
 * Contains functions for generating colors, palettes, and SVG representations of palettes.
 * Author: Abstrucked.eth
 */
library PaletteRenderer {
    uint256 private constant SIZE = 1024;

    /**
     * @notice Generates a uint256 color value from a given seed.
     * @param seed bytes32 The seed value for generating the color.
     * @return uint256 The generated uint256 color value.
     */
    function generateUintColor(bytes32 seed) private pure returns (uint256) {
        return uint256(keccak256(abi.encodePacked(seed))) % 524288;
    }

    /**
     * @notice Extracts the red component from a uint256 color value.
     * @param value uint256 The uint256 color value.
     * @return uint8 The red component as a uint8.
     */
    function getRed(uint256 value) internal pure returns (uint8) {
        return uint8((value >> 8) & 0xff);
    }

    /**
     * @notice Extracts the green component from a uint256 color value.
     * @param value uint256 The uint256 color value.
     * @return uint8 The green component as a uint8.
     */
    function getGreen(uint256 value) internal pure returns (uint8) {
        return uint8((value >> 4) & 0xff);
    }

    /**
     * @notice Extracts the blue component from a uint256 color value.
     * @param value uint256 The uint256 color value.
     * @return uint8 The blue component as a uint8.
     */
    function getBlue(uint256 value) internal pure returns (uint8) {
        return uint8(value & 0xff);
    }

    /**
     * @notice Generates the base color using a seed value.
     * @param seed bytes32 The seed value for generating the base color.
     * @return IPalettes.RGBColor The generated RGBColor structure.
     */
    function getBaseColor(
        bytes32 seed
    ) internal pure returns (IPalettes.RGBColor memory) {
        uint256 col = generateUintColor(bytes32(seed));
        return
            IPalettes.RGBColor(
                Colors.packRGB(getRed(col), getGreen(col), getBlue(col))
            );
    }

    /**
     * @notice Generates a base color palette using a seed value.
     * @param _seed bytes32 The seed value for generating the base palette.
     * @return uint192 The packed RGB values as a uint192.
     */
    function getBasePalette(bytes32 _seed) internal pure returns (uint192) {
        // Unpacked color placeholders
        uint8 r;
        uint8 g;
        uint8 b;

        // Get unpacked base color.
        (r, g, b) = Colors.unpackRGB(getBaseColor(_seed).value);
        uint8 cr = 255 - r;
        uint8 cg = 255 - g;
        uint8 cb = 255 - b;

        return
            Colors.packPalette(
                [
                    getBaseColor(_seed).value,
                    Colors.packRGB(b, r, g),
                    Colors.packRGB(g, b, r),
                    Colors.packRGB(cr, cg, cb),
                    Colors.packRGB(cb, cr, cg),
                    Colors.packRGB(cg, cb, cr),
                    Colors.packRGB((r / 5), (g / 5), (b / 5)),
                    Colors.packRGB(
                        (255 - (cr / 3)),
                        (255 - (cg / 3)),
                        (255 - (cb / 3))
                    )
                ]
            );
    }

    /**
     * @notice Converts an RGB color value to its hexadecimal string representation.
     * @param rgb uint24 The RGB color value.
     * @return string The hexadecimal string representation of the RGB color.
     */
    function getHex(uint24 rgb) internal pure returns (string memory) {
        bytes memory hexChars = "0123456789ABCDEF";
        bytes memory hexString = new bytes(7);
        hexString[0] = "#";
        unchecked {
            for (uint i = 0; i < 3; i++) {
                hexString[2 * i + 1] = hexChars[
                    uint8(rgb >> (i * 8 + 4)) & 0x0f
                ];
                hexString[2 * i + 2] = hexChars[uint8(rgb >> (i * 8)) & 0x0f];
            }
        }

        return string(hexString);
    }

    /**
     * @notice Returns the RGB color palette for a specific token.
     * @param _seed bytes32 The `tokenId` for this token.
     * @return uint24[8] The RGB color palette for a specific token.
     */
    function rgbPalette(
        bytes32 _seed
    ) internal pure returns (uint24[8] memory) {
        uint192 palette = getBasePalette(_seed);
        return [
            uint24(palette >> 168),
            uint24(palette >> 144),
            uint24(palette >> 120),
            uint24(palette >> 96),
            uint24(palette >> 72),
            uint24(palette >> 48),
            uint24(palette >> 24),
            uint24(palette)
        ];
    }

    /**
     * @notice Generates a web-safe palette based on a seed value.
     * @param seed bytes32 The seed value for generating the palette.
     * @return string[8] An array of 8 hexadecimal color codes.
     */
    function webPalette(bytes32 seed) internal pure returns (string[8] memory) {
        uint192 _rgbPalette = getBasePalette(seed);
        return [
            getHex(Colors.unpackPaletteAt(_rgbPalette, 0)),
            getHex(Colors.unpackPaletteAt(_rgbPalette, 1)),
            getHex(Colors.unpackPaletteAt(_rgbPalette, 2)),
            getHex(Colors.unpackPaletteAt(_rgbPalette, 3)),
            getHex(Colors.unpackPaletteAt(_rgbPalette, 4)),
            getHex(Colors.unpackPaletteAt(_rgbPalette, 5)),
            getHex(Colors.unpackPaletteAt(_rgbPalette, 6)),
            getHex(Colors.unpackPaletteAt(_rgbPalette, 7))
        ];
    }

    /**
     * @notice Generates an SVG string representation of the palette colors.
     * @param seed bytes32 The seed value for generating the palette colors.
     * @return string The SVG string representation of the palette colors.
     */
    function _svgColors(bytes32 seed) private pure returns (string memory) {
        uint192 palette = getBasePalette(seed);
        uint256 HEIGHT = SIZE / 8;
        string memory renderSvg;
        unchecked {
            for (uint8 i = 0; i < 8; i++) {
                renderSvg = string.concat(
                    renderSvg,
                    '<circle cy="',
                    Utils.uint2str(HEIGHT),
                    '" cx="',
                    Utils.uint2str((i * HEIGHT) + (HEIGHT / 2)),
                    '" r="',
                    Utils.uint2str((HEIGHT / 2) - 1),
                    '" fill="',
                    getHex(Colors.unpackPaletteAt(palette, i)),
                    '"></circle>'
                );
            }
        }
        return renderSvg;
    }

    /**
     * @notice Generates the full SVG representation of the palette.
     * @param _seed bytes32 The seed value for generating the palette.
     * @return string The complete SVG string.
     */
    function drawPalette(bytes32 _seed) internal pure returns (string memory) {
        return
            string.concat(
                '<svg width="',
                Utils.uint2str(SIZE),
                '" height="',
                Utils.uint2str(SIZE / 4),
                '" viewBox="0 0 ',
                Utils.uint2str(SIZE),
                " ",
                Utils.uint2str(SIZE / 4),
                '" xmlns="http://www.w3.org/2000/svg">',
                _svgColors(_seed),
                "</svg>"
            );
    }
}
