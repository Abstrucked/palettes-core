// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;
import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import { Palettes } from "../Palettes.sol";
import { IUsePalette } from "../interfaces/IUsePalette.sol";
import {console} from "hardhat/console.sol";
contract TestERC721 is ERC721, IUsePalette {
    address public _palettes;
    uint256 public _tokenIdCounter;
    constructor(address palettes) ERC721("Test", "TST") {
        _tokenIdCounter++;
        _mint(msg.sender, _tokenIdCounter);
        _palettes = palettes;
    }

    function setPalette(uint256 tokenId, uint256 paletteId, bytes calldata signature) public {
        console.log("getPalette", address(this));
        console.logBytes( signature);
        bool isSet = Palettes(_palettes).setPaletteRecord(paletteId, address(this), tokenId, signature) ;
        if(isSet) {
            emit PaletteSet(tokenId, paletteId);
        }else {
            revert("Invalid signature or not palette owner");
        }
    }

    function getPalette(
        uint256 tokenId) public view returns (string[8] memory){
        return Palettes(_palettes).getWebPalette(tokenId, address(this));
    }

    function mint() public {
        _tokenIdCounter++;
        _mint(msg.sender, _tokenIdCounter);
    }
}
