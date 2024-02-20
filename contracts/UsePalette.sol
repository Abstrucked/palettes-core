// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;
import {IUsePalette} from "./interfaces/IUsePalette.sol";
import {IManager} from "./interfaces/IManager.sol";
import {Palettes} from "./Palettes.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";

import {console} from "hardhat/console.sol";

contract UsePalette is IUsePalette, ERC165 {
    address private _paletteManager;
    address private _palettes;
    constructor(address paletteManager, address palettes){
        _paletteManager = paletteManager;
        _palettes = palettes;
    }

    function setPalette(uint256 tokenId, uint256 paletteId, bytes calldata signature) public {
        console.log("getPalette", address(this));
        console.logBytes( signature);
        bool isSet = IManager(_paletteManager).setPaletteRecord(paletteId, address(this), tokenId, signature) ;
        if(isSet) {
            emit PaletteSet(tokenId, paletteId);
        }else {
            revert("Invalid signature or not palette owner");
        }
    }

    function getPalette(
        uint256 tokenId) public view returns (string[8] memory){
        return Palettes(_palettes).webPalette(tokenId);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165) returns (bool) {
        return interfaceId == type(IUsePalette).interfaceId || super.supportsInterface(interfaceId);
    }
}
