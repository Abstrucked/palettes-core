// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;
import {IPaletteRenderer} from "./IPaletteRenderer.sol";
interface IPalettes {

    /// @dev Returns the the seed for a specific token.
    function getSeed(uint256) external view returns (bytes32);

    /// @dev Returns the RBG color palette for a specific token.
    function rgbPalette(uint256) external view returns (IPaletteRenderer.Color[8] memory);

    /// @dev Returns the hex color palette for a specific token.
    function webPalette(uint256) external view returns (string[8] memory);

    /// @dev Returns the SVG image of the color palette for a specific token.
    function svg(uint256) external view returns(string memory);

}
