// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {ERC165} from "@openzeppelin/contracts/utils/introspection/ERC165.sol";

import {IManager} from "./interfaces/IManager.sol";
import {IPalettes} from "./interfaces/IPalettes.sol";
import {IStorage} from "./interfaces/IStorage.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {console} from "hardhat/console.sol";


contract PaletteManager is ERC165, IManager, UUPSUpgradeable, OwnableUpgradeable {
    address private _palettes;
    address private _storage;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(address initialOwner, address palettesContract, address storageContract) initializer public {
        __Ownable_init(initialOwner);
        __UUPSUpgradeable_init();
        _palettes = palettesContract;
        _storage = storageContract;
    }

    function _authorizeUpgrade(address newImplementation)
    internal
    onlyOwner
    override
    {}

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

    function isPaletteOwner(uint256 paletteId, address signer) public view returns (bool) {
        require(paletteId <= IPalettes(_palettes).minted(), "Palette not found!");
        console.log("IPalettes(_palettes).ownerOf(paletteId)");
        address owner = IERC721(_palettes).ownerOf(paletteId);
        console.log(owner);
        return owner == signer;
    }

    function getPalettesContract() external view returns (address) {
        return _palettes;
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165) returns (bool) {
        return interfaceId == type(IManager).interfaceId || super.supportsInterface(interfaceId);
    }
}
