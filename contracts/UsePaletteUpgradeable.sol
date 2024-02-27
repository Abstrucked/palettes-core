// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {IManager} from "./interfaces/IManager.sol";
import {IUsePalette} from "./interfaces/IUsePalette.sol";
import {ERC165Upgradeable} from "@openzeppelin/contracts-upgradeable/utils/introspection/ERC165Upgradeable.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {console} from "hardhat/console.sol";

abstract contract UsePaletteUpgradeable is Initializable, IUsePalette , ERC165Upgradeable {
    // keccak256(abi.encode(uint256(keccak256("abstrucked.palettes.UsePalettes")) - 1)) & ~bytes32(uint256(0xff))
    bytes32 private constant UsePaletteStorageLocation = 0x5e5e01030d43f956a4f78c931500ee10bc240d7c37ba5155e6f49067079dd500;

    struct UsePaletteStorage {
        address _paletteManager;
    }

    function _getUsePaletteStorage() private pure returns (UsePaletteStorage storage $) {
        assembly {
            $.slot := UsePaletteStorageLocation
        }
    }
    function __UsePalette_init(address paletteManager) internal onlyInitializing {
        console.log("INIT::paletteManager");
        console.log(paletteManager);
        __UsePalette_init_unchained(paletteManager);
    }

    function __UsePalette_init_unchained(address paletteManager) internal onlyInitializing {
        UsePaletteStorage storage $ = _getUsePaletteStorage();
        $._paletteManager = paletteManager;
    }

    function setPalette(uint256 tokenId, uint256 paletteId, bytes calldata signature) public {
        UsePaletteStorage storage $ = _getUsePaletteStorage();
        console.log($._paletteManager);
        IManager($._paletteManager).setPaletteRecord(paletteId, address(this), tokenId, signature);
    }

    // @dev Art tokenId to palette
    function getPalette(uint256 tokenId) public view returns (string[8] memory){
        UsePaletteStorage storage $ = _getUsePaletteStorage();
        return IManager($._paletteManager).getPalette(tokenId);
    }

    function isPaletteSet(uint256 tokenId) public view returns (bool) {
        UsePaletteStorage storage $ = _getUsePaletteStorage();
        return IManager($._paletteManager).getPaletteId(tokenId, address(this)) > 0;
    }

    function getSetPaletteId(uint256 tokenId) public view returns (uint256) {
        UsePaletteStorage storage $ = _getUsePaletteStorage();
        return IManager($._paletteManager).getPaletteId(tokenId, address(this));
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IUsePalette).interfaceId || super.supportsInterface(interfaceId);
    }
}
