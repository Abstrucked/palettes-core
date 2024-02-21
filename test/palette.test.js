// Testing Palettes.sol contract:
const {  ethers, upgrades } = require("hardhat");
const { expect } = require("chai");
const fs = require('node:fs');
describe("Palette contract", async () => {
  let palettes;
  let renderer;
  let _name='Palettes';
  let _symbol='PAL';
  let owner, account1,otherAccounts;
  beforeEach(async function () {
    const utilsCF = await ethers.getContractFactory("Utils");
    const utils = await utilsCF.deploy();
    await utils.waitForDeployment();
    const ColorsLib = await ethers.getContractFactory("Colors");
    const colorsLib = await ColorsLib.deploy();

    await colorsLib.waitForDeployment();
    console.log(await utils.getAddress())
    const Renderer = await ethers.getContractFactory("PaletteRenderer");
    renderer = await Renderer.deploy();
    await renderer.waitForDeployment();
    [owner, account1, ...otherAccounts] = await ethers.getSigners();
    let Palettes = await ethers.getContractFactory("Palettes");
    palettes = await upgrades.deployProxy(Palettes, [owner.address]);
    await palettes.waitForDeployment();


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
      const tx1  = await palettes.connect(account1).mint();
      tx1.wait()
      const tx2  = await palettes.connect(account1).mint();
      tx2.wait()

      console.log(await palettes.tokenURI(1n))
      expect( await palettes.balanceOf( account1.address ) ).to.equal( 2n );
    });

    it("Should mint 10", async function () {
      const maxMint = 10;
      for( let i=0; i<maxMint; i++) {
        // const signer = (await ethers.getSigners())[i]
        // const tx1  = await palettes.connect(signer).mint();
        const tx1  = await palettes.mint();
        tx1.wait()
        // console.log(await palettes.svg((BigInt(i+1))))
        fs.writeFileSync(`palette${i+1}.svg`, await palettes.svg(i+1))
        // console.log(await palettes.webPalette(ethers.BigNumber.from(i+1)))
      }
      

      // console.log(await palettes.svg(1n))
      // console.log(await palettes.image(ethers.BigNumber.from(50)))
      // console.log(await palettes.rgbPalette(1n))
      // console.log(await palettes.webPalette(1n))
      // console.log(await palettes.tokenURI(1n));
      expect( await palettes.minted()).to.equal( maxMint);
      
    });
    it("Should set the record for an NFT", async function () {
      let NFT = await ethers.getContractFactory("TestERC721");
      const PaletteManager = await ethers.getContractFactory("PaletteManager");
      const paletteManager = await upgrades.deployProxy(PaletteManager, [owner.address, await palettes.getAddress()]);
      await paletteManager.waitForDeployment();
      await palettes.setPaletteManager(await paletteManager.getAddress());
      const nft = await NFT.deploy(await paletteManager.getAddress(), await palettes.getAddress());
      await nft.waitForDeployment();
      // console.log(await nft.getAddress(), await nft.name(), await nft.symbol());
      await palettes.mint()
      const p_address = await palettes.getAddress();
      const nft_address = await nft.getAddress();
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
          name: "PaletteManager",
          version: "1",
          chainId: BigInt(31337).toString(),
          verifyingContract: await paletteManager.getAddress(),
        },
        message: {
          paletteId: 1n,
          contractAddress: nft_address,
          tokenId: 1n,
        },
      };

      console.log(await owner.getAddress(), await palettes.ownerOf(1n));
      const signature = await owner.signTypedData(typedData.domain, typedData.primaryType, typedData.message)
      // const signature = await ethers.provider.send("eth_signTypedData_v4", [
      //   await owner.getAddress(),
      //   msgData
      // ])
      console.log(signature)
      expect(await nft.setPalette(1n, 1n, signature)).to.emit(nft, "PaletteSet").withArgs(1n, 1n,);

      console.log({
        palettesAddress: p_address,
        paletteManagerAddress: await paletteManager.getAddress(),
        nftAddress: nft_address
      })

      console.log(await nft.getPalette(1n));

      // console.log(await palettes.eip712Domain());
      // const [h, n, v, i,  c, s] = await palettes.eip712Domain();
      // //
      // // const webPalette = await nft.getPalette(1n);
      // // console.log(webPalette);
      // return c === p_address;
    });
  });
});