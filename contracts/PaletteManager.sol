// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {EIP712Upgradeable} from "@openzeppelin/contracts-upgradeable/utils/cryptography/EIP712Upgradeable.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {IPaletteManager} from "./interfaces/IPaletteManager.sol";
import {IPalettes} from "./interfaces/IPalettes.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {console} from "hardhat/console.sol";


contract PaletteManager is IPaletteManager, UUPSUpgradeable, OwnableUpgradeable, EIP712Upgradeable {
    address private palettesContract;

    struct PaletteRecord {
        address contractAddress;
        uint256 tokenId;
    }

    mapping(uint256 => PaletteRecord) private _records;
    mapping(bytes => uint256) private _recordReverse;
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(address initialOwner, address contractAddress) initializer public {
        __Ownable_init(initialOwner);
        __UUPSUpgradeable_init();
        __EIP712_init("PaletteManager", "1");
        palettesContract = contractAddress;
    }

    function _authorizeUpgrade(address newImplementation)
    internal
    onlyOwner
    override
    {}

    function _setPaletteRecord(uint256 paletteId, address _contractAddress, uint256 _tokenId) internal {
//        _records[paletteId] = PaletteRecord(_contractAddress, _tokenId);
        _recordReverse[abi.encode(PaletteRecord(_contractAddress, _tokenId))] = paletteId;
        emit PaletteRecordSet(paletteId, _contractAddress, _tokenId);
    }

    function setPaletteRecord(
        uint256 paletteId,
        address _contractAddress,
        uint256 _tokenId,
        bytes calldata signature
    ) external returns (bool) {
        console.log("setPaletteRecord");
        console.log(bytes(abi.encode(PaletteRecord(_contractAddress, _tokenId))).length);
        address signer = ECDSA.recover(
            _hashTypedDataV4(
                keccak256(
                    abi.encode(
                        keccak256("PaletteRecord(uint256 paletteId,address contractAddress,uint256 tokenId)"),
                        paletteId,
                        _contractAddress,
                        _tokenId
                    )
                )
            ),
            signature
        );
        console.log(" Signer, Owner ");
        console.log(signer, IERC721(palettesContract).ownerOf(paletteId));
        if (signer != IERC721(palettesContract).ownerOf(paletteId) ) {
            revert("Not the owner of the token");
        }
        _setPaletteRecord(paletteId, _contractAddress, _tokenId);
        return true;

    }

    function getPaletteRecord(uint256 tokenId, address contractAddress) external view returns ( uint256){
        console.log("GET_PALETTE::MSG_SENDER", msg.sender);
        uint256 paletteId = _recordReverse[abi.encode(PaletteRecord(contractAddress, tokenId))];
        console.log("GET_PALETTE::PALETTE_ID", paletteId);

        require(paletteId > 0, "Palette not found");
        return (paletteId);
    }

    function getWebPalette(uint256 tokenId, address _contractAddress) external view returns (string[8] memory){
        uint256 paletteId = _recordReverse[abi.encode(PaletteRecord(_contractAddress, tokenId))];
        require(paletteId > 0, "Palette not found");
        return IPalettes(palettesContract).webPalette(paletteId);
    }
}
