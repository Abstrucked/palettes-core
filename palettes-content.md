# Palettes Content

---

## SECTION 1: LANDING PAGE

---

### Hero Section

**Headline:**
On-Chain Color Palettes for the NFT Ecosystem

**Subheadline:**
Mint unique 8-color palettes generated entirely on-chain. Use them across any NFT collection with cryptographic ownership verification.

**CTA:**
Mint Your Palette

---

### What is Palettes?

Palettes is an ERC721 protocol that generates unique, deterministic 8-color palettes directly on the Ethereum blockchain. Each palette is derived from a cryptographic seed, producing a harmonious set of colors that can be used by any NFT collection through our cross-contract integration system.

No external dependencies. No off-chain storage. Every color, every pixel, generated and stored permanently on-chain.

---

### How It Works

**1. Mint**
Each minted token receives a unique seed derived from blockchain data. This seed deterministically generates your 8-color palette.

**2. Generate**
Our on-chain renderer creates an SVG visualization of your palette. The same seed always produces the same colors—verifiable by anyone.

**3. Integrate**
Other NFT collections can request access to your palette. Sign a message to authorize usage, and your colors become available to any compatible contract.

---

### The 8-Color System

Every Palettes token contains eight mathematically derived colors:

| Color | Derivation |
|-------|------------|
| Original | Base color extracted from seed |
| Light | 80% original blended with white |
| Dark | Reduced brightness variant |
| Muted | Desaturated toward luminance |
| Complement | Perceptual inverse with channel rotation |
| Shifted | RGB channel swap (B, R, G) |
| Inverted Shift | Complex inversion with channel reorder |
| Grayscale | NTSC luminance conversion |

This creates a cohesive palette where every color relates mathematically to the original—ensuring visual harmony.

---

### Features

**Fully On-Chain**
SVG generation, metadata, and color data all live on-chain. No IPFS. No external servers. Your palette exists as long as Ethereum exists.

**Cross-Contract Integration**
Any ERC721 collection can integrate Palettes. Inherit our UsePalette contract, and your NFTs can request and display palette colors.

**Cryptographic Authorization**
EIP-712 signature verification ensures only the palette owner can authorize which NFTs use their colors.

**Upgradeable Architecture**
UUPS proxy pattern allows protocol improvements without breaking existing tokens or integrations.

**Gas Optimized**
Colors packed into efficient uint192 storage. Pure functions for color derivation minimize gas costs.

---

### Technical Specs

