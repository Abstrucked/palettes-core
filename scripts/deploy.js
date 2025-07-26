// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// You can also run a script with `npx hardhat run <script>`. If you do that, Hardhat
// will compile your contracts, add the Hardhat Runtime Environment's members to the
// global scope, and execute the script.
const { ethers, upgrades } = require("hardhat");
async function main() {
  const [owner] = await ethers.getSigners();
  // ---  LIBRARIES  ---
  const utilsCF = await ethers.getContractFactory("Utils");
  const utils = await utilsCF.deploy();
  await utils.waitForDeployment();
  const ColorsLib = await ethers.getContractFactory("Colors");
  const colorsLib = await ColorsLib.deploy();
  await colorsLib.waitForDeployment();
  // ---------------------

  const Renderer = await ethers.getContractFactory("PaletteRenderer");
  const renderer = await Renderer.deploy();
  await renderer.waitForDeployment();

  const Palettes = await ethers.getContractFactory("Palettes");
  const palettes = await upgrades.deployProxy(Palettes, [owner.address]);
  await palettes.waitForDeployment();

  const PaletteManager = await ethers.getContractFactory("PaletteManager");
  manager = await upgrades.deployProxy(PaletteManager, [
    owner.address,
    await palettes.getAddress(),
  ]);
  await manager.waitForDeployment();

  const PaletteStorage = await ethers.getContractFactory("PaletteStorage");
  storage = await upgrades.deployProxy(PaletteStorage, [
    owner.address,
    await manager.getAddress(),
  ]);
  await storage.waitForDeployment();

  await manager.setStorageContract(await manager.getAddress());
  await palettes.setManagerContractAddress(await manager.getAddress());

  console.log("Palette deployed to:", await palettes.getAddress());
  console.log("Manager deployed to:", await manager.getAddress());
  console.log("Storage deployed to:", await storage.getAddress());
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
