// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/utils/Strings.sol";

/// @title Utils Library
/// @dev Collection of utility functions for various conversions and randomizations.
library Utils {
    /**
     * @notice Converts a bytes32 value to a uint256 by hashing it and taking a modulus.
     * @param seed The bytes32 value to convert.
     * @return uint256 The converted uint256 value.
     */
    function bytes32toUint(bytes32 seed) internal pure returns (uint256) {
        return uint256(keccak256(abi.encodePacked(seed))) % 524288;
    }

    /**
     * @notice Generates a pseudo-random uint256 based on the input string.
     * @param input string The input string to hash.
     * @return uint256 The pseudo-random uint256 value.
     */
    function random(string memory input) internal pure returns (uint256) {
        return uint256(keccak256(abi.encodePacked(input)));
    }

    /**
     * @notice Generates a pseudo-random bytes32 based on the input string.
     * @param input The input string to hash.
     * @return bytes32 The pseudo-random bytes32 value.
     */
    function randomBytes32(
        string memory input
    ) internal pure returns (bytes32) {
        return bytes32(keccak256(abi.encodePacked(input)));
    }

    /**
     * @notice Generates a pseudo-random number within a specified range based on a token ID and a key prefix.
     * @param tokenId The token ID to use as part of the randomization.
     * @param keyPrefix The prefix to use in the randomization process.
     * @param lower The lower bound of the range.
     * @param upper The upper bound of the range.
     * @return uint256 The pseudo-random number within the specified range.
     */
    function randomRange(
        uint256 tokenId,
        string memory keyPrefix,
        uint256 lower,
        uint256 upper
    ) internal pure returns (uint256) {
        uint256 rand = random(
            string(abi.encodePacked(keyPrefix, Strings.toString(tokenId)))
        );
        return (rand % (upper - lower)) + lower;
    }

    /**
     * @notice Converts a decimal value to a hexadecimal string.
     * @param decimalValue The decimal value to convert.
     * @return bytes The hexadecimal representation of the decimal value.
     * @dev Inspired by Java code.
     */
    function uintToHex(
        uint256 decimalValue
    ) internal pure returns (bytes memory) {
        uint remainder;
        bytes memory hexResult = "";
        string[16] memory hexDictionary = [
            "0",
            "1",
            "2",
            "3",
            "4",
            "5",
            "6",
            "7",
            "8",
            "9",
            "A",
            "B",
            "C",
            "D",
            "E",
            "F"
        ];

        while (decimalValue > 0) {
            remainder = decimalValue % 16;
            string memory hexValue = hexDictionary[remainder];
            hexResult = abi.encodePacked(hexValue, hexResult);
            decimalValue = decimalValue / 16;
        }

        // Account for missing leading zeros
        uint len = hexResult.length;

        if (len == 5) {
            hexResult = abi.encodePacked("0", hexResult);
        } else if (len == 4) {
            hexResult = abi.encodePacked("00", hexResult);
        } else if (len == 3) {
            hexResult = abi.encodePacked("000", hexResult);
        } else if (len == 2) {
            hexResult = abi.encodePacked("0000", hexResult);
        }

        // Ensure a minimum hex length of 6 for RGB values
        return
            hexResult.length < 6
                ? abi.encodePacked("000000", hexResult)
                : hexResult;
    }

    /**
     * @notice Converts an unsigned integer to a string.
     * @param _i The unsigned integer to convert.
     * @return _uintAsString string The string representation of the unsigned integer.
     */
    function uint2str(
        uint256 _i
    ) internal pure returns (string memory _uintAsString) {
        if (_i == 0) {
            return "0";
        }
        uint256 j = _i;
        uint256 len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint256 k = len;
        while (_i != 0) {
            k = k - 1;
            uint8 temp = (48 + uint8(_i - (_i / 10) * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            _i /= 10;
        }
        return string(bstr);
    }

    function max(uint8 r, uint8 g, uint8 b) internal pure returns (uint8) {
        uint8 _max = r > g ? r : g;

        return _max > b ? _max : g;
    }

    function min(uint8 r, uint8 g, uint8 b) internal pure returns (uint8) {
        uint8 _max = r < g ? r : g;

        return _max < b ? _max : g;
    }
}

