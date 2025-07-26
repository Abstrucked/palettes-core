// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";

import {Utils} from "../libraries/Utils.sol";
import {PaletteMetadata} from "../libraries/PaletteMetadata.sol";
import {IPalettes} from "./interfaces/IPalettes.sol";
import {IPaletteRenderer} from "./interfaces/IPaletteRenderer.sol";
import {PaletteRenderer} from "../libraries/PaletteRenderer.sol";
import {IManager} from "./interfaces/IManager.sol";
import {IUsePalette} from "./interfaces/IUsePalette.sol";
import {IErrors} from "./interfaces/IErrors.sol";

/**
 * @title Palettes
 * @dev Contract for managing ERC721 tokens representing color palettes. Provides
 * functionalities to mint, store and retrieve palettes.
 * Inherits from IErrors, IPalettes, ERC721Upgradeable, OwnableUpgradeable, UUPSUpgradeable.
 * Author: Abstrucked.eth
 */
contract Palettes is
    IErrors,
    IPalettes,
    ERC721Upgradeable,
    OwnableUpgradeable,
    UUPSUpgradeable
{
    event PriceChanged(uint256);
    event ManagerUpdated(address newManager);
    event RendererUpdated(address newRenderer);
    event MetadataUpdated(address newMetadata);

    uint256 private _tokenIdCounter;
    uint256 public MAX_SUPPLY;
    uint256 public MAX_MINTABLE;
    uint256 public price;
    address public managerContractAddress;
    address public paletteRendererAddress;
    address public paletteMetadataAddress;

    mapping(uint256 => bytes32) private _palettes;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    /**
     * @notice Initializes the contract with the given owner, MAX_SUPPLY, MAX_MINTABLE, and price.
     * @param initialOwner address The address of the initial owner.
     */
    function initialize(
        address initialOwner,
        address _paletteRendererAddress,
        address _paletteMetadataAddress
    ) public initializer {
        __ERC721_init("Palettes", "PAL");
        __Ownable_init(initialOwner);
        __UUPSUpgradeable_init();

        paletteRendererAddress = _paletteRendererAddress;
        paletteMetadataAddress = _paletteMetadataAddress;

        MAX_SUPPLY = 10000;
        MAX_MINTABLE = 20;
        price = 0.005 ether;
    }

    /**
     * @notice Authorizes an upgrade to the new implementation.
     * @param newImplementation address The address of the new implementation.
     */
    function _authorizeUpgrade(
        address newImplementation
    ) internal override onlyOwner {}

    /**
     * @notice Sets the new minting price.
     * @dev Only the contract owner can call this.
     * @param _newPrice uint256 The new price.
     */
    function setPrice(uint256 _newPrice) external onlyOwner {
        price = _newPrice;
        emit PriceChanged(price);
    }

    /**
     * @notice Sets the address of the trusted PaletteManager contract.
     * @dev Only the contract owner can call this.
     * @param _newManager address The address of the PaletteManager contract.
     */
    function setManagerContractAddress(address _newManager) external onlyOwner {
        require(_newManager != address(0), "Manager address cannot be zero");
        managerContractAddress = _newManager;
        // Consider emitting an event:
        emit ManagerUpdated(_newManager);
    }

    /**
     * @notice Sets the address of the Metadata contract.
     * @dev Only the contract owner can call this.
     * @param _newMetadata address The address of the Metadata contract.
     */
    function setMetadataContractAddress(
        address _newMetadata
    ) external onlyOwner {
        require(_newMetadata != address(0), "Manager address cannot be zero");
        managerContractAddress = _newMetadata;
        // Consider emitting an event:
        emit MetadataUpdated(_newMetadata);
    }

    /**
     * @notice Sets the address of the Renderer contract.
     * @dev Only the contract owner can call this.
     * @param _newRenderer address The address of the Renderer contract.
     *
     */
    function setRendererContractAddress(
        address _newRenderer
    ) external onlyOwner {
        require(_newRenderer != address(0), "Manager address cannot be zero");
        managerContractAddress = _newRenderer;
        // Consider emitting an event:
        emit MetadataUpdated(_newRenderer);
    }

    /**
     * @notice Mints a specific amount of tokens.
     * @param amount uint256 The amount of tokens to mint.
     * @return bool True if the minting was successful.
     */
    function mint(uint256 amount) external payable returns (bool) {
        require(amount > 0, "Amount must be greater than 0");
        if (amount > MAX_MINTABLE) revert ExceedMaxMintable(MAX_MINTABLE);
        if (_tokenIdCounter + amount > MAX_SUPPLY) revert MaxSupplyReached();
        if (msg.value != amount * price) revert IncorrectPrice(amount * price);

        unchecked {
            for (uint8 i = 0; i < amount; i++) {
                _tokenIdCounter++;
                _safeMint(msg.sender, _tokenIdCounter);
                _palettes[_tokenIdCounter] = _generateSeed(_tokenIdCounter);
            }
        }
        return true;
    }

    /**
     * @notice Returns the number of minted tokens.
     * @return uint256 The number of minted tokens.
     */
    function minted() external view returns (uint256) {
        return _tokenIdCounter;
    }

    /**
     * @dev Generates a seed for a specific token.
     * @param _tokenId uint256 The `tokenId` for this token.
     * @return bytes32 The seed for a specific token.
     */
    function _generateSeed(uint256 _tokenId) private view returns (bytes32) {
        require(_tokenId <= _tokenIdCounter, "TokenId does not exist");
        return
            Utils.randomBytes32(
                string(abi.encode(block.timestamp, msg.sender, (_tokenId)))
            );
    }

    /**
     * @notice Returns the seed for a specific token.
     * @param _tokenId uint256 The `tokenId` for this token.
     * @return bytes32 The seed for a specific token.
     */
    function getSeed(uint256 _tokenId) external view returns (bytes32) {
        if (_tokenId > _tokenIdCounter) {
            revert IdNotFound();
        }
        return _palettes[_tokenId];
    }

    /**
     * @notice Returns the RGB color palette for a specific token.
     * @param _tokenId uint256 The `tokenId` for this token.
     * @return uint24[8] The RGB color palette for a specific token.
     */
    function rgbPalette(
        uint256 _tokenId
    ) external view returns (uint24[8] memory) {
        require(
            msg.sender == managerContractAddress,
            "Palettes: Access denied. Only Manager can call."
        );

        return
            PaletteRenderer(paletteRendererAddress).rgbPalette(
                _palettes[_tokenId]
            );
    }

    /**
     * @notice Returns the hex color palette for a specific token.
     * @param _tokenId uint256 The `tokenId` for this token.
     * @return string[8] The hex color palette for a specific token.
     */
    function webPalette(
        uint256 _tokenId
    ) external view returns (string[8] memory) {
        require(
            msg.sender == managerContractAddress,
            "Palettes: Access denied. Only Manager can call."
        );

        return
            PaletteRenderer(paletteRendererAddress).webPalette(
                _palettes[_tokenId]
            );
    }

    /**
     * @dev Updates the ownership of a given token.
     * @param to address The new owner's address.
     * @param tokenId uint256 The token ID.
     * @param auth address The authorized address.
     * @return address The previous owner's address.
     */
    function _update(
        address to,
        uint256 tokenId,
        address auth
    ) internal override(ERC721Upgradeable) returns (address) {
        return super._update(to, tokenId, auth);
    }

    /**
     * @notice Checks if the contract supports a specific interface.
     * @param interfaceId bytes4 The interface ID to check.
     * @return bool True if the interface is supported, false otherwise.
     */
    function supportsInterface(
        bytes4 interfaceId
    ) public view override(ERC721Upgradeable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    /**
     * @notice Returns the SVG image of the color palette for a specific token.
     * @param _tokenId uint256 The `tokenId` for this token.
     * @return string The SVG image of the color palette for a specific token.
     */
    function svg(uint256 _tokenId) external view returns (string memory) {
        require(_tokenId <= _tokenIdCounter, "TokenId does not exist");
        require(ownerOf(_tokenId) == msg.sender, "Not the owner of the token");

        return
            PaletteRenderer(paletteRendererAddress).drawPalette(
                _palettes[_tokenId]
            );
    }

    /**
     * @notice Calculates and returns the metadata for a specific token.
     * @param tokenId uint256 The `tokenId` for this token.
     * @return string The metadata for a specific token.
     * @notice Code snippet based on Checks - ChecksMetadata.sol {author: Jalil.eth}
     */
    function tokenURI(
        uint256 tokenId
    ) public view override(ERC721Upgradeable) returns (string memory) {
        require(tokenId <= _tokenIdCounter, "TokenId does not exist");

        return
            PaletteMetadata(paletteMetadataAddress).tokenURI(
                tokenId,
                _palettes[tokenId]
            );
    }
}
