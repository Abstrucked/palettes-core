// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;
import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";

import { Palettes } from "../Palettes.sol";
import { IUsePalette } from "../interfaces/IUsePalette.sol";
import {IPaletteManager} from "../interfaces/IPaletteManager.sol";
import {console} from "hardhat/console.sol";
contract TestERC721 is ERC165, ERC721, IUsePalette {
    address private _paletteManager;
    address private _palettes;
    uint256 public _tokenIdCounter;
    constructor(address paletteManager, address palettes) ERC721("Test", "TST") {
        _tokenIdCounter++;
        _mint(msg.sender, _tokenIdCounter);
        _paletteManager = paletteManager;
        _palettes = palettes;
    }
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, ERC165) returns (bool) {
        return interfaceId == type(IUsePalette).interfaceId || super.supportsInterface(interfaceId);
    }
    function setPalette(uint256 tokenId, uint256 paletteId, bytes calldata signature) public {
        console.log("getPalette", address(this));
        console.logBytes( signature);
        bool isSet = IPaletteManager(_paletteManager).setPaletteRecord(paletteId, address(this), tokenId, signature) ;
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

    function mint() public {
        _tokenIdCounter++;
        _mint(msg.sender, _tokenIdCounter);
    }
}
