// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/utils/Base64.sol";
import {Utils} from "../libraries/Utils.sol";
import {PaletteRenderer} from "./PaletteRenderer.sol";
import {IPalettes} from "./interfaces/IPalettes.sol";

/// @title PaletteMetadata
/// @dev Library for generating SVG and metadata for color palettes associated with tokens.
contract PaletteMetadata {
    address paletteRenderer;

    constructor(address _renderer) {
        paletteRenderer = _renderer;
    }

    /**
     * @dev Calculates and returns the metadata for a specific token.
     * @param tokenId The `tokenId` for this token.
     * @param seed The `seed` for this token.
     * @return string The metadata for a specific token.
     * @notice Code snippet based on Checks - ChecksMetadata.sol {author: Jalil.eth}
     */
    function tokenURI(
        uint256 tokenId,
        bytes32 seed
    ) external view returns (string memory) {
        return
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    Base64.encode(
                        abi.encodePacked(
                            "{",
                            '"name": "Palettes ',
                            Utils.uint2str(tokenId),
                            '",',
                            '"description": "8 Color Palette.",',
                            '"image": ',
                            '"data:image/svg+xml;base64,',
                            Base64.encode(
                                abi.encodePacked(
                                    PaletteRenderer(paletteRenderer)
                                        .drawPalette(seed)
                                )
                            ),
                            '",',
                            '"animation_url": ',
                            '"data:text/html;base64,',
                            Base64.encode(
                                abi.encodePacked(
                                    generateHTML(
                                        PaletteRenderer(paletteRenderer)
                                            .drawPalette(seed)
                                    )
                                )
                            ),
                            '",',
                            '"attributes": [',
                            attributes(seed),
                            "]",
                            "}"
                        )
                    )
                )
            );
    }

    /**
     * @dev Generate the SVG snippet for all attributes.
     * @param seed The `seed` for this token.
     * @return bytes The SVG snippet for the attributes.
     * @notice Code snippet based on Checks - ChecksMetadata.sol {author: Jalil.eth}
     */
    function attributes(bytes32 seed) private view returns (bytes memory) {
        PaletteRenderer renderer = PaletteRenderer(paletteRenderer);
        return
            abi.encodePacked(
                trait("Color 1", renderer.webPalette(seed)[0], ","),
                trait("Color 2", renderer.webPalette(seed)[1], ","),
                trait("Color 3", renderer.webPalette(seed)[2], ","),
                trait("Color 4", renderer.webPalette(seed)[3], ","),
                trait("Color 5", renderer.webPalette(seed)[4], ","),
                trait("Color 6", renderer.webPalette(seed)[5], ","),
                trait("Color 7", renderer.webPalette(seed)[6], ","),
                trait("Color 8", renderer.webPalette(seed)[7], "")
            );
    }

    /**
     * @dev Generate the attribute string for a single attribute.
     * @param traitType The `trait_type` for this trait.
     * @param traitValue The `value` for this trait.
     * @param append Helper to append a comma.
     * @return string The attribute string.
     * @notice Code snippet from Checks - ChecksMetadata.sol {author: Jalil.eth}
     */
    function trait(
        string memory traitType,
        string memory traitValue,
        string memory append
    ) private pure returns (string memory) {
        return
            string(
                abi.encodePacked(
                    "{",
                    '"trait_type": "',
                    traitType,
                    '",',
                    '"value": "',
                    traitValue,
                    '"',
                    "}",
                    append
                )
            );
    }

    /**
     * @dev Generate the HTML for a specific token's palette.
     * @param svg The SVG string for the token's palette.
     * @return string The generated HTML.
     */
    function generateHTML(
        string memory svg
    ) private pure returns (string memory) {
        return
            string(
                abi.encodePacked(
                    "<html><body style='margin: 0; padding: 0;'><svg width='100%' height='100%' xmlns='http://www.w3.org/2000/svg'>",
                    svg,
                    "</svg></body></html>"
                )
            );
    }
}
