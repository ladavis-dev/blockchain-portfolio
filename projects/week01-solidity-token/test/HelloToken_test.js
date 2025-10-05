const { expect } = require("chai");

describe("HelloToken", function () {
  it("Should assign the total supply to the deployer", async function () {
    const [owner] = await ethers.getSigners();
    const HelloToken = await ethers.getContractFactory("HelloToken");
    const token = await HelloToken.deploy(1000);
    await token.deployed();

    const ownerBalance = await token.balanceOf(owner.address);
    expect(await token.totalSupply()).to.equal(ownerBalance);
  });
});

