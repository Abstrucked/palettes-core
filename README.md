# Palettes Protocol

[![License: ISC](https://img.shields.io/badge/License-ISC-blue.svg)](https://opensource.org/licenses/ISC)
[![Solidity](https://img.shields.io/badge/Solidity-^0.8.20-363636?logo=solidity)](https://soliditylang.org/)
[![Hardhat](https://img.shields.io/badge/Built%20with-Hardhat-yellow)](https://hardhat.org/)
[![OpenZeppelin](https://img.shields.io/badge/OpenZeppelin-v5.0-4E5EE4?logo=openzeppelin)](https://openzeppelin.com/)

An advanced NFT protocol for generating unique, deterministic 8-color palettes fully on-chain with cross-contract sharing capabilities.

## Overview

Palettes is an ERC721 protocol that generates procedurally created color palettes as NFTs with complete on-chain SVG rendering. Each palette contains 8 mathematically derived colors from a unique seed, stored permanently on-chain with no external dependencies.

The protocol enables NFT collections to integrate palette functionality, allowing token holders to apply their owned palettes to other NFT projects through cryptographic authorization.

### Key Features

- **Fully On-Chain Generation**: SVG rendering, metadata, and color data all stored on-chain
- **Deterministic Color Derivation**: 8 colors mathematically derived from a single seed
- **Cross-Contract Integration**: Other ERC721 collections can request and use palettes
- **EIP-712 Signature Authorization**: Secure palette ownership verification
- **UUPS Upgradeable**: Future-proof architecture with proxy pattern
- **Gas Optimized**: Efficient color packing and pure function design
- **Whitelist/Discount Support**: Merkle tree-based discount mechanism

## Architecture

The protocol consists of five main contracts:

```
┌─────────────────────────────────────────────────────────────┐
│                      Palettes Ecosystem                     │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  ┌──────────────┐      ┌─────────────────┐                  │
│  │   Palettes   │◄─────│ PaletteRenderer │                  │
│  │   (ERC721)   │      │  (SVG/Colors)   │                  │
│  └──────┬───────┘      └─────────────────┘                  │
│         │              ┌─────────────────┐                  │
│         └─────────────►│PaletteMetadata  │                  │
│         │              │  (JSON/Base64)  │                  │
│         │              └─────────────────┘                  │
│         │                                                   │
│  ┌──────▼──────────┐   ┌─────────────────┐                  │
│  │ PaletteManager  │◄──│ PaletteStorage  │                  │
│  │ (Access Control)│   │  (EIP-712 Sig)  │                  │
│  └─────────┬───────┘   └─────────────────┘                  │
│            │                                                │
│            │                                                │
│  ┌─────────▼──────────────────────────────┐                 │
│  │      External NFT Collections          │                 │
│  │   (inherit UsePalette contract)        │                 │
│  └────────────────────────────────────────┘                 │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

### Core Contracts

| Contract                | Type               | Purpose                                        |
| ----------------------- | ------------------ | ---------------------------------------------- |
| **Palettes.sol**        | Upgradeable ERC721 | Main NFT contract managing palette tokens      |
| **PaletteRenderer.sol** | Pure               | Generates colors, palettes, and SVG from seeds |
| **PaletteMetadata.sol** | View               | Constructs JSON metadata with embedded images  |
| **PaletteManager.sol**  | Upgradeable        | Manages cross-contract palette access control  |
| **PaletteStorage.sol**  | Upgradeable        | Stores palette-to-NFT associations via EIP-712 |

### Integration Contracts

| Contract                      | Purpose                                          |
| ----------------------------- | ------------------------------------------------ |
| **UsePalette.sol**            | Base contract for standard ERC721 collections    |
| **UsePaletteUpgradeable.sol** | Base contract for upgradeable ERC721 collections |
| **MerkleTree.sol**            | Abstract whitelist/discount verification base    |

## Installation

### For NFT Creators (Recommended)

Add the Palettes protocol to your project via Git repository in `package.json`:

```json
{
  "dependencies": {
    "palettes-core": "git+https://github.com/Abstrucked/palettes-core.git"
  }
}
```

Then install:

```bash
npm install
# or
yarn install
# or
pnpm install
```

### Manual Clone

```bash
git clone https://github.com/Abstrucked/palettes-erc721.git
cd palettes-erc721
npm install
```

## Quick Start

### 1. Integrate into Your NFT Contract

#### Standard ERC721

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "palettes-core/contracts/UsePalette.sol";

contract MyNFT is ERC721, UsePalette {
    constructor(address paletteManager)
        ERC721("MyNFT", "MNFT")
        UsePalette(paletteManager)
    {}

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, UsePalette)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    // Use palette colors in your rendering
    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        string[8] memory colors = getPalette(tokenId);
        // Generate your metadata using the palette colors
    }
}
```

#### Upgradeable ERC721

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "palettes-core/contracts/UsePaletteUpgradeable.sol";

contract MyNFTUpgradeable is ERC721Upgradeable, UsePaletteUpgradeable {
    function initialize(address paletteManager) public initializer {
        __ERC721_init("MyNFT", "MNFT");
        __UsePalette_init(paletteManager);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721Upgradeable, UsePaletteUpgradeable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
```

### 2. Query Palette Colors

```solidity
// Get hex color strings (#RRGGBB)
string[8] memory hexColors = getPalette(tokenId);

// Get RGB values (uint24)
uint24[8] memory rgbColors = getRGBPalette(tokenId);

// Use in SVG generation
string memory svg = string(abi.encodePacked(
    '<svg><rect fill="', hexColors[0], '"/>',
    '<rect fill="', hexColors[1], '"/></svg>'
));
```

### 3. User Authorization Flow

Users must sign a message to authorize their palette for use with your NFT:

```javascript
const ethers = require("ethers");

// EIP-712 domain
const domain = {
  name: "PaletteStorage",
  version: "1",
  chainId: await ethers.provider.getNetwork().then((n) => n.chainId),
  verifyingContract: PALETTE_STORAGE_ADDRESS,
};

// Type definition
const types = {
  PaletteRecord: [
    { name: "contractAddress", type: "address" },
    { name: "tokenId", type: "uint256" },
  ],
};

// Message to sign
const message = {
  contractAddress: YOUR_NFT_CONTRACT_ADDRESS,
  tokenId: YOUR_NFT_TOKEN_ID,
};

// User signs
const signature = await signer.signTypedData(domain, types, message);

// Set palette on your contract
await myNFTContract.setPalette(nftTokenId, paletteId, signature);
```

## Contract Details

### Palettes.sol

Main ERC721 contract for palette tokens.

**Key Functions:**

```solidity
// Mint palettes (0.005 ETH each, max 20 per tx)
function mint(uint256 amount, bytes32[] calldata proof) external payable

// Get on-chain SVG (owner only)
function svg(uint256 tokenId) external view returns (string memory)

// Get deterministic seed
function getSeed(uint256 tokenId) external view returns (bytes32)

// Get RGB palette (manager only)
function rgbPalette(uint256 tokenId) external view returns (uint24[8] memory)

// Get hex palette (manager only)
function webPalette(uint256 tokenId) external view returns (string[8] memory)

// Get metadata URI
function tokenURI(uint256 tokenId) external view returns (string memory)
```

**Constants:**

- Max Supply: 10,000
- Max Mint Per Transaction: 20
- Mint Price: 0.005 ETH (configurable)

### PaletteRenderer.sol

Pure contract for color generation and SVG rendering.

**Color Derivation:**

From a single seed, 8 colors are generated:

| Index | Type           | Algorithm                                 |
| ----- | -------------- | ----------------------------------------- |
| 0     | Original       | Base color from seed                      |
| 1     | Light          | 80% original + 20% white                  |
| 2     | Dark           | 80% brightness                            |
| 3     | Muted          | Desaturated toward luminance              |
| 4     | Complement     | Perceptual inverse with channel swap      |
| 5     | Shifted        | RGB → BGR channel rotation                |
| 6     | Inverted Shift | Complex inversion (255-G, 255-B, 255-R)   |
| 7     | Grayscale      | NTSC luminance (0.299R + 0.587G + 0.114B) |

**SVG Output:**

- Dimensions: 1024×1024px
- Layout: 8 circles horizontally distributed
- Format: Base64-encoded data URI

### PaletteManager.sol

Cross-contract access control layer.

**Functions:**

```solidity
// Get hex palette for external NFT
function getPalette(uint256 tokenId) external view returns (string[8] memory)

// Get RGB palette for external NFT
function getRGBPalette(uint256 tokenId) external view returns (uint24[8] memory)

// Link palette to external NFT (requires signature)
function setPaletteRecord(
    uint256 paletteId,
    address contractAddress,
    uint256 tokenId,
    bytes calldata signature
) external
```

### PaletteStorage.sol

Secure storage for palette associations using EIP-712 signature verification.

**Security:**

- Uses typed data hashing (EIP-712)
- Domain separator includes chain ID, contract address
- Prevents cross-chain and cross-contract signature reuse

## Color Data Formats

The protocol supports multiple color data formats:

| Type        | Description                           | Usage                    |
| ----------- | ------------------------------------- | ------------------------ |
| `uint24`    | Single RGB color (8 bits per channel) | Individual color storage |
| `uint24[8]` | Array of 8 colors                     | Function returns         |
| `uint192`   | Packed 8 colors (24×8 bits)           | Gas-efficient storage    |
| `string`    | Hex format (#RRGGBB)                  | Web/SVG rendering        |
| `string[8]` | Array of hex strings                  | External integration     |

### Color Library (Colors.sol)

```solidity
// Pack RGB components into uint24
function packRGB(uint256 r, uint256 g, uint256 b) pure returns (uint24)

// Unpack uint24 into RGB components
function unpackRGB(uint24 color) pure returns (uint256 r, uint256 g, uint256 b)

// Pack 8 colors into uint192
function packPalette(uint24[8] memory colors) pure returns (uint192)

// Unpack uint192 into 8 colors
function unpackPalette(uint192 packed) pure returns (uint24[8] memory)

// Get specific color from packed palette
function unpackPaletteAt(uint192 packed, uint256 index) pure returns (uint24)

// Convert uint24 to hex string
function getHex(uint24 color) pure returns (string memory)

// Generate perceptual complement
function getPerceptualComplement(uint256 r, uint256 g, uint256 b) pure returns (uint24)
```

## Development

### Prerequisites

- Node.js v16+ and npm/yarn/pnpm
- Hardhat
- OpenZeppelin Contracts v5

### Setup

```bash
# Clone repository
git clone https://github.com/Abstrucked/palettes-erc721.git
cd palettes-erc721

# Install dependencies
npm install

# Create .env file
cp .env.example .env

# Compile contracts
npx hardhat compile

# Generate TypeChain types
npm run typechain
```

### Environment Variables

Create a `.env` file with the following:

```bash
# Network RPC URLs
BASE_SEPOLIA=https://sepolia.base.org
BASE=https://mainnet.base.org
MAINNET=https://eth-mainnet.g.alchemy.com/v2/YOUR_KEY
ARBITRUM=https://arb-mainnet.g.alchemy.com/v2/YOUR_KEY

# Deployer Keys
BASE_SEPOLIA_DEPLOYER=your_private_key
DEPLOYER_PRIVATE_KEY=your_private_key

# Optional: API Keys
ETHERSCAN_APIKEY=your_etherscan_key
COINMARKETCAP_APIKEY=your_coinmarketcap_key

# Gas Reporting
REPORT_GAS=true
```

### Testing

```bash
# Run all tests
npx hardhat test

# Run specific test
npx hardhat test test/palette.test.js

# Run with gas reporting
REPORT_GAS=true npx hardhat test

# Run with coverage
npx hardhat coverage
```

The test suite includes:

- **palette.test.js**: Core functionality tests

  - Minting
  - SVG generation
  - Color retrieval
  - Metadata generation

- **upgradeable.test.js**: Integration tests
  - Cross-contract palette usage
  - EIP-712 signature verification
  - Manager/Storage integration
  - Upgradeable contract patterns

### Deployment

Deploy the complete protocol:

```bash
# Local deployment
npx hardhat run scripts/deploy.js

# Testnet deployment (Base Sepolia)
npx hardhat run scripts/deploy.js --network baseSepolia

# Mainnet deployment (Base)
npx hardhat run scripts/deploy.js --network base
```

**Deployment Order:**

1. Deploy `Utils` library
2. Deploy `Colors` library
3. Deploy `PaletteRenderer`
4. Deploy `PaletteMetadata` (with renderer address)
5. Deploy `Palettes` proxy (with renderer and metadata)
6. Deploy `PaletteManager` proxy (with Palettes address)
7. Set manager address in Palettes
8. Deploy `PaletteStorage` proxy (with manager address)
9. Set storage address in Manager

### Gas Costs

Approximate gas costs on Base mainnet:

| Operation                    | Gas Cost          |
| ---------------------------- | ----------------- |
| Mint 1 palette               | ~150,000          |
| Mint 20 palettes             | ~1,800,000        |
| Set palette (with signature) | ~80,000           |
| Get palette (view)           | 0 (view function) |
| Generate SVG (view)          | 0 (view function) |

### Compiler Settings

```javascript
{
  solidity: "0.8.20",
  settings: {
    optimizer: {
      enabled: true,
      runs: 200
    },
    viaIR: true
  }
}
```

## Supported Networks

| Network      | Chain ID | Status       |
| ------------ | -------- | ------------ |
| Base         | 8453     | Mainnet      |
| Base Sepolia | 84532    | Testnet      |
| Ethereum     | 1        | Configurable |
| Arbitrum     | 42161    | Configurable |

## Security

### Auditing Status

The protocol has not been formally audited. Use at your own risk.

### Security Features

- EIP-712 typed data signing for authorization
- UUPS upgradeable pattern with owner-only upgrades
- OpenZeppelin v5 battle-tested contracts
- Access control on sensitive functions
- Input validation and zero address checks

### Known Considerations

- Palette owners control authorization
- Transfer of palette token revokes previous associations (implementation-dependent)
- Manager contract is single point of access (by design)

## License

ISC License - see [LICENSE](LICENSE) file for details.

## Contributing

Contributions are welcome. Please:

1. Fork the repository
2. Create a feature branch
3. Add tests for new functionality
4. Ensure all tests pass
5. Submit a pull request

## Support

- **Issues**: [GitHub Issues](https://github.com/Abstrucked/palettes-erc721/issues)
- **Documentation**: See [palettes-content.md](palettes-content.md)
- **Author**: Abstrucked.eth

## Resources

- [OpenZeppelin Contracts](https://docs.openzeppelin.com/contracts/)
- [Hardhat Documentation](https://hardhat.org/docs)
- [EIP-712 Specification](https://eips.ethereum.org/EIPS/eip-712)
- [UUPS Proxy Pattern](https://eips.ethereum.org/EIPS/eip-1822)

## Acknowledgments

Built with:

- Solidity ^0.8.20
- OpenZeppelin Contracts v5
- Hardhat
- ethers.js v6
- TypeChain

---

**Version**: 1.0.21
**Last Updated**: January 2025

For more detailed documentation about content and integration, see [palettes-content.md](palettes-content.md).
