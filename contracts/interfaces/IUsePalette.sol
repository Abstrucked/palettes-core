// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {IPalettes} from "./IPalettes.sol";

interface IUsePalette {

    function setPalette(uint256 tokenId, uint256 paletteId, bytes calldata signature) external;
    function getPalette(uint256 tokenId) external view returns (IPalettes.WebPalette memory);
}
