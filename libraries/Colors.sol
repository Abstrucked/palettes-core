// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;
import {Utils} from "./Utils.sol";

/**
 * @title Colors
 * @dev Library for handling and manipulating RGB colors and palettes.
 */
library Colors {
    /**
     * @notice Packs RGB values into a single uint24 value.
     * @param r uint8 The red component.
     * @param g uint8 The green component.
     * @param b uint8 The blue component.
     * @return uint24 The packed RGB value.
     */
    function packRGB(uint8 r, uint8 g, uint8 b) internal pure returns (uint24) {
        return (uint24(r) << 16) | (uint24(g) << 8) | uint24(b);
    }

    /**
     * @notice Unpacks a uint24 value into RGB components.
     * @param color uint24 The packed RGB value.
     * @return r uint8 The red component.
     * @return g uint8 The green component.
     * @return b uint8 The blue component.
     */
    function unpackRGB(
        uint24 color
    ) internal pure returns (uint8 r, uint8 g, uint8 b) {
        r = uint8(color >> 16);
        g = uint8(color >> 8);
        b = uint8(color);
        return (r, g, b);
    }

    /**
     * @notice Packs an array of 8 uint24 RGB values into a single uint192 value.
     * @param values uint24[8] An array of 8 RGB values.
     * @return packed uint192 The packed palette.
     */
    function packPalette(
        uint24[8] memory values
    ) internal pure returns (uint192 packed) {
        for (uint8 i = 0; i < 8; i++) {
            packed |= uint192(values[i]) << (24 * i);
        }

        return packed;
    }

    /**
     * @notice Unpacks a uint192 value into an array of 8 uint24 RGB values.
     * @param packed uint192 The packed palette.
     * @return values uint24[8] An array of 8 unpacked RGB values.
     */
    function unpackPalette(
        uint192 packed
    ) internal pure returns (uint24[8] memory values) {
        for (uint8 i = 0; i < 8; i++) {
            values[i] = uint24(packed >> (24 * i));
        }

        return values;
    }

    /**
     * @notice Unpacks a single uint24 RGB value from a packed uint192 palette at a specified index.
     * @param packed uint192 The packed palette.
     * @param index uint8 The index of the RGB value in the palette.
     * @return uint24 The unpacked RGB value at the specified index.
     */
    function unpackPaletteAt(
        uint192 packed,
        uint8 index
    ) internal pure returns (uint24) {
        return uint24(packed >> (24 * index));
    }

    /**
     * @notice Calculates a perceptual complement of a given color.
     * @param r uint8 the color red value.
     * @param g uint8 the color green value.
     * @param b uint8 the color blue value.
     * @return uint24 The unpacked RGB value of the complementary color.
     */
    function getPerceptualComplement(
        uint8 r,
        uint8 g,
        uint8 b
    ) internal pure returns (uint24) {
        // Find the absolute maximum and minimum of the three values
        uint8 maxC = Utils.max(r, g, b);
        uint8 minC = Utils.min(r, g, b);

        // Calculate the range (difference between max and min)
        uint8 range = maxC - minC; // This is safe, as maxC >= minC

        // If it's a grayscale color (r=g=b or min=max), the complement is just the inverse
        if (range == 0) {
            return Colors.packRGB(255 - r, 255 - g, 255 - b);
        }

        uint8 invR = 255 - r;
        uint8 invG = 255 - g;
        uint8 invB = 255 - b;

        // Option 1: Simple Inversion (old `_deriveInverted` method, already robust)
        // uint8 newR = invR;
        // uint8 newG = invG;
        // uint8 newB = invB;

        // Option 2: Channel Swapped Inversion (Like your earlier proposed getPerceptualComplement)
        // This is safe because (255-X) is always 0-255.
        uint8 newR = invB; // Old B inverted
        uint8 newG = invR; // Old R inverted
        uint8 newB = invG; // Old G inverted

        return Colors.packRGB(newR, newG, newB);
    }
}
