// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;
import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import { Palettes } from "../Palettes.sol";
import { IUsePalette } from "../interfaces/IUsePalette.sol";
contract TestERC721 is ERC721, IUsePalette {
    Palettes public _palettes;
    uint256 public _tokenIdCounter;
    constructor(address palettes) ERC721("Test", "TST") {
        _tokenIdCounter++;
        _mint(msg.sender, _tokenIdCounter);
        _palettes = Palettes(palettes);
    }
    function setPalette(uint256 tokenId, uint256 paletteId, bytes calldata signature) public {
        _palettes.setPaletteRecord(tokenId, address(this), paletteId, signature);
    }

    function getPalette(uint256 tokenId) public view returns (Palettes.WebPalette memory){
        return _palettes.getWebPalette(tokenId, address(this));
    }

    function mint() public {
        _tokenIdCounter++;
        _mint(msg.sender, _tokenIdCounter);
    }
}
