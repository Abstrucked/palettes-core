// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

library Colors {
    function packRGB(uint8 r, uint8 g, uint8 b) internal pure returns (uint24) {
        return uint24(r) << 16 | uint24(g) << 8 | uint24(b);
    }

    function unpackRGB(uint24 color) internal pure returns (uint8 r, uint8 g, uint8 b) {
        r = uint8(color >> 16);
        g = uint8(color >> 8);
        b = uint8(color);

        return(r, g, b);
    }

    function packPalette(uint24[8] memory values) internal pure returns (uint192 packed) {
        for (uint8 i = 0; i < 8; i++) {
            packed |= uint192(values[i]) << (24 * i);
        }
    }

    function unpackPalette(uint192 packed) internal pure returns (uint24[8] memory values) {
        for (uint8 i = 0; i < 8; i++) {
            values[i] = uint24(packed >> (24 * i));
        }
    }
    function unpackPaletteAt(uint192 packed, uint8 index) internal pure returns (uint24) {
        return uint24(packed >> (24 * index));
    }
}
