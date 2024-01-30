
/**
 * Data price check
 * 
 * Ethereum -     0xbbCF401Bd6434B7Cff4c18e1D92E51816Ecc37D4
 * Arbitrum One - 0xF6A39693691B1F4fBeb77BFda23CFbD4bBF2bCfc
 */
const {  ethers, waffle } = require("hardhat");
const { expect } = require("chai");

describe("Palette contract", async () => {
  let AEFToken;
  let token721;
  let renderer;
  let _name='Palettes';
  let _symbol='PAL';
  let MAX_SUPPLY = 10;
  let account1,otheraccounts;
  let data;
  beforeEach(async function () {
    PALToken = await ethers.getContractFactory("Palettes");
    const utilsCF = await ethers.getContractFactory("Utils");
    const utils = await utilsCF.deploy();
    await utils.waitForDeployment();
    console.log(await utils.getAddress())
    RNDToken = await ethers.getContractFactory("PaletteRenderer", {
      libraries:{
        Utils: await utils.getAddress(),
      }});
    renderer = await RNDToken.deploy();
    await renderer.waitForDeployment();
    [owner, account1, ...otheraccounts] = await ethers.getSigners();

    token721 = await PALToken.deploy(await renderer.getAddress());
    await token721.waitForDeployment();
    // const bg = ethers.BigNumber.from("000001")
    // console.log(bg)
    // const p = "thisisthepalette"
    // const palette = ethers.utils.defaultAbiCoder.encode(['string'], [p.toString()])
    // data = ethers.utils.defaultAbiCoder.encode(['uint256', 'uint256', 'uint8', 'uint32', 'bytes' ], [bg, bg, 8, 5000, palette] )

  });

  describe("Should Deploy", async function () {

    it("Should have the correct name and symbol ", async function () {
      expect(await token721.name()).to.equal(_name);
      expect(await token721.symbol()).to.equal(_symbol);
    });
    
    // it("Should set the sale to open", async function () {
    //   await expect(await token721.toggleSale()).to.emit(token721, "SaleStateChange").withArgs(true);
    // })
    
    // it("Should revert with error SaleIsClosed()", async function () {
    //   const address1=account1.address;
    //   let response =  token721.mint(address1, ethers.utils.id("firstNFT"));
    //       await expect(response).to.be.revertedWith("SaleIsClosed()");
       
    // })

    it("Should mint a token with token ID 1 & 2 to account1", async function () {
      const address1 = account1.address;
      
      
      const tx1  = await token721.connect(account1).mint();
      tx1.wait()
      // expect(await token721.ownerOf(ethers.BigNumber.from(1))).to.equal(address1);     
      const tx2  = await token721.mint();
      tx2.wait()

      // console.log(await token721.paletteToString(ethers.BigNumber.from(1)))
      console.log(await token721.image(1n))
      // console.log(await token721.image(ethers.BigNumber.from(2)))
      
      expect( await token721.balanceOf( owner.address ) ).to.equal( 1n );
    });

    it("Should mint 10", async function () {
      const address1 = account1.address;

      for( let i=0; i<10; i++) {
        const signer = (await ethers.getSigners())[i]
        const tx1  = await token721.connect(signer).mint();
        tx1.wait()  
        console.log(await token721.image((BigInt(i+1))))
        // console.log(await token721.webPalette(ethers.BigNumber.from(i+1)))
      }
      

      console.log(await token721.image(1n))
      // console.log(await token721.image(ethers.BigNumber.from(50)))
      console.log(await token721.rgbPalette(1n))
      console.log(await token721.webPalette(1n))
      expect( await token721.minted()).to.equal( 10n);
      
    });
  });
});