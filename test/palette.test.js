// Testing Palettes.sol contract:
const { ethers, upgrades, network } = require("hardhat");
const { expect } = require("chai");
const fs = require("node:fs");
describe("Palette contract", async () => {
  let palettes;
  let storage;
  let manager;
  let renderer;
  let _name = "Palettes";
  let _symbol = "PAL";
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
  });

  describe("Should Deploy", async function () {
    it("Should have the correct name and symbol ", async function () {
      expect(await palettes.name()).to.equal(_name);
      expect(await palettes.symbol()).to.equal(_symbol);
    });

    // it("Should set the sale to open", async function () {
    //   await expect(await palettes.toggleSale()).to.emit(palettes, "SaleStateChange").withArgs(true);
    // })

    // it("Should revert with error SaleIsClosed()", async function () {
    //   const address1=account1.address;
    //   let response =  palettes.mint(address1, ethers.utils.id("firstNFT"));
    //       await expect(response).to.be.revertedWith("SaleIsClosed()");

    // })

    it("Should mint a token with token ID 1 & 2 to account1", async function () {
      const tx1 = await palettes
        .connect(account1)
        .mint(1n, [], { value: ethers.parseEther("0.01") });
      tx1.wait();
      const tx2 = await palettes
        .connect(account1)
        .mint(1n, [], { value: ethers.parseEther("0.01") });
      tx2.wait();

      // console.log(await palettes.tokenURI(1n));
      expect(await palettes.balanceOf(account1.address)).to.equal(2n);
    });

    it("Should mint 10", async function () {
      let html = `<html>
            <head>
                <title>Test Palettes</title>
                <style>
                .box {
                display: flex;
                flex-direction: column;
                gap: 1rem;
                }
</style>
            </head><body><div class="box">`;
      const maxMint = 10;
      for (let i = 0; i < maxMint; i++) {
        const tx1 = await palettes.mint(1n, [], {
          value: ethers.parseEther("0.01"),
        });
        tx1.wait();
        fs.writeFileSync(`palette${i + 1}.svg`, await palettes.svg(i + 1));
        html += await palettes.svg(i + 1);
        // console.log(await palettes.svg(i + 1));
      }

      html += `</div></body></html>`;
      fs.writeFileSync("test_palettes.html", html);
      expect(await palettes.minted()).to.equal(maxMint);
    });
    it("Should set the record for an NFT", async function () {
      let NFT = await ethers.getContractFactory("TestERC721");
      const nft = await NFT.deploy(await manager.getAddress());
      await nft.waitForDeployment();

      await palettes.mint(1n, [], { value: ethers.parseEther("0.01") });
      const nft_address = await nft.getAddress();
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
          contractAddress: await nft.getAddress(),
          tokenId: 1n,
        },
      };

      // console.log(
      //   "::::::: OWNERS :::::",
      //   await owner.getAddress(),
      //   await palettes.ownerOf(1n),
      //   await manager.isPaletteOwner(1n, await owner.getAddress())
      // );
      // console.log({
      //   palettesAddress: await palettes.getAddress(),
      //   storageAddress: await storage.getAddress(),
      //   paletteManagerAddress: await manager.getAddress(),
      //   nftAddress: nft_address,
      // });
      const signature = await owner.signTypedData(
        typedData.domain,
        typedData.primaryType,
        typedData.message
      );

      // console.log(signature);
      expect(await nft.setPalette(1n, 1n, signature))
        .to.emit(nft, "PaletteSet")
        .withArgs(1n, 1n);

      // console.log("#".repeat(100), "\n", await nft.getRGBPalette(1n));
      // console.log({
      //   palettesAddress: await palettes.getAddress(),
      //   storageAddress: await storage.getAddress(),
      //   paletteManagerAddress: await manager.getAddress(),
      //   nftAddress: nft_address,
      // });
      //
    });

    it("Should deploy the TestERC721 contract", async function () {
      const TestERC721 = await ethers.getContractFactory(
        "TestERC721Upgradeable"
      );
      const testErc721 = await upgrades.deployProxy(TestERC721, [
        await owner.getAddress(),
        await manager.getAddress(),
      ]);
      await testErc721.waitForDeployment();

      await testErc721.mint();
      await testErc721.mint();

      await palettes.mint(1n, [], { value: ethers.parseEther("0.01") });

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
          contractAddress: await testErc721.getAddress(),
          tokenId: 1n,
        },
      };
      const signature = await owner.signTypedData(
        typedData.domain,
        typedData.primaryType,
        typedData.message
      );

      // console.log(signature);
      expect(await testErc721.setPalette(1n, 1n, signature))
        .to.emit(testErc721, "PaletteSet")
        .withArgs(1n, 1n);
    });

    it("Should maintain palette assignment when NFT is transferred to another account", async function () {
      // Mint a palette as owner
      await palettes
        .connect(owner)
        .mint(1n, [], { value: ethers.parseEther("0.01") });

      // Deploy test NFT contract
      const TestERC721 = await ethers.getContractFactory(
        "TestERC721Upgradeable"
      );
      const testErc721 = await upgrades.deployProxy(TestERC721, [
        owner.address,
        await manager.getAddress(),
      ]);
      await testErc721.waitForDeployment();

      // Mint NFT to owner
      await testErc721.mint();

      // Prepare typedData for setting palette
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
          contractAddress: await testErc721.getAddress(),
          tokenId: 1n,
        },
      };

      // Sign with owner since they own the palette
      const signature = await owner.signTypedData(
        typedData.domain,
        typedData.primaryType,
        typedData.message
      );

      // Set palette for the NFT
      await testErc721.setPalette(1n, 1n, signature);

      // Verify palette is set before transfer
      expect(await testErc721.isPaletteSet(1n)).to.be.true;
      const paletteBefore = await testErc721.getPalette(1n);
      expect(paletteBefore).to.have.lengthOf(8);

      // Transfer NFT from owner to account1
      await testErc721
        .connect(owner)
        .transferFrom(owner.address, account1.address, 1n);

      // Verify new owner
      expect(await testErc721.ownerOf(1n)).to.equal(account1.address);

      // Check that palette is still set after transfer
      expect(await testErc721.isPaletteSet(1n)).to.be.true;
      const paletteAfter = await testErc721.getPalette(1n);
      expect(paletteAfter).to.have.lengthOf(8);
      // Verify the palette colors are the same
      expect(paletteAfter).to.deep.equal(paletteBefore);
    });
  });
});
