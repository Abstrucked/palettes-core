// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;
import {ERC165} from "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {UsePalette} from "../UsePalette.sol";
import {IManager} from "../interfaces/IManager.sol";

import {console} from "hardhat/console.sol";
import {UsePaletteUpgradeable} from "../UsePaletteUpgradeable.sol";

contract TestERC721Upgradeable is
    ERC165,
    ERC721Upgradeable,
    OwnableUpgradeable,
    UsePaletteUpgradeable
{
    uint256 public MAX_SUPPLY;
    uint256 public _tokenIdCounter;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(
        address initialOwner,
        address paletteManager
    ) public initializer {
        __ERC721_init("TestUpgradeable", "TESTUPGRADE");
        __Ownable_init(initialOwner);
        __UsePalette_init(paletteManager);
        MAX_SUPPLY = 10000;
        _tokenIdCounter++;
        _mint(msg.sender, _tokenIdCounter);
    }

    function testIsPaletteSet(uint256 tokenId) external view returns (bool) {
        bool result = isPaletteSet(tokenId);
        return result;
    }

    function supportsInterface(
        bytes4 interfaceId
    )
        public
        view
        virtual
        override(ERC721Upgradeable, ERC165, UsePaletteUpgradeable)
        returns (bool)
    {
        return
            interfaceId == type(UsePaletteUpgradeable).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    function mint() public {
        _tokenIdCounter++;
        _mint(msg.sender, _tokenIdCounter);
    }
}
