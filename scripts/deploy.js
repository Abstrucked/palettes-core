// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// You can also run a script with `npx hardhat run <script>`. If you do that, Hardhat
// will compile your contracts, add the Hardhat Runtime Environment's members to the
// global scope, and execute the script.
const hre = require("hardhat");

async function main() {

  const Utils = await hre.ethers.deployContract("Utils");
  await Utils.waitForDeployment();

  const PaletteRenderer = await hre.ethers.deployContract("PaletteRenderer");
  await PaletteRenderer.waitForDeployment();
  const Palettes = await hre.ethers.getContractFactory("Palettes");
  const palettes = await hre.upgrades.deployProxy(Palettes, [(await hre.ethers.getSigners())[0].address, await PaletteRenderer.getAddress()]);
  await palettes.waitForDeployment();

  console.log("Palette deployed to:", await palettes.getAddress());
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
