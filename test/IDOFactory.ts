import { Signer, parseEther } from "ethers"
import { ethers } from "hardhat"
import { expect } from "chai"
import { IDOFactory } from "typechain-types"

describe("IDOFactory", () => {
	let deployer: Signer, alice: Signer
	let idoFactory: IDOFactory

	before(async () => {
		;[deployer, alice] = await ethers.getSigners()

		const IDOFactoryFactory = await ethers.getContractFactory("IDOFactory")
		idoFactory = await IDOFactoryFactory.connect(deployer).deploy(deployer)
	})

	it("test createIDO", async () => {
		const ido = await idoFactory.connect(alice).createIDO(
			{
				feeName: "TestFee",
				feeSymbol: "TEST",
				feeSupply: ethers.parseEther("1000"),
			},
			{
				rewardToken: "0x7cb8e2bfa6cb7c7ec1d6d8f8d3e7b7d5f5b9f9d1",
				rewardTokenPrice: parseEther("10"),
				buyToken: "0x7cb8e2bfa6cb7c7ec1d6d8f8d3e7b7d5f5b9f9d1",
				buyTokenSupply: ethers.parseEther("0"),
				softCap: ethers.parseEther("200"),
				hardCap: ethers.parseEther("500"),
			},
			{
				startTimestamp: Math.floor(Date.now() / 1000) + 3600,
				endTimestamp: Math.floor(Date.now() / 1000) + 7200,
				claimTimestamp: Math.floor(Date.now() / 1000) + 10800,
			},
			{
				router: "0x7cb8e2bfa6cb7c7ec1d6d8f8d3e7b7d5f5b9f9d1",
				factory: "0x7cb8e2bfa6cb7c7ec1d6d8f8d3e7b7d5f5b9f9d1",
			},
			"https://gateway.pinata.cloud/ipfs/QmST6e7bZLgeSizmvqGRS5x8aqt4GiSbzEj421NMfiWo6f"
		)

		await expect(ido).to.be.emit(idoFactory, "IDOCreated")
	})
})
