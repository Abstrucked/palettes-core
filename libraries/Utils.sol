// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
import "@openzeppelin/contracts/utils/Strings.sol";
library Utils {

    function random(string memory input) internal pure returns (uint256){
        return  uint256(keccak256(abi.encodePacked(input)));
    }

    function randomBytes32(string memory input) internal pure returns (bytes32){
        return  bytes32(keccak256(abi.encodePacked(input)));
    }

    function randomRange(
        uint256 tokenId,
        string memory keyPrefix,
        uint256 lower,
        uint256 upper
    ) internal pure returns (uint256) {
        uint256 rand = random(string(abi.encodePacked(keyPrefix, Strings.toString(tokenId))));
        return (rand % (upper - lower)) + lower;
    }


    /**
       * Inspired by Java code - unknown url but will find later
       * Converts a decimal value to a hex value without the #
       */
    function uintToHex (uint256 decimalValue) pure internal returns (bytes memory) {
        uint remainder;
        bytes memory hexResult = "";
        string[16] memory hexDictionary = ["0", "1", "2", "3", "4", "5", "6", "7", "8", "9", "A", "B", "C", "D", "E", "F"];

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
        } else if (len == 4) {
            hexResult = abi.encodePacked("0000", hexResult);
        }

        return hexResult;
    }


    // converts an unsigned integer to a string
    function uint2str(uint256 _i) internal pure returns (string memory _uintAsString) {
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

    function packRGB(uint8 r, uint8 g, uint8 b) internal pure returns (uint24) {
        return uint24(r) << 16 | uint24(g) << 8 | uint24(b);
    }

    function unpackRGB(uint24 color) internal pure returns (uint8 r, uint8 g, uint8 b) {
        r = uint8(color >> 16);
        g = uint8(color >> 8);
        b = uint8(color);

        return(r, g, b);
    }

    function packPalette(uint24[8] memory values) internal pure returns (uint192 packed) {
        for (uint i = 0; i < 8; i++) {
            packed |= uint192(values[i]) << (24 * i);
        }
    }

    function unpackPalette(uint192 packed) internal pure returns (uint24[8] memory values) {
        for (uint i = 0; i < 8; i++) {
            values[i] = uint24(packed >> (24 * i));
        }
    }
    function unpackPaletteAt(uint192 packed, uint8 index) internal pure returns (uint24) {
        return uint24(packed >> (24 * index));
    }
}