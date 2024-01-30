// Testing Palette.sol contract:
const {  ethers, upgrades } = require("hardhat");
const { expect } = require("chai");

describe("Palette contract", async () => {
  let palettes;
  let renderer;
  let _name='Palettes';
  let _symbol='PAL';
  let account1,otheraccounts;
  beforeEach(async function () {
    Palettes = await ethers.getContractFactory("Palettes");
    const utilsCF = await ethers.getContractFactory("Utils");
    const utils = await utilsCF.deploy();
    await utils.waitForDeployment();
    console.log(await utils.getAddress())
    const Renderer = await ethers.getContractFactory("PaletteRenderer", {
      libraries:{
        Utils: await utils.getAddress(),
      }});
    renderer = await Renderer.deploy();
    await renderer.waitForDeployment();
    [owner, account1, ...otheraccounts] = await ethers.getSigners();

    palettes = await upgrades.deployProxy(Palettes, [owner.address, await renderer.getAddress()]);
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
      // expect(await palettes.ownerOf(ethers.BigNumber.from(1))).to.equal(address1);     
      const tx2  = await palettes.mint();
      tx2.wait()

      // console.log(await palettes.paletteToString(ethers.BigNumber.from(1)))
      console.log(await palettes.image(1n))
      // console.log(await palettes.image(ethers.BigNumber.from(2)))
      
      expect( await palettes.balanceOf( owner.address ) ).to.equal( 1n );
    });

    it("Should mint 10", async function () {
      const maxMint = 10;
      for( let i=0; i<maxMint; i++) {
        // const signer = (await ethers.getSigners())[i]
        // const tx1  = await palettes.connect(signer).mint();
        const tx1  = await palettes.mint();
        tx1.wait()
        console.log(await palettes.image((BigInt(i+1))))
        // console.log(await palettes.webPalette(ethers.BigNumber.from(i+1)))
      }
      

      console.log(await palettes.image(1n))
      // console.log(await palettes.image(ethers.BigNumber.from(50)))
      console.log(await palettes.rgbPalette(1n))
      console.log(await palettes.webPalette(1n))
      expect( await palettes.minted()).to.equal( maxMint);
      
    });
  });
});