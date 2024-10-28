// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;
import {ERC165} from "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {UsePalette} from "../UsePalette.sol";

import {console} from "hardhat/console.sol";
contract TestERC721 is  ERC165, ERC721, UsePalette {

    uint256 public _tokenIdCounter;
    constructor(address paletteManager)
        ERC721("Test", "TST")
        UsePalette(paletteManager)
    {
        _tokenIdCounter++;
        _mint(msg.sender, _tokenIdCounter);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, ERC165, UsePalette) returns (bool) {
        return super.supportsInterface(interfaceId);
    }



    function mint() public {
        _tokenIdCounter++;
        _mint(msg.sender, _tokenIdCounter);
    }
}
