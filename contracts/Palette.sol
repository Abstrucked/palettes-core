// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

// import "./ColorConverter.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
// import "solidity-bytes-utils/contracts/BytesLib.sol";

import "../libraries/Utils.sol";

import "./PaletteRenderer.sol";

contract Palette is ERC721, Ownable {
  error MaxSupplyReached();
  error IdNotFound();
  uint256 private _tokenIdCounter;
  
  uint256 MAX_SUPPLY = 10000;
  
  mapping(uint256 => bytes32) private _palettes;
  
  PaletteRenderer public renderer;
  
  constructor(PaletteRenderer _renderer)
    ERC721("Palettes", "PAL")
    Ownable(msg.sender)
  {
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
    return renderer.getBasePalette(_palettes[_tokenId]);
  }

  function webPalette(uint256 _tokenId) public view returns (string[8] memory) {
    require(_tokenId <= _tokenIdCounter, "TokenId does not exist");
    return  renderer.webPalette(_palettes[_tokenId]);
  }
  
  function image(uint256 _tokenId) public view returns(string memory) {
    require(_tokenId <= _tokenIdCounter, "TokenId does not exist");
    return renderer.drawPalette(_palettes[_tokenId]);
  }

}