- **Token Standard:** ERC721 (Upgradeable)
- **Max Supply:** 10,000
- **Mint Price:** 0.005 ETH
- **Colors Per Palette:** 8
- **SVG Dimensions:** 1024 x 1024 px
- **Color Format:** RGB (uint24) / Hex (#RRGGBB)

---

### For Creators

Building an NFT collection? Palettes gives your holders a new dimension of customization.

- Let holders apply their owned palettes to your artwork
- Query palette colors directly from your contract
- No API calls—everything happens on-chain
- Verify palette ownership cryptographically

---

### For Collectors

Your palette is an asset. Own colors that other NFT projects can integrate.

- Unique seed generates unique colors
- Authorize specific NFTs to use your palette
- Revoke access anytime
- Trade palettes like any ERC721

---

### Integration Example

```solidity
contract MyNFT is ERC721, UsePalette {
    constructor(address paletteManager)
        UsePalette(paletteManager) {}

    function getColors(uint256 tokenId)
        external view returns (string[8] memory) {
        return getPalette(tokenId);
    }
}
```

---

### FAQ

**What chain is Palettes deployed on?**
Palettes is deployed on Base with support for Ethereum mainnet.

**How are colors generated?**
A keccak256 hash of blockchain data creates a seed. This seed passes through our color derivation algorithm to produce 8 related colors.

**Can I use my palette in multiple NFT collections?**
Yes. You can authorize any compatible NFT contract to access your palette colors.

**What happens if I sell my palette?**
The new owner gains control over authorization. Previously authorized NFTs may need re-authorization depending on the implementing contract.

**Are the SVGs stored on-chain?**
Yes. The SVG is generated on-demand by the contract. No external storage is used.

---

---

## SECTION 2: DOCUMENTATION

---

### Overview

Palettes is a protocol for on-chain color palette generation and cross-contract color sharing. It consists of five core contracts:

| Contract | Purpose |
|----------|---------|
| Palettes | Main ERC721 token contract |
| PaletteRenderer | SVG and color generation |
| PaletteMetadata | JSON metadata construction |
| PaletteManager | Cross-contract access control |
| PaletteStorage | Palette-to-NFT association storage |

---

### Installation

```bash
npm install palettes-core
```

Or with yarn:

```bash
yarn add palettes-core
```

---

### Contract Addresses

**Base Mainnet**
- Palettes: `[DEPLOYED_ADDRESS]`
- PaletteManager: `[DEPLOYED_ADDRESS]`

**Base Sepolia (Testnet)**
- Palettes: `[DEPLOYED_ADDRESS]`
- PaletteManager: `[DEPLOYED_ADDRESS]`

---

### Minting

Mint palette tokens by calling the `mint` function:

```solidity
function mint(uint256 amount, bytes32[] calldata proof) external payable
```

**Parameters:**
- `amount`: Number of palettes to mint (max 20 per transaction)
- `proof`: Merkle proof for discount eligibility (empty array if none)

**Cost:** 0.005 ETH per palette (discounts may apply with valid proof)

**Example:**
```javascript
const tx = await palettes.mint(1, [], {
    value: ethers.parseEther("0.005")
});
```

---

### Querying Palettes

**Get SVG**
```solidity
function svg(uint256 tokenId) external view returns (string memory)
```
Returns the on-chain SVG representation. Only callable by token owner.

**Get RGB Colors**
```solidity
function rgbPalette(uint256 tokenId) external view returns (uint24[8] memory)
```
Returns array of 8 RGB values packed as uint24. Only callable by PaletteManager.

**Get Hex Colors**
```solidity
function webPalette(uint256 tokenId) external view returns (string[8] memory)
```
Returns array of 8 hex color strings (#RRGGBB format). Only callable by PaletteManager.

**Get Token Metadata**
```solidity
function tokenURI(uint256 tokenId) external view returns (string memory)
```
Returns base64-encoded JSON with embedded SVG image and animation URL.

---

### Integrating Palettes into Your NFT Contract

To allow your NFT collection to use Palettes, inherit from `UsePalette`:

```solidity
import "palettes-core/contracts/UsePalette.sol";

contract MyCollection is ERC721, UsePalette {
    constructor(address _paletteManager)
        ERC721("MyCollection", "MC")
        UsePalette(_paletteManager)
    {}

    function supportsInterface(bytes4 interfaceId)
        public view override(ERC721, UsePalette)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
```

For upgradeable contracts, use `UsePaletteUpgradeable`:

```solidity
import "palettes-core/contracts/UsePaletteUpgradeable.sol";

contract MyCollectionV1 is ERC721Upgradeable, UsePaletteUpgradeable {
    function initialize(address _paletteManager) public initializer {
        __ERC721_init("MyCollection", "MC");
        __UsePalette_init(_paletteManager);
    }
}
```

---

### Authorizing Palette Usage

Before an external NFT can use a palette, the palette owner must sign an authorization message.

**1. Construct the EIP-712 Message**

```javascript
const domain = {
    name: "PaletteStorage",
    version: "1",
    chainId: chainId,
    verifyingContract: paletteStorageAddress
};

const types = {
    PaletteRecord: [
        { name: "contractAddress", type: "address" },
        { name: "tokenId", type: "uint256" }
    ]
};

const message = {
    contractAddress: nftContractAddress,
    tokenId: nftTokenId
};
```

**2. Sign with Palette Owner**

```javascript
const signature = await paletteOwner.signTypedData(domain, types, message);
```

**3. Set Palette on NFT Contract**

```javascript
await nftContract.setPalette(nftTokenId, paletteId, signature);
```

---

### Retrieving Colors in Your Contract

Once a palette is linked, query colors using inherited functions:

```solidity
// Get hex color array
function getPalette(uint256 tokenId)
    public view returns (string[8] memory)

// Get RGB color array
function getRGBPalette(uint256 tokenId)
    public view returns (uint24[8] memory)
```

**Usage Example:**

```solidity
function render(uint256 tokenId) external view returns (string memory) {
    string[8] memory colors = getPalette(tokenId);

    return string(abi.encodePacked(
        '<svg><rect fill="', colors[0], '"/></svg>'
    ));
}
```

---

### Color Data Formats

**uint24 (RGB)**
Single color packed as 24-bit integer:
- Bits 23-16: Red (0-255)
- Bits 15-8: Green (0-255)
- Bits 7-0: Blue (0-255)

**uint192 (Packed Palette)**
All 8 colors packed into single value for gas-efficient storage.

**string (Hex)**
Standard web format: `#RRGGBB`

---

### Color Derivation Algorithm

From a single seed, 8 colors are derived:

```
[0] Original    = extractFromSeed(seed)
[1] Light       = blend(original, white, 0.8)
[2] Dark        = scale(original, 0.8)
[3] Muted       = blend(original, luminance, factor)
[4] Complement  = perceptualInverse(original)
[5] Shifted     = swap(B, R, G)
[6] InvShifted  = invert(swap(G, B, R))
[7] Grayscale   = ntscLuminance(original)
```

NTSC luminance formula: `0.299R + 0.587G + 0.114B`

---

### Interface Reference

**IUsePalette**
```solidity
interface IUsePalette {
    function getPalette(uint256 tokenId) external view returns (string[8] memory);
    function getRGBPalette(uint256 tokenId) external view returns (uint24[8] memory);
    function setPalette(uint256 tokenId, uint256 paletteId, bytes calldata signature) external;
}
```

**IPalettes**
```solidity
interface IPalettes {
    function svg(uint256 tokenId) external view returns (string memory);
    function rgbPalette(uint256 tokenId) external view returns (uint24[8] memory);
    function webPalette(uint256 tokenId) external view returns (string[8] memory);
    function getSeed(uint256 tokenId) external view returns (bytes32);
}
```

---

### Error Codes

| Error | Description |
|-------|-------------|
| `NotOwner()` | Caller does not own the specified token |
| `InvalidSignature()` | EIP-712 signature verification failed |
| `ZeroAddress()` | Address parameter cannot be zero |
| `MaxSupplyReached()` | Cannot mint beyond max supply (10,000) |
| `MaxMintExceeded()` | Cannot mint more than 20 per transaction |
| `InsufficientPayment()` | ETH sent is less than mint price |
| `CallerNotManager()` | Function only callable by PaletteManager |

---

### Security Considerations

**Signature Verification**
EIP-712 typed data signing prevents signature reuse across chains and contracts. Always verify the domain separator matches your deployment.

**Access Control**
- `rgbPalette()` and `webPalette()` restricted to PaletteManager
- `svg()` restricted to token owner
- Admin functions protected by Ownable

**Upgrades**
UUPS proxy pattern with `_authorizeUpgrade()` restricted to owner. Proxy addresses remain constant across upgrades.

---

### Gas Considerations

**Minting:** ~150,000 gas per token (varies with batch size)

**SVG Generation:** View function, no gas for external calls

**setPalette:** ~80,000 gas (writes storage + signature verification)

**getPalette:** View function, no gas for external calls

---

### Events

```solidity
event PaletteSet(
    uint256 indexed tokenId,
    uint256 indexed paletteId
);

event Transfer(
    address indexed from,
    address indexed to,
    uint256 indexed tokenId
);
```

---

### Deployed Libraries

The protocol uses two internal libraries:

**Colors.sol**
- `packRGB(r, g, b)` - Combine RGB into uint24
- `unpackRGB(color)` - Extract RGB from uint24
- `packPalette(colors)` - Pack 8 colors into uint192
- `unpackPalette(packed)` - Unpack uint192 to 8 colors
- `getHex(color)` - Convert uint24 to hex string
- `getPerceptualComplement(r, g, b)` - Generate complement color

**Utils.sol**
- String conversion utilities
- Base64 encoding for metadata

---

### Example: Full Integration Flow

**1. Deploy your NFT contract**
```solidity
MyNFT nft = new MyNFT(PALETTE_MANAGER_ADDRESS);
```

**2. User mints your NFT**
```javascript
await nft.mint(userAddress, tokenId);
```

**3. User owns a Palette (tokenId: 42)**
```javascript
const paletteId = 42;
```

**4. User signs authorization**
```javascript
const signature = await user.signTypedData(domain, types, {
    contractAddress: nft.address,
    tokenId: tokenId
});
```

**5. Link palette to NFT**
```javascript
await nft.setPalette(tokenId, paletteId, signature);
```

**6. Query colors in your contract**
```solidity
string[8] memory colors = getPalette(tokenId);
// Use colors in your rendering logic
```

---

### Support

- GitHub: [Repository URL]
- Discord: [Discord Invite]
- Twitter: [@handle]

---

### License

ISC License

---

### Version History

| Version | Changes |
|---------|---------|
| 1.0.25 | Current release |
| 1.0.21 | Package restructure |
| 1.0.0 | Initial release |
