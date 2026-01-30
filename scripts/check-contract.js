// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// You can also run a script with `npx hardhat run <script>`. If you do that, Hardhat
// will compile your contracts, add the Hardhat Runtime Environment's members to the
// global scope, and execute the script.
const { ethers, upgrades, network } = require("hardhat");

async function main() {
  const proxyAddress = {
    baseSepolia: "0x2609FA31f65DD255Bd0990dE033CF8b7BDADe119",
    sepolia: "0x17d888db845d0Cf5BE3394A7207f00695e9AF5bE",
  };

  if (!proxyAddress[network.name])
    throw new Error("proxyAddress for the selected chain is not valid");
  const palettes = await ethers.getContractAt(
    "Palettes",
    proxyAddress[network.name]
  );

  const maxSupply = await palettes.maxSupply();
  console.log({ maxSupply });

  // await palettes.setMaxSupply(1000n);
  // const discount = await palettes.discount();

  await palettes.setMerkleRoot(
    "0xf3d3017dee5ff99f3f8ed5763b28933fde3b49dcd8754aa21a53ddd72cbdcfcb"
  );
  // console.log({ discount });
}

Promise.all([main()]);

/**
 Palette deployed to: 0x2609FA31f65DD255Bd0990dE033CF8b7BDADe119
 Manager deployed to: 0x2df08A3B070be33D6f4Ded2Fe6173348a6A02fA3
 Storage deployed to: 0xB093B84a7AF628Ed658cD801cd5C8EB0AC3a89D8
 */
