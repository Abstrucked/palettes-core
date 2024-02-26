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
import {PaletteRenderer} from "./PaletteRenderer.sol";
import {IManager} from "./interfaces/IManager.sol";
import {console} from "hardhat/console.sol";
import {IUsePalette} from "./interfaces/IUsePalette.sol";
import {IErrors} from "./interfaces/IErrors.sol";

contract Palettes is IErrors, IPalettes, ERC721Upgradeable, OwnableUpgradeable, UUPSUpgradeable {


    uint256 private _tokenIdCounter;
    uint256 public MAX_SUPPLY;
    uint256 public MAX_MINTABLE;
    uint256 public PRICE;
    mapping(uint256 => bytes32) private _palettes;


    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(address initialOwner) initializer public {
        __ERC721_init("Palettes", "PAL");
        __Ownable_init(initialOwner);
        __UUPSUpgradeable_init();

        MAX_SUPPLY = 10000;
        MAX_MINTABLE = 20;
        PRICE = 0.01 ether;
    }


    function _authorizeUpgrade(address newImplementation)
    internal
    onlyOwner
    override
    {}

    /**
     * @dev Mints a specific amount of tokens.
     * @param amount The amount of tokens to mint.
     * @return bool True if the minting was successful.
    */
    function mint(uint256 amount) external payable returns (bool){
        require(amount > 0, "Amount must be greater than 0");
        if(amount > MAX_MINTABLE) revert ExceedMaxMintable(MAX_MINTABLE);
        if(_tokenIdCounter + amount > MAX_SUPPLY) revert MaxSupplyReached();
        if(msg.value != amount * PRICE) revert IncorrectPrice(amount * PRICE);
        for(uint8 i=0; i<amount; i++){
            _tokenIdCounter++;
            _safeMint(msg.sender, _tokenIdCounter);
            _palettes[_tokenIdCounter] = _generateSeed(_tokenIdCounter);
        }
        return true;
    }

    function minted() external view returns (uint256){
        return _tokenIdCounter;
    }

    /**
     * @dev Generates a seed for a specific token.
     * @param _tokenId The `tokenId` for this token.
     * @return bytes32 The seed for a specific token.
    */
    function _generateSeed(uint256 _tokenId) private view returns (bytes32){
        require(_tokenId <= _tokenIdCounter, "TokenId does not exist");
        return Utils.randomBytes32(string(abi.encode(block.timestamp, msg.sender, (_tokenId))));
    }

    /**
     * @dev Returns the the seed for a specific token.
     * @param _tokenId The `tokenId` for this token.
     * @return bytes32 The seed for a specific token.
    */
    function getSeed(uint256 _tokenId) external view returns (bytes32){
        if (_tokenId > _tokenIdCounter) {
            revert IdNotFound();
        }
        return _palettes[_tokenId];
    }

    /**
     * @dev Returns the RBG color palette for a specific token.
     * @param _tokenId The `tokenId` for this token.
     * @return Color[8] The RBG color palette for a specific token.
    */
    function rgbPalette(uint256 _tokenId) external view returns (uint24[8] memory) {
        require(_tokenId <= _tokenIdCounter, "TokenId does not exist");
        require(ownerOf(_tokenId) == msg.sender, "Not the owner of the token");

        uint192 palette = PaletteRenderer.getBasePalette(_palettes[_tokenId]);
        return [
            uint24(palette >> 168),
            uint24(palette >> 144),
            uint24(palette >> 120),
            uint24(palette >> 96),
            uint24(palette >> 72),
            uint24(palette >> 48),
            uint24(palette >> 24),
            uint24(palette)
            ];
    }

   /**
   * @dev Returns the hex color palette for a specific token.
   * @param _tokenId The `tokenId` for this token.
   * @return string The hex color palette for a specific token.
   */
    function webPalette(uint256 _tokenId, address _contract) external view returns (string[8] memory)  {
        require(
            IERC165(msg.sender).supportsInterface(type(IManager).interfaceId),
            "Caller does not implement IManager interface"
        );
        require(
            IERC165(_contract).supportsInterface(type(IUsePalette).interfaceId),
            "Contract does not implement IUsePalette interface"
        );

        /// @dev Check if the paletteId is valid is done in the manager contract as well
//        require(paletteId > 0, "Palette not found");
        console.log("MSG_SENDER");
        console.log(msg.sender);
//        require(_tokenId <= _tokenIdCounter, "TokenId does not exist");
//        require(ownerOf(_tokenId) == msg.sender, "Not the owner of the token");

        return PaletteRenderer.webPalette(_palettes[_tokenId]);
    }

    function _update(address to, uint256 tokenId, address auth)
    internal
    override(ERC721Upgradeable)
    returns (address)
    {
        return super._update(to, tokenId, auth);
    }


    function supportsInterface(bytes4 interfaceId)
    public
    view
    override(ERC721Upgradeable)
    returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns the SVG image of the color palette for a specific token.
    * @param _tokenId The `tokenId` for this token.
    * @return string The SVG image of the color palette for a specific token.
    */
    function svg(uint256 _tokenId) external view returns (string memory) {
        require(_tokenId <= _tokenIdCounter, "TokenId does not exist");
        require(ownerOf(_tokenId) == msg.sender, "Not the owner of the token");

        return PaletteRenderer.drawPalette(_palettes[_tokenId]);
    }



    /**
    * @dev Calculates and returns the metadata for a specific token.
    * @param tokenId The `tokenId` for this token.
    * @return string The metadata for a specific token.
    * @notice Code snippet based on Checks - ChecksMetadata.sol {author: Jalil.eth}
    */
    function tokenURI(uint256 tokenId)
    public
    view
    override(ERC721Upgradeable)
    returns (string memory)
    {
        require(tokenId <= _tokenIdCounter, "TokenId does not exist");

        return PaletteMetadata.tokenURI(tokenId, _palettes[tokenId]);
    }

}