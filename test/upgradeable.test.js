// Testing Palettes.sol contract:
const {ethers, upgrades} = require("hardhat");
const {expect} = require("chai");
const fs = require('node:fs');
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

    const Palettes = await ethers.getContractFactory("Palettes");
    palettes = await upgrades.deployProxy(Palettes, [owner.address]);
    await palettes.waitForDeployment();

    const PaletteStorage = await ethers.getContractFactory("PaletteStorage");
    storage = await upgrades.deployProxy(PaletteStorage, [owner.address]);
    await storage.waitForDeployment();

    const PaletteManager = await ethers.getContractFactory("PaletteManager");
    manager = await upgrades.deployProxy(PaletteManager, [owner.address, await palettes.getAddress(), await storage.getAddress()]);
    await manager.waitForDeployment();

    await palettes.mint(2n,{value: ethers.parseEther("0.02")});

    const TestERC721Upgradeable = await ethers.getContractFactory("TestERC721Upgradeable");
    testERC721Upgradeable = await upgrades.deployProxy(
      TestERC721Upgradeable, [owner.address, await manager.getAddress()]);
    await testERC721Upgradeable.waitForDeployment();
  });

  describe("Test Upgradeable ERC721", async function () {

    it("Should deploy the test contract", async function  () {
      expect(await testERC721Upgradeable.name()).to.equal("TestUpgradeable");
      expect(await testERC721Upgradeable.symbol()).to.equal("TESTUPGRADE");
    });

    it("Should mint and set the palette #1", async function() {
      const tokenId = 1;



      await testERC721Upgradeable.mint();
      const typedData = {
        types: {
          EIP712Domain: [
            { name: "name", type: "string" },
            { name: "version", type: "string" },
            { name: "chainId", type: "uint256" },
            { name: "verifyingContract", type: "address" },
            { name: "salt", type: "bytes32" }
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
          ]
        },
        domain: {
          name: "PaletteStorage",
          version: "1",
          chainId: BigInt(31337).toString(),
          verifyingContract: await storage.getAddress(),
        },
        message: {
          paletteId: 1n,
          contractAddress: await testERC721Upgradeable.getAddress(),
          tokenId: 1n,
        },
      };

      console.log("::::::: OWNERS :::::", await owner.getAddress(), await palettes.ownerOf(1n), await manager.isPaletteOwner(1n, await owner.getAddress()));
      console.log({
        palettesAddress: await palettes.getAddress(),
        storageAddress: await storage.getAddress(),
        paletteManagerAddress: await manager.getAddress(),
        nftAddress: await testERC721Upgradeable.getAddress()
      })
      const signature = await owner.signTypedData(typedData.domain, typedData.primaryType, typedData.message)

      console.log(signature)
      expect(await testERC721Upgradeable.setPalette(1n, 1n, signature)).to.emit(testERC721Upgradeable, "PaletteSet").withArgs(1n, 1n,);


      // expect(await testERC721Upgradeable.getPalette(tokenId)).to.equal(1n);

    })


  });
});