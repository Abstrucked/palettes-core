// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;
import "@openzeppelin/contracts/interfaces/IERC165.sol";

//import {IPalettes} from "./IPalettes.sol";

/**
 toDo:  Add paletteManager infrastructure to lift weight form the Palette.sol contract
        Elaborate on the PaletteManager interface
        Think about user experience and how to make it easier to use for devs/artists in contracts
*/


interface IUsePalette {
    event PaletteSet(uint256 indexed tokenId, uint256 indexed paletteId);
    function setPalette(uint256 tokenId, uint256 paletteId, bytes calldata signature) external;
    function getPalette(uint256 tokenId) external view returns (string[8] memory);
//    function getPaletteId(uint256 tokenId) external view returns (uint256);
}
