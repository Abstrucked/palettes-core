// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
import "@openzeppelin/contracts/utils/Strings.sol";
import "../libraries/Utils.sol";
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
            Utils.packRGB(
                getColorComponentRed(col),
                getColorComponentGreen(col),
                getColorComponentBlue(col)
            )
        );
    }

     function getBasePalette(bytes32 _seed) 
        internal 
        pure 
        returns (IPalettes.RGBPalette memory)
    {
        uint24[8] memory palette; // tmp storage

        // Unpacked color placeholders
        uint8 r;
        uint8 g;
        uint8 b;

        // Get unpacked base color.
        (r,g,b) = Utils.unpackRGB(getBaseColor(_seed).value);
        palette[2] = Utils.packRGB((255 - r),(255 - g),(255 - b));

        // Set Base Color
        palette[0] = getBaseColor(_seed).value;
        // Base Right Spectrum
        palette[1] = Utils.packRGB(b, r, g);
        // Base Left Spectrum
        palette[3] = Utils.packRGB(g, r, b);
        // Dark
        palette[6] = Utils.packRGB((r/5),(g/5),(b/5));
        // Complementary Color
        (r,g,b) = Utils.unpackRGB(palette[2]);
        // Complementary Right Spectrum
        palette[4] = Utils.packRGB(b, r, g);
        // Complementary Left Spectrum
        palette[5] = Utils.packRGB(g, r, b);
        // Light
        palette[7] = Utils.packRGB((255-(r/3)),(255-(g/3)),(255-(b/3)));
        return IPalettes.RGBPalette(Utils.packPalette(palette));
    }

    function getHex(uint24 rgb)
        internal 
        pure 
        returns(string memory) 
    {
        uint8 r;
        uint8 g;
        uint8 b;
        (r,g,b) = Utils.unpackRGB(rgb);
        return string.concat(
            "#",
            bytes(string(Utils.uintToHex(r))).length == 1 ? string.concat(string(Utils.uintToHex(r)), "0") : "",
            bytes(string(Utils.uintToHex(g))).length == 1 ? string.concat(string(Utils.uintToHex(g)), "0") : "",
            bytes(string(Utils.uintToHex(b))).length == 1 ? string.concat(string(Utils.uintToHex(b)), "0") : ""
        );
    } 

    function webPalette(bytes32 seed)
        internal 
        pure
        returns (string[8] memory)
    {
        uint192 rgbPalette = getBasePalette(seed).colors;
        return
            [
                getHex(Utils.unpackPaletteAt(rgbPalette,0)),
                getHex(Utils.unpackPaletteAt(rgbPalette,1)),
                getHex(Utils.unpackPaletteAt(rgbPalette,2)),
                getHex(Utils.unpackPaletteAt(rgbPalette,3)),
                getHex(Utils.unpackPaletteAt(rgbPalette,4)),
                getHex(Utils.unpackPaletteAt(rgbPalette,5)),
                getHex(Utils.unpackPaletteAt(rgbPalette,6)),
                getHex(Utils.unpackPaletteAt(rgbPalette,7))
            ];


    }

    function svgColors(bytes32 seed)
        private 
        pure
        returns (string memory) 
    {
        uint192 palette = getBasePalette(seed).colors;
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
                    getHex(Utils.unpackPaletteAt(palette, i)),
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
