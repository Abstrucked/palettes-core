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
        return IPalettes.RGBColor(getColorComponentRed(col), getColorComponentGreen(col), getColorComponentBlue(col));
    }

     function getBasePalette(bytes32 _seed) 
        internal 
        pure 
        returns (IPalettes.RGBPalette memory)
    {
        IPalettes.RGBPalette memory palette;
        IPalettes.RGBColor memory base = getBaseColor(_seed);
        IPalettes.RGBColor memory complementary = IPalettes.RGBColor(
            (255 - getBaseColor(_seed).r),
            (255 - getBaseColor(_seed).g),
            (255 - getBaseColor(_seed).b)  
        );

        // Set Base Color
        palette.colors[0] = base;
        // Base Right Spectrum
        palette.colors[1] = IPalettes.RGBColor(
            (getBaseColor(_seed).b),
            (getBaseColor(_seed).r),
            (getBaseColor(_seed).g)  
        );

        palette.colors[2] = IPalettes.RGBColor(
            (255 - getBaseColor(_seed).r),
            (255 - getBaseColor(_seed).g),
            (255 - getBaseColor(_seed).b)  
        );
        
        // Base Left Spectrum
        palette.colors[3] = IPalettes.RGBColor(
            (getBaseColor(_seed).g),
            (getBaseColor(_seed).r),
            (getBaseColor(_seed).b)  
        );
        // Base Right Spectrum
        palette.colors[4] = IPalettes.RGBColor(
            (complementary.b),
            (complementary.r),
            (complementary.g)  
        );
        // Base Left Spectrum
        palette.colors[5] = IPalettes.RGBColor(
            (complementary.g),
            (complementary.r),
            (complementary.b)  
        );
        // Dark
        palette.colors[6] = IPalettes.RGBColor(
            ((getBaseColor(_seed).r/5)),
            ((getBaseColor(_seed).g/5)),
            ((getBaseColor(_seed).b/5))
        );
        // Light
        palette.colors[7] = IPalettes.RGBColor(
            (255-(complementary.r/3)),
            (255-(complementary.r/3)),
            (255-(complementary.r/3))
        );
        return palette;
    }

    function getHex(IPalettes.RGBColor memory rgb)
        internal 
        pure 
        returns(string memory) 
    {
        string[3] memory  color;
        color[0] = string(Utils.uintToHex(rgb.r));
        color[1] = string(Utils.uintToHex(rgb.g));
        color[2] = string(Utils.uintToHex(rgb.b));
        // Add leading 0 if needed
        bytes(color[0]).length == 1 ? string.concat(color[0], "0") : "";
        bytes(color[1]).length == 1 ? string.concat(color[1], "0") : "";
        bytes(color[2]).length == 1 ? string.concat(color[2], "0") : "";
    return  string.concat("#", color[0], color[1], color[2]);
    } 

    function webPalette(bytes32 seed)
        internal 
        pure
        returns (IPalettes.WebPalette memory)
    {
//        IPalettes.RGBPalette memory rgbPalette = getBasePalette(seed);

        return IPalettes.WebPalette(
            [
                getHex(getBasePalette(seed).colors[0]),
                getHex(getBasePalette(seed).colors[1]),
                getHex(getBasePalette(seed).colors[2]),
                getHex(getBasePalette(seed).colors[3]),
                getHex(getBasePalette(seed).colors[4]),
                getHex(getBasePalette(seed).colors[5]),
                getHex(getBasePalette(seed).colors[6]),
                getHex(getBasePalette(seed).colors[7])
            ]
        );

    }

    function svgColors(bytes32 seed)
        private 
        pure
        returns (string memory) 
    {

        uint256 HEIGHT = SIZE/getBasePalette(seed).colors.length;
        string memory renderSvg;
        for(uint256 i=0; i<getBasePalette(seed).colors.length; i++) {
            renderSvg = string.concat(
                renderSvg,
                '<circle cy="',
                    Utils.uint2str(SIZE/getBasePalette(seed).colors.length),
                    '" cx="',
                    Utils.uint2str(i*HEIGHT+HEIGHT/2),
                    '" r="',
                    Utils.uint2str(HEIGHT/2-1),
                    '" fill="rgb(',
                    string.concat(
                        Utils.uint2str(getBasePalette(seed).colors[i].r),
                        ",",
                        Utils.uint2str(getBasePalette(seed).colors[i].g),
                        ",",
                        Utils.uint2str(getBasePalette(seed).colors[i].b)
                    ), ')"></circle>'
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
