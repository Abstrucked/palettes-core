// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;
import "@openzeppelin/contracts/utils/Strings.sol";
import "../libraries/Utils.sol";

contract PaletteRenderer {
    
    uint256 private constant SIZE = 1024;

    struct Color {
        uint8 r;
        uint8 g;
        uint8 b;
    }

    function generateColor(bytes32 seed) 
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
    function getRGB(bytes32 seed) 
        public 
        pure 
        returns (uint8[3] memory)
    {
        uint256 col = generateColor(bytes32(seed));
        return [getColorComponentRed(col), getColorComponentGreen(col), getColorComponentBlue(col)];
    }

     function getBasePalette(bytes32 _seed) 
        public 
        pure 
        returns (Color[8] memory)
    {
        Color[8] memory palette;
        uint256 baseColor = generateColor( _seed);
        Color memory base = Color( 
            getColorComponentRed(baseColor), 
            getColorComponentGreen(baseColor), 
            getColorComponentBlue(baseColor)
        );
        Color memory complementary = Color(
            (255 - base.r),
            (255 - base.g),
            (255 - base.b)  
        );

        // Main Color
        palette[0] = base;        
        // Base Right Spectrum
        palette[1] = Color(
            (base.b),
            (base.r),
            (base.g)  
        );
        
        palette[2] = Color(
            (255 - base.r),
            (255 - base.g),
            (255 - base.b)  
        );
        
        // Base Left Spectrum
        palette[3] = Color(
            (base.g),
            (base.r),
            (base.b)  
        );
        // Base Right Spectrum
        palette[4] = Color(
            (complementary.b),
            (complementary.r),
            (complementary.g)  
        );
        // Base Left Spectrum
        palette[5] = Color(
            (complementary.g),
            (complementary.r),
            (complementary.b)  
        );
        // Dark
        palette[6] = Color(
            ((base.r/5)),
            ((base.g/5)),
            ((base.b/5))
        );
        // Light
        palette[7] = Color(
            (255-(complementary.r/3)),
            (255-(complementary.r/3)),
            (255-(complementary.r/3))
        );
        return palette;
    }

    function getHex(Color memory rgb) 
        public
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
        public
        pure
        returns (string[8] memory)
    {
        string[8] memory hexPalette;
        Color[8] memory rgbPalette = getBasePalette(seed);
        hexPalette[0] = getHex(rgbPalette[0]);
        hexPalette[1] = getHex(rgbPalette[1]);
        hexPalette[2] = getHex(rgbPalette[2]);
        hexPalette[3] = getHex(rgbPalette[3]);
        hexPalette[4] = getHex(rgbPalette[4]);
        hexPalette[5] = getHex(rgbPalette[5]);
        hexPalette[6] = getHex(rgbPalette[6]);
        hexPalette[7] = getHex(rgbPalette[7]);
        
        return hexPalette;
    }

    function svgColors(bytes32 seed)
        private 
        pure
        returns (string memory) 
    {
        Color[8] memory palette = getBasePalette(seed);
        string memory colorTuple;
        uint256 HEIGHT = SIZE/palette.length;
        string memory renderSvg;
        for(uint256 i=0; i<palette.length; i++) {
            colorTuple = string.concat(
                Utils.uint2str(palette[i].r),
                ",",
                Utils.uint2str(palette[i].g),
                ",",
                Utils.uint2str(palette[i].b)
              );
            renderSvg = string.concat(
                renderSvg,
                '<circle cy="',
                    Utils.uint2str(SIZE/palette.length),
                    '" cx="',
                    Utils.uint2str(i*HEIGHT+HEIGHT/2),
                    '" r="',
                    Utils.uint2str(HEIGHT/2-1),
                    '" fill="rgb(',
                    colorTuple,
                    ')"></circle>'
                );
        }
        return renderSvg;
    }

    function drawPalette(bytes32 _seed) 
        public 
        pure 
        returns (string memory) {
        string memory renderSvg = string.concat(
            '<svg width="',
            Utils.uint2str(SIZE),
            '" height="',
            Utils.uint2str(SIZE/4),
            '" viewBox="0 0 ',
            Utils.uint2str(SIZE),
            " ",
            Utils.uint2str(SIZE/4),
            '" xmlns="http://www.w3.org/2000/svg">'
          );

          renderSvg = string.concat(renderSvg, svgColors(_seed), "</svg>");

          return renderSvg;
    }
}
