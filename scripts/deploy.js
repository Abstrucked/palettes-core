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

  const Metadata = await ethers.getContractFactory("PaletteMetadata");
  const metadata = await Metadata.deploy(await renderer.getAddress());
  await metadata.waitForDeployment();
  const Palettes = await ethers.getContractFactory("Palettes");
  const palettes = await upgrades.deployProxy(Palettes, [
    owner.address,
    await renderer.getAddress(),
    await metadata.getAddress(),
  ]);
  await palettes.waitForDeployment();

  const PaletteManager = await ethers.getContractFactory("PaletteManager");
  const manager = await upgrades.deployProxy(PaletteManager, [
    owner.address,
    await palettes.getAddress(),
  ]);
  await manager.waitForDeployment();
  await palettes.setManagerContractAddress(await manager.getAddress());
  const PaletteStorage = await ethers.getContractFactory("PaletteStorage");
  const storage = await upgrades.deployProxy(PaletteStorage, [
    owner.address,
    await manager.getAddress(),
  ]);
  await storage.waitForDeployment();

  await manager.setStorageContract(await storage.getAddress());

  const palettesImplAddress = await upgrades.erc1967.getImplementationAddress(
    await palettes.getAddress()
  );
  const managerImplAddress = await upgrades.erc1967.getImplementationAddress(
    await manager.getAddress()
  );
  const storageImplAddress = await upgrades.erc1967.getImplementationAddress(
    await storage.getAddress()
  );

  // Verify Utils library
  try {
    console.log("Verifying Utils library...");
    await hre.run("verify:verify", {
      address: await utils.getAddress(),
      constructorArguments: [],
    });
    console.log("✓ Utils library verified.");
  } catch (err) {
    console.warn("✗ Utils library verify failed:", err.message || err);
  }

  // Verify Colors library
  try {
    console.log("Verifying Colors library...");
    await hre.run("verify:verify", {
      address: await colorsLib.getAddress(),
      constructorArguments: [],
    });
    console.log("✓ Colors library verified.");
  } catch (err) {
    console.warn("✗ Colors library verify failed:", err.message || err);
  }

  // Verify PaletteRenderer
  try {
    console.log("Verifying PaletteRenderer...");
    await hre.run("verify:verify", {
      address: await renderer.getAddress(),
      constructorArguments: [],
    });
    console.log("✓ PaletteRenderer verified.");
  } catch (err) {
    console.warn("✗ PaletteRenderer verify failed:", err.message || err);
  }

  // Verify PaletteMetadata
  try {
    console.log("Verifying PaletteMetadata...");
    await hre.run("verify:verify", {
      address: await metadata.getAddress(),
      constructorArguments: [await renderer.getAddress()],
    });
    console.log("✓ PaletteMetadata verified.");
  } catch (err) {
    console.warn("✗ PaletteMetadata verify failed:", err.message || err);
  }

  // Verify Palettes implementation
  try {
    console.log("Verifying Palettes implementation...");
    await hre.run("verify:verify", {
      address: palettesImplAddress,
      constructorArguments: [],
    });
    console.log("✓ Palettes implementation verified.");
  } catch (err) {
    console.warn(
      "✗ Palettes implementation verify failed:",
      err.message || err
    );
  }

  // Verify PaletteManager implementation
  try {
    console.log("Verifying PaletteManager implementation...");
    await hre.run("verify:verify", {
      address: managerImplAddress,
      constructorArguments: [],
    });
    console.log("✓ PaletteManager implementation verified.");
  } catch (err) {
    console.warn(
      "✗ PaletteManager implementation verify failed:",
      err.message || err
    );
  }

  // Verify PaletteStorage implementation
  try {
    console.log("Verifying PaletteStorage implementation...");
    await hre.run("verify:verify", {
      address: storageImplAddress,
      constructorArguments: [],
    });
    console.log("✓ PaletteStorage implementation verified.");
  } catch (err) {
    console.warn(
      "✗ PaletteStorage implementation verify failed:",
      err.message || err
    );
  }

  console.log("\n=== Verification complete ===");

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
