//// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;
import "@openzeppelin/contracts/utils/Base64.sol";
import { Utils } from "../libraries/Utils.sol";
import { PaletteRenderer } from "../contracts/PaletteRenderer.sol";
import { IPalettes } from "../contracts/interfaces/IPalettes.sol";
library  PaletteMetadata {
///**
//   * @dev Returns the SVG image of the color palette for a specific token.
//   * @param _tokenId The `tokenId` for this token.
//   * @return string The SVG image of the color palette for a specific token.
//   */
//    function svg(uint256 _tokenId) private view returns(string memory) {
//        require(_tokenId <= _tokenIdCounter, "TokenId does not exist");
//        require(ownerOf(_tokenId) == msg.sender, "Not the owner of the token");
//
//        return renderer.drawPalette(_palettes[_tokenId]);
//    }
//


    /**
     * @dev Calculates and returns the metadata for a specific token.
   * @param tokenId The `tokenId` for this token.
   * @return string The metadata for a specific token.
   * @notice Code snippet based on Checks - ChecksMetadata.sol {author: Jalil.eth}
   */
    function tokenURI(uint256 tokenId, bytes32 seed)
    internal
    pure
    returns (string memory)
    {



//
//        bytes memory metadata = abi.encodePacked(
//            '{',
//            '"name": "Palettes ', Utils.uint2str(tokenId), '",',
//            '"description": "8 Color Palette.",',
//            '"image": ',
//            '"data:image/svg+xml;base64,',
//            Base64.encode(abi.encodePacked(PaletteRenderer.drawPalette(seed))),
//            '",',
//            '"animation_url": ',
//            '"data:text/html;base64,',
//            Base64.encode(
//                "generateHTML"
//            ),
//            '",',
//            '"attributes": [',attributes(seed) , ']',
//            '}'
//        );

        return string(
            abi.encodePacked(
                "data:application/json;base64,",
                Base64.encode(
                    abi.encodePacked(
                        '{',
                        '"name": "Palettes ', Utils.uint2str(tokenId), '",',
                        '"description": "8 Color Palette.",',
                        '"image": ',
                        '"data:image/svg+xml;base64,',
                        Base64.encode(abi.encodePacked(PaletteRenderer.drawPalette(seed))),
                        '",',
                        '"animation_url": ',
                        '"data:text/html;base64,',
                        Base64.encode(
                            "generateHTML"
                        ),
                        '",',
                        '"attributes": [',attributes(seed) , ']',
                        '}'
                    )
                )
            )
        );
    }

  /**
   * @dev Generate the SVG snipped for a for all attributes.
   * @param seed The `seed` for this token.
   * @return bytes The SVG snippet for the attributes.
   * @notice Code snippet based on Checks - ChecksMetadata.sol {author: Jalil.eth}
   */
    function attributes(bytes32 seed) private pure returns(bytes memory) {
        return abi.encodePacked(
            trait("Color 1", PaletteRenderer.webPalette(seed)[0], ","),
            trait("Color 2", PaletteRenderer.webPalette(seed)[1], ","),
            trait("Color 3", PaletteRenderer.webPalette(seed)[2], ","),
            trait("Color 4", PaletteRenderer.webPalette(seed)[3], ","),
            trait("Color 5", PaletteRenderer.webPalette(seed)[4], ","),
            trait("Color 6", PaletteRenderer.webPalette(seed)[5], ","),
            trait("Color 7", PaletteRenderer.webPalette(seed)[6], ","),
            trait("Color 8", PaletteRenderer.webPalette(seed)[7], "")
        );
    }

    /// @dev Generate the SVG snipped for a single attribute.
    /// @param traitType The `trait_type` for this trait.
    /// @param traitValue The `value` for this trait.
    /// @param append Helper to append a comma.
    /// @return string The SVG snippet for the attribute.
    /// @notice Code snippet from Checks - ChecksMetadata.sol {author: Jalil.eth}
    function trait(
        string memory traitType, string memory traitValue, string memory append
    ) private pure returns (string memory) {
        return string(abi.encodePacked(
            '{',
            '"trait_type": "', traitType, '",'
        '"value": "', traitValue, '"'
        '}',
            append
        ));
    }
}
//    function tokenURI(uint256 tokenId, bytes32 seed, IPaletteRenderer renderer) public view returns (string memory) {
//        bytes memory svg = abi.encodePacked(
//            IPaletteRenderer(renderer).drawPalette(seed)
//        );
//        bytes memory metadata = abi.encodePacked(
//            '{',
//            '"name": "Palettes ', Utils.uint2str(tokenId), '",',
//            '"description": "This artwork may or may not be notable.",',
//            '"image": ',
//            '"data:image/svg+xml;base64,',
//            Base64.encode(
//                svg
//            ),
//            '",',
//            '"animation_url": ',
//            '"data:text/html;base64,',
//            Base64.encode(
//                "generateHTML"
//            ),
//            '",',
//            '"attributes": [',"attributes" , ']',
//            '}'
//        );
//
//        return string(
//            abi.encodePacked(
//                "data:application/json;base64,",
//                Base64.encode(metadata)
//            )
//        );
//    }
//
////    function generateHTML(uint256 tokenId, string memory svg) private pure returns (string memory) {
////        return string(
////            abi.encodePacked(
////                "<html><body style='margin: 0; padding: 0;'><svg width='100%' height='100%' viewBox='0 0 1024 1024' xmlns='http://www.w3.org/2000/svg'>",
////                bytes(svg),
////                "</svg></body></html>"
////            )
////        );
////    }
//}
