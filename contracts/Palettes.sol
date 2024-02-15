// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// import "./ColorConverter.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/EIP712Upgradeable.sol";
import { IERC721 } from "@openzeppelin/contracts/token/ERC721/IERC721.sol";

import "../libraries/Utils.sol";
import {PaletteMetadata} from "../libraries/PaletteMetadata.sol";
import {IPalettes} from "./interfaces/IPalettes.sol";
import {IPaletteRenderer} from "./interfaces/IPaletteRenderer.sol";
import {PaletteRenderer} from "./PaletteRenderer.sol";
import { ECDSA } from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

import {console} from "hardhat/console.sol";

contract Palettes is IPalettes, Initializable, ERC721Upgradeable, OwnableUpgradeable, EIP712Upgradeable {
  error MaxSupplyReached();
  error IdNotFound();
  uint256 private _tokenIdCounter;
  
  uint256 public MAX_SUPPLY;
  
  mapping(uint256 => bytes32) private _palettes;
  mapping(uint256 => PaletteRecord) private _records;
  mapping(bytes => uint256) private _recordReverse;
//  PaletteRenderer public renderer;

  modifier onlyOwnerOf(uint256 tokenId) {
    require(ownerOf(tokenId) == msg.sender, "Not the owner of the token");
    _;
  }

  /// @custom:oz-upgrades-unsafe-allow constructor
  constructor() {
    _disableInitializers();
  }

  function initialize(address initialOwner) initializer public {
    __ERC721_init("Palettes", "PAL");
    __Ownable_init(initialOwner);
    __EIP712_init("Palettes", "1");
    MAX_SUPPLY = 10000;
//    renderer = PaletteRenderer(_renderer);

  }

  function mint() external returns (uint256){
    if(_tokenIdCounter>= MAX_SUPPLY) {
        revert MaxSupplyReached();
    }
    _tokenIdCounter++;
    uint256 tokenId = _tokenIdCounter;
    _palettes[tokenId] = _generateSeed(tokenId);
    _safeMint(msg.sender, tokenId);
    
    return tokenId;
  }

  function minted() external view returns(uint256){
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
    if(_tokenId > _tokenIdCounter) {
      revert IdNotFound();
    }
    return _palettes[_tokenId];
  }

  /**
   * @dev Returns the RBG color palette for a specific token.
   * @param _tokenId The `tokenId` for this token.
   * @return Color[8] The RBG color palette for a specific token.
   */
  function rgbPalette(uint256 _tokenId) external view returns (RGBPalette memory) {
    require(_tokenId <= _tokenIdCounter, "TokenId does not exist");
    require(ownerOf(_tokenId) == msg.sender, "Not the owner of the token");

    return PaletteRenderer.getBasePalette(_palettes[_tokenId]);
  }

  /**
   * @dev Returns the hex color palette for a specific token.
   * @param _tokenId The `tokenId` for this token.
   * @return string The hex color palette for a specific token.
   */
  function webPalette(uint256 _tokenId) external view returns (string[8] memory) {
    require(_tokenId <= _tokenIdCounter, "TokenId does not exist");
    require(ownerOf(_tokenId) == msg.sender, "Not the owner of the token");

    return  PaletteRenderer.webPalette(_palettes[_tokenId]);
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
  function svg(uint256 _tokenId) external view returns(string memory) {
    require(_tokenId <= _tokenIdCounter, "TokenId does not exist");
    require(ownerOf(_tokenId) == msg.sender, "Not the owner of the token");

    return PaletteRenderer.drawPalette(_palettes[_tokenId]);
  }
//
//
//
//  /**
//   * @dev Calculates and returns the metadata for a specific token.
//   * @param tokenId The `tokenId` for this token.
//   * @return string The metadata for a specific token.
//   * @notice Code snippet based on Checks - ChecksMetadata.sol {author: Jalil.eth}
//   */
  function tokenURI(uint256 tokenId)
  public
  view
  override(ERC721Upgradeable)
  returns (string memory)
  {
    require(tokenId <= _tokenIdCounter, "TokenId does not exist");

   return PaletteMetadata.tokenURI(tokenId, _palettes[tokenId]);
  }
//
//  /**
//   * @dev Generate the SVG snipped for a for all attributes.
//   * @param tokenId The `tokenId` for this token.
//   * @return bytes The SVG snippet for the attributes.
//   * @notice Code snippet based on Checks - ChecksMetadata.sol {author: Jalil.eth}
//   */
//  function attributes(uint256 tokenId) private view returns(bytes memory) {
//    require(tokenId <= _tokenIdCounter, "TokenId does not exist");
//    return abi.encodePacked(
//      trait("Color 1", PaletteRenderer.webPalette(_palettes[tokenId]).colors[0], ","),
//      trait("Color 2", PaletteRenderer.webPalette(_palettes[tokenId]).colors[1], ","),
//      trait("Color 3", PaletteRenderer.webPalette(_palettes[tokenId]).colors[2], ","),
//      trait("Color 4", PaletteRenderer.webPalette(_palettes[tokenId]).colors[3], ","),
//      trait("Color 5", PaletteRenderer.webPalette(_palettes[tokenId]).colors[4], ","),
//      trait("Color 6", PaletteRenderer.webPalette(_palettes[tokenId]).colors[5], ","),
//      trait("Color 7", PaletteRenderer.webPalette(_palettes[tokenId]).colors[6], ","),
//      trait("Color 8", PaletteRenderer.webPalette(_palettes[tokenId]).colors[7], "")
//    );
//  }

  /// @dev Generate the SVG snipped for a single attribute.
  /// @param traitType The `trait_type` for this trait.
  /// @param traitValue The `value` for this trait.
  /// @param append Helper to append a comma.
  /// @return string The SVG snippet for the attribute.
  /// @notice Code snippet from Checks - ChecksMetadata.sol {author: Jalil.eth}
//  function trait(
//    string memory traitType, string memory traitValue, string memory append
//  ) public pure returns (string memory) {
//    return string(abi.encodePacked(
//      '{',
//      '"trait_type": "', traitType, '",'
//    '"value": "', traitValue, '"'
//    '}',
//      append
//    ));
//  }

  /// @dev Modifier should check for the owner of the linkedToken is the same as the msg.sender from
  /// the sender contract.
//  modifier ownerOfLinkedToken(uint256 tokenId, address sender) {
//    require(IERC721(_records[paletteId].contractAddress).ownerOf(_records[paletteId].tokenId) == msg.sender, "Not the owner of the token");
//    _;
//  }

//  function _setPaletteRecord(uint256 paletteId, address _contractAddress, uint256 _tokenId) internal  {
//    _records[paletteId] = PaletteRecord(_contractAddress, _tokenId);
//    _recordReverse[abi.encode(PaletteRecord(_contractAddress, _tokenId))] = paletteId;
//  }

  function setPaletteRecord(uint256 paletteId, address _contractAddress, uint256 _tokenId, bytes calldata signature) external  {


  }

  function getWebPalette(uint256 tokenId, address _contractAddress) external view returns (string[8] memory){
    console.log("msg.sender", msg.sender);
    uint256 paletteId =  _recordReverse[abi.encode(PaletteRecord(_contractAddress, tokenId))];
    require(paletteId > 0, "Palette not found");
//    require(ownerOf(paletteId) == msg.sender, "Not the owner of the token");
    return PaletteRenderer.webPalette(_palettes[paletteId]);
  }
}