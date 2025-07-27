// Testing Palettes.sol contract:
const { ethers, upgrades, network } = require("hardhat");
const { expect } = require("chai");
const fs = require("node:fs");
describe("Palette contract", async () => {
  let palettes;
  let storage;
  let manager;
  let renderer;
  let testERC721Upgradeable;
  let owner, account1, otherAccounts;
  beforeEach(async function () {
    [owner, account1, ...otherAccounts] = await ethers.getSigners();

    // ---  LIBRARIES  ---
    const utilsCF = await ethers.getContractFactory("Utils");
    const utils = await utilsCF.deploy();
    await utils.waitForDeployment();
    const ColorsLib = await ethers.getContractFactory("Colors");
    const colorsLib = await ColorsLib.deploy();
    await colorsLib.waitForDeployment();
    // ---------------------

    const Renderer = await ethers.getContractFactory("PaletteRenderer");
    renderer = await Renderer.deploy();
    await renderer.waitForDeployment();

    const Metadata = await ethers.getContractFactory("PaletteMetadata");
    const metadata = await Metadata.deploy(await renderer.getAddress());
    await metadata.waitForDeployment();

    const Palettes = await ethers.getContractFactory("Palettes");
    palettes = await upgrades.deployProxy(Palettes, [
      owner.address,
      await renderer.getAddress(),
      await metadata.getAddress(),
    ]);
    await palettes.waitForDeployment();

    const PaletteManager = await ethers.getContractFactory("PaletteManager");
    manager = await upgrades.deployProxy(PaletteManager, [
      owner.address,
      await palettes.getAddress(),
    ]);
    await manager.waitForDeployment();
    await palettes.setManagerContractAddress(await manager.getAddress());
    const PaletteStorage = await ethers.getContractFactory("PaletteStorage");
    storage = await upgrades.deployProxy(PaletteStorage, [
      owner.address,
      await manager.getAddress(),
    ]);
    await storage.waitForDeployment();

    await manager.setStorageContract(await storage.getAddress());

    await palettes.setPrice(ethers.parseEther("0.01"));

    const TestERC721Upgradeable = await ethers.getContractFactory(
      "TestERC721Upgradeable"
    );
    testERC721Upgradeable = await upgrades.deployProxy(TestERC721Upgradeable, [
      owner.address,
      await manager.getAddress(),
    ]);
    await testERC721Upgradeable.waitForDeployment();
  });

  describe("Test Upgradeable ERC721", async function () {
    it("Should deploy the test contract", async function () {
      expect(await testERC721Upgradeable.name()).to.equal("TestUpgradeable");
      expect(await testERC721Upgradeable.symbol()).to.equal("TESTUPGRADE");
    });

    it("Should mint and set the palette #1", async function () {
      const tokenId = 1;

      await palettes.mint(2n, [], { value: ethers.parseEther("0.02") });
      await testERC721Upgradeable.mint();
      const typedData = {
        types: {
          EIP712Domain: [
            { name: "name", type: "string" },
            { name: "version", type: "string" },
            { name: "chainId", type: "uint256" },
            { name: "verifyingContract", type: "address" },
            { name: "salt", type: "bytes32" },
          ],
          PaletteRecord: [
            { name: "paletteId", type: "uint256" },
            { name: "tokenId", type: "uint256" },
          ],
        },
        primaryType: {
          PaletteRecord: [
            { name: "paletteId", type: "uint256" },
            { name: "contractAddress", type: "address" },
            { name: "tokenId", type: "uint256" },
          ],
        },
        domain: {
          name: "PaletteManager",
          version: "1",
          chainId: BigInt(31337).toString(),
          verifyingContract: await manager.getAddress(),
        },
        message: {
          paletteId: 1n,
          contractAddress: await testERC721Upgradeable.getAddress(),
          tokenId: 1n,
        },
      };

      console.log(
        "::::::: OWNERS :::::",
        await owner.getAddress(),
        await palettes.ownerOf(1n),
        await manager.isPaletteOwner(1n, await owner.getAddress())
      );
      console.log({
        palettesAddress: await palettes.getAddress(),
        storageAddress: await storage.getAddress(),
        paletteManagerAddress: await manager.getAddress(),
        nftAddress: await testERC721Upgradeable.getAddress(),
      });
      const signature = await owner.signTypedData(
        typedData.domain,
        typedData.primaryType,
        typedData.message
      );

      console.log(signature);
      expect(await testERC721Upgradeable.setPalette(1n, 1n, signature))
        .to.emit(testERC721Upgradeable, "PaletteSet")
        .withArgs(1n, 1n);
      console.log(await testERC721Upgradeable.getRGBPalette(1n));
      const webPalette = await testERC721Upgradeable.getPalette(1n);
      console.log(webPalette);
      // Function to unpack uint24 to RGB value
      function uint24ToRgb(uint24) {
        const red = (uint24 >> 16) & 0xff;
        const green = (uint24 >> 8) & 0xff;
        const blue = uint24 & 0xff;
        return { red, green, blue };
      }

      // Example usage:
      let rgbPalette1 = await testERC721Upgradeable.getRGBPalette(1n);
      let rgbValues = rgbPalette1.map((col) =>
        uint24ToRgb(Number(col.toString()))
      );
      console.log(rgbValues); // { red: R_VALUE, green: G_VALUE, blue: B_VALUE }
      const hexString = rgbPalette1[0].toString(16);

      // Convert the hexadecimal string to a number
      const decimalNumber = parseInt(hexString, 16);

      console.log(decimalNumber);
      console.log(uint24ToRgb(decimalNumber));

      const hexColor = webPalette[0];

      // Extract the red, green, and blue components from the hexadecimal color code
      const r = parseInt(hexColor.slice(1, 3), 16);
      const g = parseInt(hexColor.slice(3, 5), 16);
      const b = parseInt(hexColor.slice(5, 7), 16);

      console.log(`HEX: ${webPalette[0]}, RGB: (${r}, ${g}, ${b})`);
      // Additional expectation/unittest (if necessary)
      //   expect(rgbValue).to.deep.equal({ red: EXPECTED_R, green: EXPECTED_G, blue: EXPECTED_B });
      //       expect(await testERC721Upgradeable.getPalette(tokenId)).to.equal(1n);

      const hexNumbers = [
        12440268n,
        726804n,
        9018312n,
        10209417n,
        13142427n,
        7758903n,
        6567798n,
        3634788n,
      ];

      const hexToRgb = (hexNumber) => {
        const hexString = hexNumber.toString(16).padStart(6, "0"); // Convert BigInt to hex string and pad with zeroes if necessary
        const r = parseInt(hexString.slice(0, 2), 16);
        const g = parseInt(hexString.slice(2, 4), 16);
        const b = parseInt(hexString.slice(4, 6), 16);
        return `RGB: (${r}, ${g}, ${b})`;
      };

      const rgbNumbers = rgbPalette1.map(hexToRgb);

      console.log(rgbNumbers.join("\n"));

      console.log(await palettes.svg(1n));
      //
    });
  });
});
