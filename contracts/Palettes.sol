// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

// import "./ColorConverter.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721BurnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/utils/Base64.sol";

import "../libraries/Utils.sol";
import {IPalettes} from "./interfaces/IPalettes.sol";
import {IPaletteRenderer} from "./interfaces/IPaletteRenderer.sol";
import {PaletteRenderer} from "./PaletteRenderer.sol";

contract Palettes is IPalettes, Initializable, ERC721Upgradeable, ERC721PausableUpgradeable, OwnableUpgradeable, ERC721BurnableUpgradeable{
  error MaxSupplyReached();
  error IdNotFound();
  uint256 private _tokenIdCounter;
  
  uint256 public MAX_SUPPLY;
  
  mapping(uint256 => bytes32) private _palettes;
  
  PaletteRenderer public renderer;

  /// @custom:oz-upgrades-unsafe-allow constructor
  constructor() {
    _disableInitializers();
  }

  function initialize(address initialOwner, PaletteRenderer _renderer) initializer public {
    __ERC721_init("Palettes", "PAL");
    __ERC721Pausable_init();
    __Ownable_init(initialOwner);
    __ERC721Burnable_init();
    MAX_SUPPLY = 10000;
    renderer = PaletteRenderer(_renderer);

  }

  function mint() public returns (uint256){
    if(_tokenIdCounter>= MAX_SUPPLY) {
        revert MaxSupplyReached();
    }
    _tokenIdCounter++;
    uint256 tokenId = _tokenIdCounter;
    _palettes[tokenId] = generateSeed(tokenId);
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
  function generateSeed(uint256 _tokenId) private view returns (bytes32){
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
  function rgbPalette(uint256 _tokenId) public view returns (PaletteRenderer.Color[8] memory) {
    require(_tokenId <= _tokenIdCounter, "TokenId does not exist");
    require(ownerOf(_tokenId) == msg.sender, "Not the owner of the token");

    return renderer.getBasePalette(_palettes[_tokenId]);
  }

  /**
   * @dev Returns the hex color palette for a specific token.
   * @param _tokenId The `tokenId` for this token.
   * @return string The hex color palette for a specific token.
   */
  function webPalette(uint256 _tokenId) public view returns (string[8] memory) {
    require(_tokenId <= _tokenIdCounter, "TokenId does not exist");
    require(ownerOf(_tokenId) == msg.sender, "Not the owner of the token");

    return  renderer.webPalette(_palettes[_tokenId]);
  }

  /**
   * @dev Returns the SVG image of the color palette for a specific token.
   * @param _tokenId The `tokenId` for this token.
   * @return string The SVG image of the color palette for a specific token.
   */
  function svg(uint256 _tokenId) public view returns(string memory) {
    require(_tokenId <= _tokenIdCounter, "TokenId does not exist");
    require(ownerOf(_tokenId) == msg.sender, "Not the owner of the token");

    return renderer.drawPalette(_palettes[_tokenId]);
  }

  function _update(address to, uint256 tokenId, address auth)
  internal
  override(ERC721Upgradeable, ERC721PausableUpgradeable)
  returns (address)
  {
    return super._update(to, tokenId, auth);
  }

  /**
   * @dev Calculates and returns the metadata for a specific token.
   * @param tokenId The `tokenId` for this token.
   * @return string The metadata for a specific token.
   */
  function tokenURI(uint256 tokenId)
  public
  view
  override(ERC721Upgradeable)
  returns (string memory)
  {
    require(tokenId <= _tokenIdCounter, "TokenId does not exist");

    bytes memory svg = abi.encodePacked(
      renderer.drawPalette(_palettes[tokenId])
    );
    bytes memory metadata = abi.encodePacked(
      '{',
      '"name": "Palettes ', Utils.uint2str(tokenId), '",',
      '"description": "8 Color Palette.",',
      '"image": ',
      '"data:image/svg+xml;base64,',
      Base64.encode(svg),
      '",',
      '"animation_url": ',
      '"data:text/html;base64,',
      Base64.encode(
        "generateHTML"
      ),
      '",',
      '"attributes": [',attributes(tokenId) , ']',
      '}'
    );

    return string(
      abi.encodePacked(
        "data:application/json;base64,",
        Base64.encode(metadata)
      )
    );
  }

  /**
   * @dev Generate the SVG snipped for a for all attributes.
   * @param tokenId The `tokenId` for this token.
   * @return bytes The SVG snippet for the attributes.
   * @notice Code snippet based on Checks - ChecksMetadata.sol {author: Jalil.eth}
   */
  function attributes(uint256 tokenId) private view returns(bytes memory) {
    require(tokenId <= _tokenIdCounter, "TokenId does not exist");
    return abi.encodePacked(
      trait("Color 1", renderer.webPalette(_palettes[tokenId])[0], ","),
      trait("Color 2", renderer.webPalette(_palettes[tokenId])[1], ","),
      trait("Color 3", renderer.webPalette(_palettes[tokenId])[2], ","),
      trait("Color 4", renderer.webPalette(_palettes[tokenId])[3], ","),
      trait("Color 5", renderer.webPalette(_palettes[tokenId])[4], ","),
      trait("Color 6", renderer.webPalette(_palettes[tokenId])[5], ","),
      trait("Color 7", renderer.webPalette(_palettes[tokenId])[6], ","),
      trait("Color 8", renderer.webPalette(_palettes[tokenId])[7], "")
    );
  }

  /// @dev Generate the SVG snipped for a single attribute.
  /// @param traitType The `trait_type` for this trait.
  /// @param traitValue The `value` for this trait.
  /// @param append Helper to append a comma.
  /// @return string The SVG snippet for the attribute.
  /// @notice Code snippet from Checks - ChecksMetadata.sol {author: Jalil.eth}
  function trait(
    string memory traitType, string memory traitValue, string memory append
  ) public pure returns (string memory) {
    return string(abi.encodePacked(
      '{',
        '"trait_type": "', traitType, '",'
        '"value": "', traitValue, '"'
      '}',
      append
    ));
  }

  function supportsInterface(bytes4 interfaceId)
  public
  view
  override(ERC721Upgradeable)
  returns (bool)
  {
    return super.supportsInterface(interfaceId);
  }
}