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
import {IUsePalette} from "./interfaces/IUsePalette.sol";

/**
 * @title PaletteManager
 * @dev Contract for managing palettes, storing palette records, and providing palette-related functionalities.
 * Inherits from ERC165, IManager, UUPSUpgradeable, and OwnableUpgradeable.
 * Author: Abstrucked.eth
 */
contract PaletteManager is
    ERC165,
    IManager,
    UUPSUpgradeable,
    OwnableUpgradeable
{
    event StorageContractUpdated(address newAddress);

    /// @dev Address of the palettes contract
    address private _palettes;

    /// @dev Address of the storage contract
    address private _storage;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    /**
     * @notice Initializes the contract with the given owner, palettes contract, and storage contract.
     * @param initialOwner address The address of the initial owner.
     * @param palettesContract address The address of the palettes contract.
     */
    function initialize(
        address initialOwner,
        address palettesContract
    ) public initializer {
        __Ownable_init(initialOwner);
        __UUPSUpgradeable_init();
        _palettes = palettesContract;
    }

    /**
     * @notice Authorizes an upgrade to the new implementation.
     * @param newImplementation address The address of the new implementation.
     */
    function _authorizeUpgrade(
        address newImplementation
    ) internal override onlyOwner {}

    /**
     * @notice Sets the address of the PaletteStorage contract.
     * @dev Only the contract owner can call this.
     * @param storageContractAddress address The address of the PaletteStorage contract.
     */
    function setStorageContract(
        address storageContractAddress
    ) external onlyOwner {
        require(
            storageContractAddress != address(0),
            "Storage address cannot be zero"
        );
        _storage = storageContractAddress;
        // Consider emitting an event for transparency
        emit StorageContractUpdated(_storage);
    }

    /**
     * @notice Sets a palette record in the storage contract.
     * @param paletteId uint256 The palette ID.
     * @param _contractAddress address The contract address associated with the palette.
     * @param _tokenId uint256 The token ID associated with the palette.
     * @param signature bytes The signature to authorize the palette setting.
     */
    function setPaletteRecord(
        uint256 paletteId,
        address _contractAddress,
        uint256 _tokenId,
        bytes calldata signature
    ) external {
        require(_storage != address(0), "Storage contract not set.");
        // Call Storage contract to set the palette record
        IStorage(_storage).setPaletteRecord(
            paletteId,
            _contractAddress,
            _tokenId,
            signature
        );
    }

    /**
     * @notice Gets the palette for a given token ID.
     * @param tokenId uint256 The token ID.
     * @return An array of hexadecimal color codes representing the palette.
     */
    function getPalette(
        uint256 tokenId
    ) external view returns (string[8] memory) {
        require(
            ERC165(msg.sender).supportsInterface(type(IUsePalette).interfaceId),
            "PaletteManager: Caller does not implement IUsePalette interface"
        );
        uint256 paletteId = getPaletteId(tokenId, msg.sender);
        console.log("Manager::PaletteId", paletteId);
        require(paletteId > 0, "Palette not found");

        return IPalettes(_palettes).webPalette(paletteId);
    }

    /**
     * @notice Gets the palette for a given token ID.
     * @param tokenId uint256 The token ID.
     * @return An array of hexadecimal color codes representing the palette.
     */
    function getRGBPalette(
        uint256 tokenId
    ) external view returns (uint24[8] memory) {
        require(
            ERC165(msg.sender).supportsInterface(type(IUsePalette).interfaceId),
            "PaletteManager: Caller does not implement IUsePalette interface"
        );

        uint256 paletteId = getPaletteId(tokenId, msg.sender);
        console.log("Manager::PaletteId", paletteId);
        require(paletteId > 0, "Palette not found");

        return IPalettes(_palettes).rgbPalette(paletteId);
    }

    /**
     * @notice Gets the palette ID for a given token ID and contract address.
     * @param tokenId uint256 The token ID.
     * @param _contractAddress address The contract address.
     * @return uint256 The palette ID.
     */
    function getPaletteId(
        uint256 tokenId,
        address _contractAddress
    ) public view returns (uint256) {
        return IStorage(_storage).getPaletteId(tokenId, _contractAddress);
    }

    /**
     * @notice Checks if the given address is the owner of the given palette ID.
     * @param paletteId uint256 The palette ID.
     * @param signer address The address to check ownership for.
     * @return bool True if the address is the owner of the palette ID, false otherwise.
     */
    function isPaletteOwner(
        uint256 paletteId,
        address signer
    ) public view returns (bool) {
        require(
            paletteId <= IPalettes(_palettes).minted(),
            "Palette not found!"
        );
        console.log("IPalettes(_palettes).ownerOf(paletteId)");
        address owner = IERC721(_palettes).ownerOf(paletteId);
        console.log(owner);
        return owner == signer;
    }

    /**
     * @notice Gets the address of the palettes contract.
     * @return address The address of the palettes contract.
     */
    function getPalettesContract() external view returns (address) {
        return _palettes;
    }

    /**
     * @notice Checks if the contract supports a specific interface.
     * @param interfaceId bytes4 The interface ID to check.
     * @return bool True if the interface is supported, false otherwise.
     */
    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(ERC165) returns (bool) {
        return
            interfaceId == type(IManager).interfaceId ||
            super.supportsInterface(interfaceId);
    }
}

