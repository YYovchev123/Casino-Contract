const {
  time,
  loadFixture,
} = require("@nomicfoundation/hardhat-toolbox/network-helpers");
const { anyValue } = require("@nomicfoundation/hardhat-chai-matchers/withArgs");
const { expect } = require("chai");

describe("Casino", function () {
  async function deployOneYearLockFixture() {
    const initialAmount = hre.ethers.parseEther("0.001");

    // Contracts are deployed using the first signer/account by default
    const [owner, accOne, accTwo, accThree, accFour] =
      await ethers.getSigners();

    const Casino = await ethers.getContractFactory("Casino");
    const casino = await Casino.deploy({ value: initialAmount });

    return { casino, owner, accOne, accTwo, accThree, accFour };
  }

  // describe("Modifiers", function() {
  //   it("")
  // })

  describe("Deployment", function () {
    it("Should set the right owner", async function () {
      const { casino, owner } = await loadFixture(deployOneYearLockFixture);

      await expect(await casino.owner()).to.equal(owner.address);
    });
  });

  describe("Enter Game", function () {
    it("Should revert if amount isn't right", async function () {
      const { casino, accOne } = await loadFixture(deployOneYearLockFixture);

      await expect(
        casino.connect(accOne).enterGame(42, { value: 1 })
      ).to.be.revertedWith("0.1 ether required");
    });

    it("Should revert if lobby is full", async function () {
      const { casino, owner, accOne, accTwo, accThree, accFour } =
        await loadFixture(deployOneYearLockFixture);

      await casino.connect(accOne).enterGame(41, { value: 10000000000000 });
      await casino.connect(accTwo).enterGame(71, { value: 10000000000000 });
      await casino.connect(accThree).enterGame(12, { value: 10000000000000 });
      await casino.connect(accFour).enterGame(52, { value: 10000000000000 });

      await expect(
        casino.connect(owner).enterGame(52, { value: 10000000000000 })
      ).to.be.revertedWith("Lobby is full");
    });

    it("Should revert when prediction is higher than 100", async function () {
      const { casino, accOne } = await loadFixture(deployOneYearLockFixture);

      await expect(
        casino.connect(accOne).enterGame(120, { value: 10000000000000 })
      ).to.be.revertedWith("100 is the max guess");
    });

    it("Should revert if player enters twice", async function () {
      const { casino, accOne } = await loadFixture(deployOneYearLockFixture);
      await casino.connect(accOne).enterGame(41, { value: 10000000000000 });

      await expect(
        casino.connect(accOne).enterGame(52, { value: 10000000000000 })
      ).to.be.revertedWith("Player has already entered");
    });

    it("Should revert if the number is already predicted", async function () {
      const { casino, accOne, accTwo } = await loadFixture(
        deployOneYearLockFixture
      );
      await casino.connect(accOne).enterGame(41, { value: 10000000000000 });

      await expect(
        casino.connect(accTwo).enterGame(41, { value: 10000000000000 })
      ).to.be.revertedWith("Number already predicted");
    });
  });
  describe("Start Game", function () {
    it("Should revert if the lobby isn't full", async function () {
      const { casino, owner, accOne, accTwo } = await loadFixture(
        deployOneYearLockFixture
      );
      await casino.connect(accOne).enterGame(41, { value: 10000000000000 });
      await casino.connect(accTwo).enterGame(71, { value: 10000000000000 });

      await expect(casino.connect(owner).startGame()).to.be.revertedWith(
        "Lobby isn't filled"
      );
    });

    // FIX
    it("Should revert if the game has already started", async function () {
      const { casino, owner, accOne, accTwo, accThree, accFour } =
        await loadFixture(deployOneYearLockFixture);

      await casino.connect(accOne).enterGame(41, { value: 10000000000000 });
      await casino.connect(accTwo).enterGame(71, { value: 10000000000000 });
      await casino.connect(accThree).enterGame(12, { value: 10000000000000 });
      await casino.connect(accFour).enterGame(52, { value: 10000000000000 });
      await casino.connect(owner).startGame();

      await expect(casino.connect(owner).startGame()).to.be.revertedWith(
        "Game already started"
      );
    });
  });
});
