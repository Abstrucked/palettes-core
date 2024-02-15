// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {IPalettes} from "./IPalettes.sol";

/// @title Palette Renderer Interface
/// @author Abstrucked.eth
interface IPaletteRenderer {

    /// @dev Returns the color from the palette seed.
    function getBaseColor(bytes32) external pure returns (IPalettes.RGBColor memory);

    /// @dev Returns the RGB palette from the palette seed.
    function getBasePalette(bytes32) external pure returns (IPalettes.RGBPalette memory);

    /// @dev Returns the hex color palette from the palette seed.
    function webPalette(bytes32) external pure returns (IPalettes.WebPalette memory);

    /// @dev Returns the SVG color palette from the palette seed.
    function drawPalette(bytes32) external pure returns (string memory);
}
