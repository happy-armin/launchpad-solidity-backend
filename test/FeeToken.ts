// Import necessary modules and contracts
import { Signer, parseEther } from "ethers";
import { ethers } from "hardhat";
import { expect } from "chai";
import { FeeToken } from "typechain-types";

// Describe the test suite for the FeeToken contract
describe("FeeToken", () => {
  // Declare variables for the deployer and the FeeToken contract instance
  let deployer: Signer;
  let feeToken: FeeToken;

  // Run before each test
  before(async () => {
    // Get the first signer from the Hardhat environment
    [deployer] = await ethers.getSigners();

    // Create a contract factory for the FeeToken contract
    const FeeTokenFactory = await ethers.getContractFactory("FeeToken");

    // Deploy the FeeToken contract with the deployer as the signer
    feeToken = await FeeTokenFactory.connect(deployer).deploy(
      "FeeToken",
      "FTK",
      ethers.parseEther("1000")
    );
  });

  // Test case to check the total supply of the FeeToken contract
  it("test after construction", async () => {
    // Check if the total supply of the FeeToken contract is equal to 1000 ETH
    expect(await feeToken.totalSupply()).to.equal(ethers.parseEther("1000"));
  });
});
