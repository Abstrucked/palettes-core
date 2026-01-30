// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import {IUsePalette} from "./interfaces/IUsePalette.sol";
import {IManager} from "./interfaces/IManager.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";

/**
 * @title UsePalette
 * @dev Contract for managing palettes associated with token IDs.
 * Author: Abstrucked.eth
 */
contract UsePalette is IUsePalette, ERC165 {
    /// @dev Address of the palette manager contract
    address private _paletteManager;

    /**
     * @notice Constructor to set the palette manager address.
     * @param paletteManager address The address of the palette manager contract.
     */
    constructor(address paletteManager) {
        _paletteManager = paletteManager;
    }

    /**
     * @notice Get the current nonce for an address from the PaletteManager.
     * @dev Helper function to simplify frontend integration - no need to call PaletteManager directly.
     * @param account address The address to check.
     * @return uint256 The current nonce for the account.
     */
    function getNonce(address account) external view returns (uint256) {
        return IManager(_paletteManager).getNonce(account);
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
        IManager(_paletteManager).setPaletteRecord(
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
        return IManager(_paletteManager).getPalette(tokenId);
    }

    /**
     * @notice Get the palette for a given token ID.
     * @param tokenId uint256 The ID of the token.
     * @return string[8] An array of strings representing the palette.
     */
    function getRGBPalette(
        uint256 tokenId
    ) public view returns (uint24[8] memory) {
        return IManager(_paletteManager).getRGBPalette(tokenId);
    }

    /**
     * @notice Check if a palette is set for a given token ID.
     * @param tokenId uint256 The ID of the token.
     * @return bool A boolean indicating if the palette is set.
     */
    function isPaletteSet(uint256 tokenId) external view returns (bool) {
        return
            IManager(_paletteManager).getPaletteId(tokenId, address(this)) > 0;
    }

    /**
     * @notice Get the palette ID set for a given token ID.
     * @param tokenId uint256 The ID of the token.
     * @return uint256 The ID of the set palette.
     */
    function getSetPaletteId(uint256 tokenId) external view returns (uint256) {
        return IManager(_paletteManager).getPaletteId(tokenId, address(this));
    }

    /**
     * @notice Check if the contract supports an interface.
     * @param interfaceId bytes4 The interface ID to check.
     * @return bool A boolean indicating if the interface is supported.
     */
    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(ERC165) returns (bool) {
        return
            interfaceId == type(IUsePalette).interfaceId ||
            super.supportsInterface(interfaceId);
    }
}
