// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

// import "./ColorConverter.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721BurnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
// import "solidity-bytes-utils/contracts/BytesLib.sol";

import "../libraries/Utils.sol";

import "./PaletteRenderer.sol";

contract Palettes is Initializable, ERC721Upgradeable, ERC721PausableUpgradeable, OwnableUpgradeable, ERC721BurnableUpgradeable{
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

  function generateSeed(uint256 _tokenId) private view returns (bytes32){
    require(_tokenId <= _tokenIdCounter, "TokenId does not exist");
    return Utils.randomBytes32(string(abi.encode(block.timestamp, msg.sender, (_tokenId))));
  }

  function getSeed(uint256 _tokenId) external view returns (bytes32){
    if(_tokenId > _tokenIdCounter) {
      revert IdNotFound();
    }
    return _palettes[_tokenId];
  }

  function rgbPalette(uint256 _tokenId) public view returns (PaletteRenderer.Color[8] memory) {
    require(_tokenId <= _tokenIdCounter, "TokenId does not exist");
    require(ownerOf(_tokenId) == msg.sender, "Not the owner of the token");

    return renderer.getBasePalette(_palettes[_tokenId]);
  }

  function webPalette(uint256 _tokenId) public view returns (string[8] memory) {
    require(_tokenId <= _tokenIdCounter, "TokenId does not exist");
    require(ownerOf(_tokenId) == msg.sender, "Not the owner of the token");

    return  renderer.webPalette(_palettes[_tokenId]);
  }
  
  function image(uint256 _tokenId) public view returns(string memory) {
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

  function tokenURI(uint256 tokenId)
  public
  view
  override(ERC721Upgradeable)
  returns (string memory)
  {
    return super.tokenURI(tokenId);
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