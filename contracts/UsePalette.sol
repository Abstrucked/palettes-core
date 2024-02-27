// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;
import {IUsePalette} from "./interfaces/IUsePalette.sol";
import {IManager} from "./interfaces/IManager.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";

import {console} from "hardhat/console.sol";

contract UsePalette is IUsePalette, ERC165 {
    address private _paletteManager;
    constructor(address paletteManager){
        _paletteManager = paletteManager;
    }

    function setPalette(uint256 tokenId, uint256 paletteId, bytes calldata signature) public {
        console.log("getPalette", address(this));
        console.logBytes( signature);
        IManager(_paletteManager).setPaletteRecord(paletteId, address(this), tokenId, signature) ;

    }

    /// @dev Art tokenId to palette
    function getPalette(
        uint256 tokenId) public view returns (string[8] memory){
        return IManager(_paletteManager).getPalette(tokenId);
    }

    function isPaletteSet(uint256 tokenId) external view returns (bool) {
        return IManager(_paletteManager).getPaletteId(tokenId, address(this)) > 0;
    }

    function getSetPaletteId(uint256 tokenId) external view returns (uint256) {
        return IManager(_paletteManager).getPaletteId(tokenId, address(this));
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165) returns (bool) {
        return interfaceId == type(IUsePalette).interfaceId || super.supportsInterface(interfaceId);
    }
}
