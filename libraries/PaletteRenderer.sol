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

    // Add new helper for luminance calculation (scaled to avoid floats)
    function getLuminanceScaled(
        uint8 r,
        uint8 g,
        uint8 b
    ) internal pure returns (uint256) {
        // NTSC Luminance formula: (0.299*R + 0.587*G + 0.114*B) scaled by 1000 for integers
        return (uint256(r) * 299 + uint256(g) * 587 + uint256(b) * 114) / 1000;
    }

    // Add a helper for a more "perceptual" complementary color
    function getPerceptualComplement(
        uint8 r,
        uint8 g,
        uint8 b
    ) internal pure returns (uint24) {
        // This is a simplified approach, often used in graphics shaders:
        // It's not a full HSL complement, but aims for better visual contrast than 255-X.
        // Basically, it means subtracting the color from a "neutral" white point.
        // For a more accurate RGB complement that is still cheaper than HSL,
        // you might shift the hue by 180 degrees using a simplified matrix approach if colors are primary/secondary.
        // For now, let's keep it simple: inverted + slight saturation adjustment or just inverted.

        // Using a "simplified" complementary calculation that's more effective than just 255-x.
        // Example: For a color (r,g,b), its complement can be thought of as (255-r, 255-g, 255-b) but then
        // re-normalized or slightly adjusted. A simple method is to find the min/max and use that.
        // Or, for a primary, the complement is the mix of the other two.
        // This can get complex quickly.
        // Let's stick with the simplest and most performant perceptual:
        // This is basically finding the "negative" of the light
        // uint8 nr = 255 - r;
        // uint8 ng = 255 - g;
        // uint8 nb = 255 - b;
        // return Colors.packRGB(nr, ng, nb);

        // For a slightly "better" complement, we can derive hue like in HSL but only do rotation.
        // This goes back to being close to HSL costs.

        // Stick to your 255-r for now, it's the cheapest.
        // If you want "better," the HSL module you shared IS the "better" and more expensive way.

        // Let's offer a different kind of "related" color instead of aiming for "complement" directly
        // that stays simple RGB math. How about a color with shifted primary dominance?
        // E.g., if RED is dominant, decrease it and increase others.
        // uint256 maxC = Utils.max(r, g, b);
        // uint256 minC = Utils.min(r, g, b);
        // uint256 sum = uint256(r) + uint256(g) + uint256(b);

        // This is a simple RGB-based shift that "rotates" the primary
        // Effectively moving a primary color to a secondary, or vice-versa
        // e.g., (R,G,B) -> (G,B,R) -> (B,R,G) as distinct colors.
        // Or, a "rotated inverse"
        uint8 newR = 255 - b;
        uint8 newG = 255 - r;
        uint8 newB = 255 - g;
        return Colors.packRGB(newR, newG, newB);
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

    // Ensure getPerceptualComplement function is also available and simplified if possible.
    // Or, keep it as is, it's just one call within getBasePalette then.

    // --- Original getBasePalette function (now simplified) ---

    function getBasePalette(bytes32 _seed) internal pure returns (uint192) {
        uint8 r;
        uint8 g;
        uint8 b;

        // Unpack base color
        (r, g, b) = Colors.unpackRGB(getBaseColor(_seed).value);

        // Calculate luminance (only need `luminance255` for `_deriveDesaturated`)
        uint256 baseLuminance = getLuminanceScaled(r, g, b);
        uint256 luminance255 = (baseLuminance * 255) / 1000;

        // 🛑 Final Fix: Populate the array by calling the new helper functions
        uint24[8] memory colorsArray;

        colorsArray[0] = _deriveOriginalColor(_seed);
        colorsArray[1] = _deriveLighterShade(r, g, b);
        colorsArray[2] = _deriveDarkerShade(r, g, b);
        colorsArray[3] = getPerceptualComplement(r, g, b); // Assuming this is defined externally or within this library
        colorsArray[4] = _deriveChannelSwapped(r, g, b);
        colorsArray[5] = _deriveInverted(r, g, b);
        colorsArray[6] = _deriveDesaturated(r, g, b, luminance255);
        colorsArray[7] = _deriveDarkerShade(r, g, b); // Re-using for the 8th slot example

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
