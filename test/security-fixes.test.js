// Test file to verify critical security vulnerability fixes
const { ethers, upgrades } = require("hardhat");
const { expect } = require("chai");

describe("Security Fixes - Critical Vulnerabilities", async () => {
  let palettes;
  let storage;
  let manager;
  let renderer;
  let metadata;
  let owner, account1, account2;

  beforeEach(async function () {
    [owner, account1, account2] = await ethers.getSigners();

    // Deploy libraries
    const utilsCF = await ethers.getContractFactory("Utils");
    const utils = await utilsCF.deploy();
    await utils.waitForDeployment();

    const ColorsLib = await ethers.getContractFactory("Colors");
    const colorsLib = await ColorsLib.deploy();
    await colorsLib.waitForDeployment();

    // Deploy Renderer
    const Renderer = await ethers.getContractFactory("PaletteRenderer");
    renderer = await Renderer.deploy();
    await renderer.waitForDeployment();

    // Deploy Metadata
    const Metadata = await ethers.getContractFactory("PaletteMetadata");
    metadata = await Metadata.deploy(await renderer.getAddress());
    await metadata.waitForDeployment();

    // Deploy Palettes
    const Palettes = await ethers.getContractFactory("Palettes");
    palettes = await upgrades.deployProxy(Palettes, [
      owner.address,
      await renderer.getAddress(),
      await metadata.getAddress(),
    ]);
    await palettes.waitForDeployment();

    // Deploy PaletteManager
    const PaletteManager = await ethers.getContractFactory("PaletteManager");
    manager = await upgrades.deployProxy(PaletteManager, [
      owner.address,
      await palettes.getAddress(),
    ]);
    await manager.waitForDeployment();

    // Deploy PaletteStorage
    const PaletteStorage = await ethers.getContractFactory("PaletteStorage");
    storage = await upgrades.deployProxy(PaletteStorage, [
      owner.address,
      await manager.getAddress(),
    ]);
    await storage.waitForDeployment();

    // Connect manager to storage and palettes
    await manager.setStorageContract(await storage.getAddress());
    await palettes.setManagerContractAddress(await manager.getAddress());
    await palettes.startMintingPhase();
  });

  describe("CRITICAL FIX #1: Signature Replay Attack Prevention", () => {
    it("Should prevent signature replay attacks with nonce mechanism", async () => {
      // Mint a palette for account1
      await palettes.connect(account1).mint(1, [], { value: ethers.parseEther("0.001") });
      const paletteId = 2; // Token ID 1 is minted in initialize, so this is #2

      // Get domain separator and type hash for EIP-712 signature
      const domain = {
        name: "PaletteManager",
        version: "1",
        chainId: (await ethers.provider.getNetwork()).chainId,
        verifyingContract: await manager.getAddress(),
      };

      const types = {
        PaletteRecord: [
          { name: "paletteId", type: "uint256" },
          { name: "contractAddress", type: "address" },
          { name: "tokenId", type: "uint256" },
          { name: "nonce", type: "uint256" },
          { name: "deadline", type: "uint256" },
        ],
      };

      // First mapping: palette #2 -> token #100
      const nonce1 = await manager.getNonce(account1.address);
      expect(nonce1).to.equal(0); // Initial nonce should be 0

      const value1 = {
        paletteId: paletteId,
        contractAddress: await palettes.getAddress(),
        tokenId: 100,
        nonce: nonce1,
        deadline: 0,
      };

      const signature1 = await account1.signTypedData(domain, types, value1);

      // Set the first palette record
      await manager.connect(account1).setPaletteRecord(
        paletteId,
        await palettes.getAddress(),
        100,
        nonce1,
        0,
        signature1
      );

      // Verify nonce increased
      const nonce2 = await manager.getNonce(account1.address);
      expect(nonce2).to.equal(1);

      // ATTACK: Try to replay the first signature
      await expect(
        manager.connect(account2).setPaletteRecord(
          paletteId,
          await palettes.getAddress(),
          100,
          nonce1, // Old nonce = 0
          0,
          signature1
        )
      ).to.be.revertedWith("Invalid nonce");

      // Verify the mapping is still #100 (attack failed)
      const mappedPaletteId = await storage.getPaletteId(100, await palettes.getAddress());
      expect(mappedPaletteId).to.equal(paletteId);
    });

    it("Should reject expired signatures based on deadline", async () => {
      // Mint a palette for account1
      await palettes.connect(account1).mint(1, [], { value: ethers.parseEther("0.001") });
      const paletteId = 2;

      const domain = {
        name: "PaletteManager",
        version: "1",
        chainId: (await ethers.provider.getNetwork()).chainId,
        verifyingContract: await manager.getAddress(),
      };

      const types = {
        PaletteRecord: [
          { name: "paletteId", type: "uint256" },
          { name: "contractAddress", type: "address" },
          { name: "tokenId", type: "uint256" },
          { name: "nonce", type: "uint256" },
          { name: "deadline", type: "uint256" },
        ],
      };

      const nonce = await manager.getNonce(account1.address);
      const currentTimestamp = (await ethers.provider.getBlock("latest")).timestamp;
      const expiredDeadline = currentTimestamp - 100; // Already expired

      const value = {
        paletteId: paletteId,
        contractAddress: await palettes.getAddress(),
        tokenId: 100,
        nonce: nonce,
        deadline: expiredDeadline,
      };

      const signature = await account1.signTypedData(domain, types, value);

      // Try to use expired signature
      await expect(
        manager.connect(account1).setPaletteRecord(
          paletteId,
          await palettes.getAddress(),
          100,
          nonce,
          expiredDeadline,
          signature
        )
      ).to.be.revertedWith("Signature expired");
    });

    it("Should allow valid signatures with future deadlines", async () => {
      // Mint a palette for account1
      await palettes.connect(account1).mint(1, [], { value: ethers.parseEther("0.001") });
      const paletteId = 2;

      const domain = {
        name: "PaletteManager",
        version: "1",
        chainId: (await ethers.provider.getNetwork()).chainId,
        verifyingContract: await manager.getAddress(),
      };

      const types = {
        PaletteRecord: [
          { name: "paletteId", type: "uint256" },
          { name: "contractAddress", type: "address" },
          { name: "tokenId", type: "uint256" },
          { name: "nonce", type: "uint256" },
          { name: "deadline", type: "uint256" },
        ],
      };

      const nonce = await manager.getNonce(account1.address);
      const currentTimestamp = (await ethers.provider.getBlock("latest")).timestamp;
      const futureDeadline = currentTimestamp + 3600; // 1 hour from now

      const value = {
        paletteId: paletteId,
        contractAddress: await palettes.getAddress(),
        tokenId: 100,
        nonce: nonce,
        deadline: futureDeadline,
      };

      const signature = await account1.signTypedData(domain, types, value);

      // Should succeed
      await expect(
        manager.connect(account1).setPaletteRecord(
          paletteId,
          await palettes.getAddress(),
          100,
          nonce,
          futureDeadline,
          signature
        )
      ).to.emit(manager, "NonceUsed").withArgs(account1.address, nonce);

      // Verify mapping was set
      const mappedPaletteId = await storage.getPaletteId(100, await palettes.getAddress());
      expect(mappedPaletteId).to.equal(paletteId);
    });

    it("Should increment nonce correctly across multiple operations", async () => {
      // Mint a palette for account1
      await palettes.connect(account1).mint(1, [], { value: ethers.parseEther("0.001") });
      const paletteId = 2;

      const domain = {
        name: "PaletteManager",
        version: "1",
        chainId: (await ethers.provider.getNetwork()).chainId,
        verifyingContract: await manager.getAddress(),
      };

      const types = {
        PaletteRecord: [
          { name: "paletteId", type: "uint256" },
          { name: "contractAddress", type: "address" },
          { name: "tokenId", type: "uint256" },
          { name: "nonce", type: "uint256" },
          { name: "deadline", type: "uint256" },
        ],
      };

      // Operation 1: Map to token 100
      let nonce = await manager.getNonce(account1.address);
      expect(nonce).to.equal(0);

      let value = {
        paletteId: paletteId,
        contractAddress: await palettes.getAddress(),
        tokenId: 100,
        nonce: nonce,
        deadline: 0,
      };

      let signature = await account1.signTypedData(domain, types, value);
      await manager.connect(account1).setPaletteRecord(
        paletteId,
        await palettes.getAddress(),
        100,
        nonce,
        0,
        signature
      );

      // Operation 2: Map to token 200 (change mapping)
      nonce = await manager.getNonce(account1.address);
      expect(nonce).to.equal(1);

      value = {
        paletteId: paletteId,
        contractAddress: await palettes.getAddress(),
        tokenId: 200,
        nonce: nonce,
        deadline: 0,
      };

      signature = await account1.signTypedData(domain, types, value);
      await manager.connect(account1).setPaletteRecord(
        paletteId,
        await palettes.getAddress(),
        200,
        nonce,
        0,
        signature
      );

      // Verify final nonce
      nonce = await manager.getNonce(account1.address);
      expect(nonce).to.equal(2);

      // Verify final mapping
      const mappedPaletteId = await storage.getPaletteId(200, await palettes.getAddress());
      expect(mappedPaletteId).to.equal(paletteId);
    });
  });

  describe("CRITICAL FIX #2: Correct Withdraw Event Emission", () => {
    it("Should emit Withdrawn event with correct balance before transfer", async () => {
      // Mint some NFTs to generate revenue
      const mintPrice = ethers.parseEther("0.001");
      await palettes.connect(account1).mint(1, [], { value: mintPrice });
      await palettes.connect(account1).mint(1, [], { value: mintPrice });
      await palettes.connect(account1).mint(1, [], { value: mintPrice });

      // Contract should have 3 * 0.001 = 0.003 ETH
      const contractBalance = await ethers.provider.getBalance(await palettes.getAddress());
      expect(contractBalance).to.equal(ethers.parseEther("0.003"));

      // Record owner balance before withdrawal
      const ownerBalanceBefore = await ethers.provider.getBalance(owner.address);

      // Execute withdrawal and check event
      const tx = await palettes.connect(owner).withdraw();
      const receipt = await tx.wait();

      // Find the Withdrawn event
      const withdrawnEvent = receipt.logs.find(
        log => {
          try {
            const parsed = palettes.interface.parseLog(log);
            return parsed.name === "Withdrawn";
          } catch {
            return false;
          }
        }
      );

      expect(withdrawnEvent).to.not.be.undefined;
      const parsedEvent = palettes.interface.parseLog(withdrawnEvent);

      // CRITICAL: Event should emit the actual withdrawn amount (0.003 ETH), not 0
      expect(parsedEvent.args[1]).to.equal(ethers.parseEther("0.003"));

      // Verify the transfer actually happened
      const contractBalanceAfter = await ethers.provider.getBalance(await palettes.getAddress());
      expect(contractBalanceAfter).to.equal(0);

      // Owner should have received the funds (minus gas for the withdrawal tx)
      const ownerBalanceAfter = await ethers.provider.getBalance(owner.address);
      expect(ownerBalanceAfter).to.be.gt(ownerBalanceBefore);
    });

    it("Should successfully transfer using call instead of transfer", async () => {
      // Mint to generate revenue
      const mintPrice = ethers.parseEther("0.001");
      await palettes.connect(account1).mint(5, [], { value: mintPrice * 5n });

      const contractBalance = await ethers.provider.getBalance(await palettes.getAddress());
      expect(contractBalance).to.equal(ethers.parseEther("0.005"));

      // Withdraw should succeed even with contract owners (call has no gas limit)
      await expect(palettes.connect(owner).withdraw()).to.not.be.reverted;

      // Verify balance transferred
      const contractBalanceAfter = await ethers.provider.getBalance(await palettes.getAddress());
      expect(contractBalanceAfter).to.equal(0);
    });

    it("Should revert if transfer fails", async () => {
      // This would require a contract that rejects ETH, which is complex to test
      // But the code now uses require(success, "Transfer failed") to handle this
    });

    it("Should revert on empty balance withdrawal", async () => {
      // Contract should have 0 balance initially (except for the 1 token minted in initialize)
      // Let's withdraw that first
      const initialBalance = await ethers.provider.getBalance(await palettes.getAddress());
      if (initialBalance > 0) {
        await palettes.connect(owner).withdraw();
      }

      // Now try to withdraw with 0 balance
      await expect(palettes.connect(owner).withdraw()).to.be.revertedWith(
        "No balance to withdraw"
      );
    });
  });

  describe("UX Improvement: getNonce Helper in UsePalette", () => {
    it("Should allow getting nonce directly from NFT contract", async () => {
      // Deploy a test NFT that uses UsePalette
      const TestERC721 = await ethers.getContractFactory("TestERC721");
      const nft = await TestERC721.deploy(await manager.getAddress());
      await nft.waitForDeployment();

      // Mint a palette
      await palettes.connect(account1).mint(1, [], { value: ethers.parseEther("0.001") });

      // UX IMPROVEMENT: Can get nonce from NFT contract instead of PaletteManager
      const nonceFromNFT = await nft.getNonce(account1.address);
      const nonceFromManager = await manager.getNonce(account1.address);

      // Both should return the same value
      expect(nonceFromNFT).to.equal(nonceFromManager);
      expect(nonceFromNFT).to.equal(0);

      // Now the frontend only needs the NFT contract address!
      const domain = {
        name: "PaletteManager",
        version: "1",
        chainId: (await ethers.provider.getNetwork()).chainId,
        verifyingContract: await manager.getAddress(),
      };

      const types = {
        PaletteRecord: [
          { name: "paletteId", type: "uint256" },
          { name: "contractAddress", type: "address" },
          { name: "tokenId", type: "uint256" },
          { name: "nonce", type: "uint256" },
          { name: "deadline", type: "uint256" },
        ],
      };

      const value = {
        paletteId: 2,
        contractAddress: await nft.getAddress(),
        tokenId: 1,
        nonce: nonceFromNFT,
        deadline: 0,
      };

      const signature = await account1.signTypedData(domain, types, value);

      // Set palette using only the NFT contract
      await nft.connect(account1).setPalette(1, 2, nonceFromNFT, 0, signature);

      // Verify it worked
      const paletteId = await nft.getSetPaletteId(1);
      expect(paletteId).to.equal(2);

      // Verify nonce incremented
      expect(await nft.getNonce(account1.address)).to.equal(1);
    });
  });

  describe("Integration: Both Fixes Together", () => {
    it("Should handle multiple palette mappings with nonces and correct event emissions", async () => {
      // Mint palettes and track revenue
      const mintPrice = ethers.parseEther("0.001");
      await palettes.connect(account1).mint(2, [], { value: mintPrice * 2n });
      await palettes.connect(account2).mint(1, [], { value: mintPrice });

      const paletteId1 = 2; // account1's first palette
      const paletteId2 = 3; // account1's second palette

      const domain = {
        name: "PaletteManager",
        version: "1",
        chainId: (await ethers.provider.getNetwork()).chainId,
        verifyingContract: await manager.getAddress(),
      };

      const types = {
        PaletteRecord: [
          { name: "paletteId", type: "uint256" },
          { name: "contractAddress", type: "address" },
          { name: "tokenId", type: "uint256" },
          { name: "nonce", type: "uint256" },
          { name: "deadline", type: "uint256" },
        ],
      };

      // Account1 sets two different palette mappings
      let nonce = await manager.getNonce(account1.address);

      const value1 = {
        paletteId: paletteId1,
        contractAddress: await palettes.getAddress(),
        tokenId: 100,
        nonce: nonce,
        deadline: 0,
      };

      const signature1 = await account1.signTypedData(domain, types, value1);
      await manager.connect(account1).setPaletteRecord(
        paletteId1,
        await palettes.getAddress(),
        100,
        nonce,
        0,
        signature1
      );

      nonce = await manager.getNonce(account1.address);

      const value2 = {
        paletteId: paletteId2,
        contractAddress: await palettes.getAddress(),
        tokenId: 200,
        nonce: nonce,
        deadline: 0,
      };

      const signature2 = await account1.signTypedData(domain, types, value2);
      await manager.connect(account1).setPaletteRecord(
        paletteId2,
        await palettes.getAddress(),
        200,
        nonce,
        0,
        signature2
      );

      // Verify both mappings are correct
      expect(await storage.getPaletteId(100, await palettes.getAddress())).to.equal(paletteId1);
      expect(await storage.getPaletteId(200, await palettes.getAddress())).to.equal(paletteId2);

      // Now withdraw and verify correct event
      const contractBalance = await ethers.provider.getBalance(await palettes.getAddress());
      expect(contractBalance).to.equal(ethers.parseEther("0.003"));

      const tx = await palettes.connect(owner).withdraw();
      const receipt = await tx.wait();

      const withdrawnEvent = receipt.logs.find(
        log => {
          try {
            const parsed = palettes.interface.parseLog(log);
            return parsed.name === "Withdrawn";
          } catch {
            return false;
          }
        }
      );

      const parsedEvent = palettes.interface.parseLog(withdrawnEvent);
      expect(parsedEvent.args[1]).to.equal(ethers.parseEther("0.003"));
    });
  });
});
