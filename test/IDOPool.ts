// Import necessary modules and contracts
import { Signer, parseEther } from "ethers"
import { ethers } from "hardhat"
import { expect } from "chai"
import { FeeToken, IDOPool, IERC20, MockUSDT } from "typechain-types"

describe("IDOPool", () => {
	const ADDRESS__UNISWAP_V2_ROUTER = "0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D"
	const ADDRESS__UNISWAP_V2_FACTORY = "0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f"

	let deployer: Signer, alice: Signer, bob: Signer
	let rewardToken: FeeToken
	let buyToken: MockUSDT
	let idoPool: IDOPool

	const rewardTokenPrice = ethers.parseEther("10") // 10 buy tokens per reward token
	const softCap = ethers.parseEther("300")
	const hardCap = ethers.parseEther("700")

	before(async () => {
		;[deployer, alice, bob] = await ethers.getSigners()

		// Define timestamps
		const startTimestamp = (await ethers.provider.getBlock("latest"))?.timestamp + 100 // start in the future
		const endTimestamp = startTimestamp + 200 // end after 5 minutes
		const claimTimestamp = endTimestamp + 200 // claim after end

		const FeeTokenFactory = await ethers.getContractFactory("FeeToken")
		rewardToken = await FeeTokenFactory.connect(deployer).deploy("DogToken", "DTK", ethers.parseEther("1000"))

		const MockUSDT = await ethers.getContractFactory("MockUSDT")
		buyToken = await MockUSDT.deploy(ethers.parseEther("1000"))

		const IDOPoolFactory = await ethers.getContractFactory("IDOPool")
		idoPool = await IDOPoolFactory.connect(deployer).deploy(
			deployer,
			{
				rewardToken: rewardToken,
				rewardTokenPrice: rewardTokenPrice,
				buyToken: buyToken,
				buyTokenSupply: 0,
				softCap: softCap,
				hardCap: hardCap,
			},
			{
				startTimestamp: startTimestamp,
				endTimestamp: endTimestamp,
				claimTimestamp: claimTimestamp,
			},
			{
				router: ADDRESS__UNISWAP_V2_ROUTER,
				factory: ADDRESS__UNISWAP_V2_FACTORY,
			}
		)

		await rewardToken.connect(deployer).transfer(idoPool, ethers.parseEther("1000"))
	})

	it("test stake function before starting", async () => {
		await expect(idoPool.connect(alice).stake(ethers.parseEther("100"))).to.be.revertedWith("Project not started")
	})

	it("test stake function", async () => {
		await ethers.provider.send("evm_increaseTime", [200]) // add 200 seconds
		await ethers.provider.send("evm_mine")

		await buyToken.connect(deployer).transfer(alice, ethers.parseEther("500"))
		await buyToken.connect(deployer).transfer(bob, ethers.parseEther("500"))

		await buyToken.connect(alice).approve(idoPool, ethers.parseEther("100"))
		await buyToken.connect(bob).approve(idoPool, ethers.parseEther("100"))

		await idoPool.connect(alice).stake(ethers.parseEther("100"))
		await idoPool.connect(bob).stake(ethers.parseEther("100"))

		const aliceInfo = await idoPool.userInfo(alice)
		const bobInfo = await idoPool.userInfo(bob)

		expect(aliceInfo.stakedAmount).to.be.equal(ethers.parseEther("100"))
		expect(bobInfo.stakedAmount).to.be.equal(ethers.parseEther("100"))
	})

	it("test refund function before ending", async () => {
		await expect(idoPool.connect(alice).refund()).to.be.revertedWith("Project not ended yet")
	})

	it("test refund function", async () => {
		await ethers.provider.send("evm_increaseTime", [200]) // add 200 seconds
		await ethers.provider.send("evm_mine")

		await idoPool.connect(alice).refund()

		const userInfo = await idoPool.userInfo(alice)

		expect(userInfo.stakedAmount).to.be.equal(ethers.parseEther("0"))
	})

	it("test claim function before claiming", async () => {
		await expect(idoPool.connect(alice).claim()).to.be.revertedWith("Project not claimable")
	})

	it("test claim function when project failed", async () => {
		await ethers.provider.send("evm_increaseTime", [200]) // add 200 seconds
		await ethers.provider.send("evm_mine")

		await expect(idoPool.connect(alice).claim()).to.be.revertedWith("Project is not succeed")
	})

	it("test claim function with no stake", async () => {
		// Change the soft cap limition

		await idoPool.setSoftCap(ethers.parseEther("100"))

		await expect(idoPool.connect(alice).claim()).to.be.revertedWith("You have no staked amount")
	})

	it("test claim function", async () => {
		await idoPool.connect(bob).claim()

		const bobInfo = await idoPool.userInfo(bob)

		expect(bobInfo.hasClaimed).to.be.true
	})

	it("test withdraw function", async () => {
		expect(await rewardToken.balanceOf(idoPool)).to.be.equal(ethers.parseEther("990"))

		expect(await buyToken.balanceOf(idoPool)).to.be.equal(ethers.parseEther("100"))

		expect((await idoPool.tokenInfo()).buyTokenSupply).to.be.equal(ethers.parseEther("100"))

		await idoPool.connect(deployer).withdraw()
	})
})
