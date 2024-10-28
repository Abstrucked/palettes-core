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
  let _name = 'Palettes';
  let _symbol = 'PAL';
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



  });
});