//// SPDX-License-Identifier: UNLICENSED
//pragma solidity ^0.8.0;
//import "@openzeppelin/contracts/utils/Base64.sol";
//import { Utils } from "../libraries/Utils.sol";
//import { IPaletteRenderer } from "../contracts/interfaces/IPaletteRenderer.sol";
//library  PaletteMetadata {
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
