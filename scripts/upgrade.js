// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// You can also run a script with `npx hardhat run <script>`. If you do that, Hardhat
// will compile your contracts, add the Hardhat Runtime Environment's members to the
// global scope, and execute the script.
const { ethers, upgrades, network } = require("hardhat");

async function main() {
  const [owner] = await ethers.getSigners();
  // ---  LIBRARIES  ---
  const Palettes = await ethers.getContractFactory("Palettes_v2");
  const proxyAddress =
    network.name === "baseSepolia"
      ? "0x0cE70A0D8dB342C4D1184E08EB3df56a7b406997"
      : "";
  const palettes = await ethers.getContractAt("Palettes", proxyAddress);

  const upgraded = await upgrades.upgradeProxy(palettes, Palettes);
  await upgraded.waitForDeployment();

  const implAddress = await upgrades.erc1967.getImplementationAddress(
    proxyAddress
  );

  console.log({ proxyAddress, implAddress });
}

Promise.all([main()]);
