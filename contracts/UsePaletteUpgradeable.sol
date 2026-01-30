// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import {IManager} from "./interfaces/IManager.sol";
import {IUsePalette} from "./interfaces/IUsePalette.sol";
import {ERC165Upgradeable} from "@openzeppelin/contracts-upgradeable/utils/introspection/ERC165Upgradeable.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

/**
 * @title UsePaletteUpgradeable
 * @dev Abstract contract for managing palettes associated with token IDs.
 * Inherits from Initializable, IUsePalette, and ERC165Upgradeable.
 * Author: Abstrucked.eth
 */
abstract contract UsePaletteUpgradeable is
    Initializable,
    IUsePalette,
    ERC165Upgradeable
{
    // keccak256(abi.encode(uint256(keccak256("abstrucked.palettes.UsePalettes")) - 1)) & ~bytes32(uint256(0xff))
    bytes32 private constant UsePaletteStorageLocation =
        0x5e5e01030d43f956a4f78c931500ee10bc240d7c37ba5155e6f49067079dd500;

    /// @dev Storage structure for UsePaletteUpgradeable
    struct UsePaletteStorage {
        address _paletteManager;
    }

    /**
     * @dev Private pure function to get the storage struct.
     * @return $ Storage reference for UsePaletteStorage.
     */
    function _getUsePaletteStorage()
        private
        pure
        returns (UsePaletteStorage storage $)
    {
        assembly {
            $.slot := UsePaletteStorageLocation
        }

        return $;
    }

    /**
     * @dev Initializer for UsePaletteUpgradeable.
     * @param paletteManager address The address of the palette manager contract.
     */
    function __UsePalette_init(
        address paletteManager
    ) internal onlyInitializing {
        __UsePalette_init_unchained(paletteManager);
    }

    /**
     * @dev Unchained initializer for UsePaletteUpgradeable.
     * @param paletteManager address The address of the palette manager contract.
     */
    function __UsePalette_init_unchained(
        address paletteManager
    ) internal onlyInitializing {
        UsePaletteStorage storage s = _getUsePaletteStorage();
        s._paletteManager = paletteManager;
    }

    /**
     * @notice Get the current nonce for an address from the PaletteManager.
     * @dev Helper function to simplify frontend integration - no need to call PaletteManager directly.
     * @param account address The address to check.
     * @return uint256 The current nonce for the account.
     */
    function getNonce(address account) external view returns (uint256) {
        UsePaletteStorage storage s = _getUsePaletteStorage();
        return IManager(s._paletteManager).getNonce(account);
    }

    /**
     * @notice Set a palette for a given token ID.
     * @param tokenId uint256 The ID of the token.
     * @param paletteId uint256 The ID of the palette.
     * @param nonce uint256 The nonce for replay protection.
     * @param deadline uint256 Optional deadline timestamp (0 for no deadline).
     * @param signature bytes The signature to authorize the palette setting.
     */
    function setPalette(
        uint256 tokenId,
        uint256 paletteId,
        uint256 nonce,
        uint256 deadline,
        bytes calldata signature
    ) public {
        UsePaletteStorage storage s = _getUsePaletteStorage();
        IManager(s._paletteManager).setPaletteRecord(
            paletteId,
            address(this),
            tokenId,
            nonce,
            deadline,
            signature
        );
    }

    /**
     * @notice Get the palette for a given token ID.
     * @param tokenId uint256 The ID of the token.
     * @return string[8] An array of strings representing the palette.
     */
    function getPalette(
        uint256 tokenId
    ) public view returns (string[8] memory) {
        UsePaletteStorage storage s = _getUsePaletteStorage();
        return IManager(s._paletteManager).getPalette(tokenId);
    }

    /**
     * @notice Get the palette for a given token ID.
     * @param tokenId uint256 The ID of the token.
     * @return string[8] An array of strings representing the palette.
     */
    function getRGBPalette(
        uint256 tokenId
    ) public view returns (uint24[8] memory) {
        UsePaletteStorage storage s = _getUsePaletteStorage();
        return IManager(s._paletteManager).getRGBPalette(tokenId);
    }

    /**
     * @notice Check if a palette is set for a given token ID.
     * @param tokenId uint256 The ID of the token.
     * @return bool A boolean indicating if the palette is set.
     */
    function isPaletteSet(uint256 tokenId) public view returns (bool) {
        UsePaletteStorage storage s = _getUsePaletteStorage();
        return
            IManager(s._paletteManager).getPaletteId(tokenId, address(this)) >
            0;
    }

    /**
     * @notice Get the palette ID set for a given token ID.
     * @param tokenId uint256 The ID of the token.
     * @return uint256 The ID of the set palette.
     */
    function getSetPaletteId(uint256 tokenId) public view returns (uint256) {
        UsePaletteStorage storage s = _getUsePaletteStorage();
        return IManager(s._paletteManager).getPaletteId(tokenId, address(this));
    }

    /**
     * @notice Check if the contract supports an interface.
     * @param interfaceId bytes4 The interface ID to check.
     * @return bool A boolean indicating if the interface is supported.
     */
    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override returns (bool) {
        return
            interfaceId == type(IUsePalette).interfaceId ||
            super.supportsInterface(interfaceId);
    }
}
