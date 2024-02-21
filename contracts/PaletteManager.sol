// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {IManager} from "./interfaces/IManager.sol";
import {IPalettes} from "./interfaces/IPalettes.sol";
import {IStorage} from "./interfaces/IStorage.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {console} from "hardhat/console.sol";
import {PaletteStorage} from "./PaletteStorage.sol";


contract PaletteManager is IManager, UUPSUpgradeable, OwnableUpgradeable {
    address private _palettes;
    address private _storage;

    struct PaletteRecord {
        address contractAddress;
        uint256 tokenId;
    }

//    mapping(uint256 => PaletteRecord) private _records;
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(address initialOwner, address palettesContract, address storageContract) initializer public {
        __Ownable_init(initialOwner);
        __UUPSUpgradeable_init();
//        __EIP712_init("PaletteManager", "1"); ### EIP712Upgradeable is not used moved to PalettesStorage.sol
        _palettes = palettesContract;
        _storage = storageContract;
    }

    function _authorizeUpgrade(address newImplementation)
    internal
    onlyOwner
    override
    {}
//
//    function _setPaletteRecord(uint256 paletteId, address _contractAddress, uint256 _tokenId) internal {
////        _records[paletteId] = PaletteRecord(_contractAddress, _tokenId);
//        _recordReverse[abi.encode(PaletteRecord(_contractAddress, _tokenId))] = paletteId;
//        emit PaletteRecordSet(paletteId, _contractAddress, _tokenId);
//    }

    function setPaletteRecord(
        uint256 paletteId,
        address _contractAddress,
        uint256 _tokenId,
        bytes calldata signature
    ) external {
        // Call Storage contract to set the palette record
        IStorage(_storage).setPaletteRecord(paletteId, _contractAddress, _tokenId, signature);
    }

    function getPalette(uint256 tokenId) external view returns (string[8] memory){
        uint256 paletteId = getPaletteId(tokenId, msg.sender);
        console.log("Manager::PaletteId", paletteId);
        require(paletteId > 0, "Palette not found");

        return IPalettes(_palettes).webPalette(paletteId, msg.sender);
    }

    function getPaletteId(uint256 tokenId, address _contractAddress) public view returns (uint256){
        return IStorage(_storage).getPaletteId(tokenId, _contractAddress);
    }

    function paletteOwner(uint256 paletteId) external view returns (address) {
        require(paletteId < IPalettes(_palettes).minted(), "Palette not found!");
        console.log("Palette Owner", IERC721(_palettes).ownerOf(paletteId));
        return IERC721(_palettes).ownerOf(paletteId);
    }
}
