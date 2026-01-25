// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Utils} from "./libraries/Utils.sol";
import {Colors} from "./libraries/Colors.sol";
import {IPalettes} from "./interfaces/IPalettes.sol";

/**
 * @title PaletteRenderer
 * @dev Library for generating and rendering color palettes based on a seed value.
 * Contains functions for generating colors, palettes, and SVG representations of palettes.
 * Author: Abstrucked.eth
 */
contract PaletteRenderer {
    uint256 private constant SIZE = 1024;

    constructor() {}

    /**
     * @notice Generates a uint256 color value from a given seed.
     * @param seed bytes32 The seed value for generating the color.
     * @return uint256 The generated uint256 color value.
     */
    function generateUintColor(bytes32 seed) private pure returns (uint256) {
        return uint256(keccak256(abi.encodePacked(seed))) % 16777216;
    }

    /**
     * @notice Extracts the red component from a uint256 color value.
     * @param value uint256 The uint256 color value.
     * @return uint8 The red component as a uint8.
     */
    function getRed(uint256 value) internal pure returns (uint8) {
        return uint8((value >> 16) & 0xff);
    }

    /**
     * @notice Extracts the green component from a uint256 color value.
     * @param value uint256 The uint256 color value.
     * @return uint8 The green component as a uint8.
     */
    function getGreen(uint256 value) internal pure returns (uint8) {
        return uint8((value >> 8) & 0xff);
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

    // Add new helper for luminance calculation (scaled to avoid floats)
    function getLuminanceScaled(
        uint8 r,
        uint8 g,
        uint8 b
    ) internal pure returns (uint256) {
        // NTSC Luminance formula: (0.299*R + 0.587*G + 0.114*B) scaled by 1000 for integers
        return (uint256(r) * 299 + uint256(g) * 587 + uint256(b) * 114) / 1000;
    }

    function _deriveOriginalColor(
        bytes32 _seed
    ) internal pure returns (uint24) {
        return getBaseColor(_seed).value;
    }

    function _deriveLighterShade(
        uint8 r,
        uint8 g,
        uint8 b
    ) internal pure returns (uint24) {
        uint8 r_light1 = uint8((uint256(r) * 80 + 255 * 20) / 100);
        uint8 g_light1 = uint8((uint256(g) * 80 + 255 * 20) / 100);
        uint8 b_light1 = uint8((uint256(b) * 80 + 255 * 20) / 100);
        return Colors.packRGB(r_light1, g_light1, b_light1);
    }

    function _deriveDarkerShade(
        uint8 r,
        uint8 g,
        uint8 b
    ) internal pure returns (uint24) {
        uint8 r_dark1 = uint8((uint256(r) * 80) / 100);
        uint8 g_dark1 = uint8((uint256(g) * 80) / 100);
        uint8 b_dark1 = uint8((uint256(b) * 80) / 100);
        return Colors.packRGB(r_dark1, g_dark1, b_dark1);
    }

    function _deriveChannelSwapped(
        uint8 r,
        uint8 g,
        uint8 b
    ) internal pure returns (uint24) {
        return Colors.packRGB(b, r, g);
    }

    function _deriveGrayscale(
        uint8 r,
        uint8 g,
        uint8 b
    ) internal pure returns (uint24) {
        uint256 luminance = getLuminanceScaled(r, g, b); // Get scaled luminance
        uint8 grayValue = uint8((luminance * 255) / 1000); // Scale luminance to 0-255

        return Colors.packRGB(grayValue, grayValue, grayValue);
    }

    function _deriveInverted(
        uint8 r,
        uint8 g,
        uint8 b
    ) internal pure returns (uint24) {
        uint8 cr = 255 - r;
        uint8 cg = 255 - g;
        uint8 cb = 255 - b;
        return Colors.packRGB(cr, cg, cb);
    }

    function _deriveDesaturated(
        uint8 r,
        uint8 g,
        uint8 b,
        uint256 luminance255
    ) internal pure returns (uint24) {
        uint8 r_desat = uint8((uint256(r) + luminance255) / 2);
        uint8 g_desat = uint8((uint256(g) + luminance255) / 2);
        uint8 b_desat = uint8((uint256(b) + luminance255) / 2);
        return Colors.packRGB(r_desat, g_desat, b_desat);
    }

    // In PaletteRenderer.sol, add this function somewhere with your other _derive helpers
    function _deriveAnotherChannelSwappedInverted(
        uint8 r,
        uint8 g,
        uint8 b
    ) internal pure returns (uint24) {
        // This is (255-G, 255-B, 255-R) or another permutation like (255-R, 255-B, 255-G)
        // Let's use (255-G, 255-B, 255-R) for demonstration
        uint8 invR = 255 - r;
        uint8 invG = 255 - g;
        uint8 invB = 255 - b;
        return Colors.packRGB(invG, invB, invR);
    }

    function getBasePalette(bytes32 _seed) internal pure returns (uint192) {
        uint8 r;
        uint8 g;
        uint8 b;

        // Unpack base color
        (r, g, b) = Colors.unpackRGB(getBaseColor(_seed).value);

        // Calculate luminance (only need `luminance255` for `_deriveDesaturated`)
        uint256 baseLuminance = getLuminanceScaled(r, g, b);
        uint256 luminance255 = (baseLuminance * 255) / 1000;

        uint24[8] memory colorsArray;

        colorsArray[0] = _deriveOriginalColor(_seed);
        colorsArray[1] = _deriveLighterShade(r, g, b);
        colorsArray[2] = _deriveDarkerShade(r, g, b);
        colorsArray[4] = Colors.getPerceptualComplement(r, g, b); // Assuming this is defined externally or within this library
        colorsArray[5] = _deriveChannelSwapped(r, g, b);
        colorsArray[7] = _deriveGrayscale(r, g, b);
        colorsArray[3] = _deriveDesaturated(r, g, b, luminance255);
        colorsArray[6] = _deriveAnotherChannelSwappedInverted(r, g, b); // Re-using for the 8th slot example

        return Colors.packPalette(colorsArray);
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
    ) external pure returns (uint24[8] memory) {
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
    function webPalette(bytes32 seed) external pure returns (string[8] memory) {
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

        uint256 padding = 50;
        uint256 innerHeight = SIZE - (2 * padding); // Assuming square overall drawing area

        // For a single horizontal row of 8 circles/rectangles:
        // The height of each palette "bar" or the diameter of each circle.
        // Let's assume the circles/rectangles fill the *padded* height, and are laid out horizontally.
        uint256 elementSize = innerHeight / 8; // If you want them stacked vertically
        // Or, if single horizontal row, this is the height/diameter of each element.

        string memory renderSvg;

        unchecked {
            for (uint8 i = 0; i < 8; i++) {
                // Calculate center Y for vertical centering within the padded area
                // (Padding + half of innerHeight for perfect vertical centering of a single strip)
                uint256 centerY = padding + (innerHeight / 2);

                // Calculate center X for horizontal distribution within the padded area
                // (Padding + start of first element + (element index * element width) + half element width)
                uint256 centerX = padding +
                    (i * elementSize) +
                    (elementSize / 2);
                uint256 radius = (elementSize / 2) - 1; // Radius, with a small inner margin

                renderSvg = string.concat(
                    renderSvg,
                    '<circle cy="',
                    Utils.uint2str(centerY),
                    '" cx="',
                    Utils.uint2str(centerX),
                    '" r="',
                    Utils.uint2str(radius),
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
    function drawPalette(bytes32 _seed) external pure returns (string memory) {
        return
            string.concat(
                '<svg width="',
                Utils.uint2str(SIZE),
                '" height="',
                Utils.uint2str(SIZE),
                '" viewBox="0 0 ',
                Utils.uint2str(SIZE),
                " ",
                Utils.uint2str(SIZE),
                '" xmlns="http://www.w3.org/2000/svg">',
                '<rect x="0" y="0" width="',
                Utils.uint2str(SIZE),
                '" height="',
                Utils.uint2str(SIZE),
                '" fill="#FFFFFF"></rect>',
                _svgColors(_seed),
                "</svg>"
            );
    }
}
