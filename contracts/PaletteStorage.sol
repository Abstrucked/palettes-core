// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {EIP712Upgradeable} from "@openzeppelin/contracts-upgradeable/utils/cryptography/EIP712Upgradeable.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {PaletteManager} from "./PaletteManager.sol";
import {IPalettes} from "./interfaces/IPalettes.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {console} from "hardhat/console.sol";
import {IStorage} from "./interfaces/IStorage.sol";
import {IManager} from "./interfaces/IManager.sol";
import {IERC165} from "@openzeppelin/contracts/interfaces/IERC165.sol";

/**
 * @title PaletteStorage
 * @dev Contract for managing palette storage and records.
 * Inherits from IStorage, UUPSUpgradeable, OwnableUpgradeable, and EIP712Upgradeable.
 * Author: Abstrucked.eth
 */
contract PaletteStorage is IStorage, UUPSUpgradeable, OwnableUpgradeable, EIP712Upgradeable {
    /// @dev Mapping from hash to palette ID
    mapping(bytes32 => uint256) private _hashToPaletteId;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    /**
     * @notice Initializes the contract with the given owner.
     * @param initialOwner address The address of the initial owner.
     */
    function initialize(address initialOwner) public initializer {
        __Ownable_init(initialOwner);
        __UUPSUpgradeable_init();
        __EIP712_init("PaletteStorage", "1");
    }

    /**
     * @notice Authorizes an upgrade to the new implementation.
     * @param newImplementation address The address of the new implementation.
     */
    function _authorizeUpgrade(address newImplementation) internal onlyOwner override {}

    /**
     * @dev Sets a palette record.
     * @param paletteId uint256 The palette ID.
     * @param _contractAddress address The contract address associated with the palette.
     * @param _tokenId uint256 The token ID associated with the palette.
     */
    function _setPaletteRecord(uint256 paletteId, address _contractAddress, uint256 _tokenId) private {
        _hashToPaletteId[keccak256(abi.encode(PaletteRecord(_contractAddress, _tokenId)))] = paletteId;
        emit PaletteRecordSet(paletteId, _contractAddress, _tokenId);
    }

    /**
     * @notice Sets a palette record with a signature.
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
        require(IERC165(msg.sender).supportsInterface(type(IManager).interfaceId), "Caller does not support IManager");
        console.log("setPaletteRecord");
        console.logBytes32(keccak256(abi.encode(PaletteRecord(_contractAddress, _tokenId))));
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
        console.log("log manager %s %s", msg.sender, signer, paletteId);
        console.log("isOwner %s", IManager(msg.sender).isPaletteOwner(paletteId, signer));
        if (!IManager(msg.sender).isPaletteOwner(paletteId, signer)) {
            revert("Not the owner of the token");
        }
        _setPaletteRecord(paletteId, _contractAddress, _tokenId);
    }

    /**
     * @notice Gets the palette ID for a given token ID and contract address.
     * @param tokenId uint256 The token ID.
     * @param contractAddress address The contract address.
     * @return uint256 The palette ID.
     */
    function getPaletteId(uint256 tokenId, address contractAddress) external view returns (uint256) {
        /// check for gas efficiency here declare/re-call function.
        uint256 paletteId = _getPaletteId(tokenId, contractAddress);
        console.log("Palette Id", paletteId);
        if (paletteId == 0) {
            revert("Palette not found");
        }
        return paletteId;
    }

    /**
     * @dev Gets the palette ID for a given token ID and contract address.
     * @param tokenId uint256 The token ID.
     * @param _contractAddress address The contract address.
     * @return uint256 The palette ID.
     */
    function _getPaletteId(uint256 tokenId, address _contractAddress) private view returns (uint256) {
        return _hashToPaletteId[
            keccak256(
                abi.encode(
                    PaletteRecord(
                        _contractAddress,
                        tokenId
                    )
                )
            )
            ];
    }
}