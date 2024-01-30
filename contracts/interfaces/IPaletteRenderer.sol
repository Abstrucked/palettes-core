// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

/// @title Palette Renderer Interface
/// @author Abstrucked.eth
interface IPaletteRenderer {
    /// Color struct definition
    struct Color {
        uint8 r;
        uint8 g;
        uint8 b;
    }

    /// @dev Returns the color from the palette seed.
    function getRGB(bytes32) external pure returns (uint8[3] memory);

    /// @dev Returns the RGB palette from the palette seed.
    function getBasePalette(bytes32) external pure returns (Color[8] memory);

    /// @dev Returns the hex color palette from the palette seed.
    function webPalette(bytes32) external pure returns (string[8] memory);

    /// @dev Returns the SVG color palette from the palette seed.
    function drawPalette(bytes32) external pure returns (string memory);
}
