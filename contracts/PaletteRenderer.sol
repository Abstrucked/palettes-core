// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
import "@openzeppelin/contracts/utils/Strings.sol";
import "../libraries/Utils.sol";
import {Colors} from "../libraries/Colors.sol";
//import { IPaletteRenderer } from "./interfaces/IPaletteRenderer.sol";
import { IPalettes } from "./interfaces/IPalettes.sol";

library PaletteRenderer {
    uint256 private constant SIZE = 1024;

    function generateUintColor(bytes32 seed)
        private
        pure
        returns (uint256)
    {
        return uint256(keccak256(abi.encodePacked(seed))) % 524288;
    }



    function getColorComponentRed(uint256 value)
        internal
        pure
        returns (uint8)
    {
        return uint8((value >> 8) & 0xff);
    }

    function getColorComponentGreen(uint256 value)
        internal
        pure
        returns (uint8)
    {
        return uint8((value >> 4) & 0xff);
    }

    function getColorComponentBlue(uint256 value)
        internal
        pure
        returns (uint8)
    {
        return uint8(value & 0xff);
    }

    /**
     * @param seed of the token 
     * @return value of 'number'
     */
    function getBaseColor(bytes32 seed)
        internal 
        pure 
        returns (IPalettes.RGBColor memory)
    {
        uint256 col = generateUintColor(bytes32(seed));
        return IPalettes.RGBColor(
            Colors.packRGB(
                getColorComponentRed(col),
                getColorComponentGreen(col),
                getColorComponentBlue(col)
            )
        );
    }

     function getBasePalette(bytes32 _seed) 
        internal 
        pure 
        returns (uint192)
    {
        uint24[8] memory palette; // tmp storage

        // Unpacked color placeholders
        uint8 r;
        uint8 g;
        uint8 b;

        // Get unpacked base color.
        (r,g,b) = Colors.unpackRGB(getBaseColor(_seed).value);
        uint8 cr = 255 - r;
        uint8 cg = 255 - g;
        uint8 cb = 255 - b;

        return Colors.packPalette(
            [
                getBaseColor(_seed).value,
                Colors.packRGB(b, r, g),
                Colors.packRGB(g, r, b),
                Colors.packRGB(cr, cg, cb),
                Colors.packRGB(cb, cr, cg),
                Colors.packRGB(cg, cr, cb),
                Colors.packRGB((r/5),(g/5),(b/5)),
                Colors.packRGB((255-(cr/3)),(255-(cg/3)),(255-(cb/3)))
            ]
        );

//        // Set Base Color
//        palette[0] = getBaseColor(_seed).value;
//        // Base Right Spectrum
//        palette[1] = Colors.packRGB(b, r, g);
//        // Base Left Spectrum
//        palette[3] = Colors.packRGB(g, r, b);
//        // Dark
//        palette[6] = Colors.packRGB((r/5),(g/5),(b/5));
//        // Complementary Color
//        palette[2] = Colors.unpackRGB(cr, cg, cb);
//        // Complementary Right Spectrum
//        palette[4] = Colors.packRGB(cb, cr, cg);
//        // Complementary Left Spectrum
//        palette[5] = Colors.packRGB(cg, cr, cb);
//        // Light
//        palette[7] = Colors.packRGB((255-(cr/3)),(255-(cg/3)),(255-(cb/3)));
//        return IPalettes.RGBPalette(Colors.packPalette(palette));
    }

    function getHex(uint24 rgb)
        internal 
        pure 
        returns(string memory) 
    {

        bytes memory hexChars = "0123456789ABCDEF";

        bytes memory hexString = new bytes(7);
        hexString[0] = '#';

        for (uint i = 0; i < 3; i++) {
        hexString[2*i + 1] = hexChars[uint8(rgb >> (i*8 + 4)) & 0x0f];
        hexString[2*i + 2] = hexChars[uint8(rgb >> (i*8)) & 0x0f];
        }

        return string(hexString);
    }

    function webPalette(bytes32 seed)
        internal 
        pure
        returns (string[8] memory)
    {
        uint192 rgbPalette = getBasePalette(seed);
        return
            [
                getHex(Colors.unpackPaletteAt(rgbPalette,0)),
                getHex(Colors.unpackPaletteAt(rgbPalette,1)),
                getHex(Colors.unpackPaletteAt(rgbPalette,2)),
                getHex(Colors.unpackPaletteAt(rgbPalette,3)),
                getHex(Colors.unpackPaletteAt(rgbPalette,4)),
                getHex(Colors.unpackPaletteAt(rgbPalette,5)),
                getHex(Colors.unpackPaletteAt(rgbPalette,6)),
                getHex(Colors.unpackPaletteAt(rgbPalette,7))
            ];


    }

    function svgColors(bytes32 seed)
        private 
        pure
        returns (string memory) 
    {
        uint192 palette = getBasePalette(seed);
        uint256 HEIGHT = SIZE/8;
        string memory renderSvg;
        for(uint8 i=0; i<8; i++) {
            renderSvg = string.concat(
                renderSvg,
                '<circle cy="',
                    Utils.uint2str(HEIGHT),
                    '" cx="',
                    Utils.uint2str((i*HEIGHT)+(HEIGHT/2)),
                    '" r="',
                    Utils.uint2str((HEIGHT/2)-1),
                    '" fill="',
                    getHex(Colors.unpackPaletteAt(palette, i)),
                '"></circle>'
            );
        }
        return renderSvg;
    }

    function drawPalette(bytes32 _seed) 
        internal 
        pure 
        returns (string memory)
    {
        return string.concat(
              '<svg width="',
              Utils.uint2str(SIZE),
              '" height="',
              Utils.uint2str(SIZE/4),
              '" viewBox="0 0 ',
              Utils.uint2str(SIZE),
              " ",
              Utils.uint2str(SIZE/4),
              '" xmlns="http://www.w3.org/2000/svg">', svgColors(_seed), "</svg>");
    }
}
