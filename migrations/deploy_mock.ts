import { MockUSDT } from "./../typechain-types/contracts/MockUSDT"
import { ethers } from "hardhat"

async function deploy() {
	const [deployer] = await ethers.getSigners()

	console.log("Deploying contracts with the account:", deployer.address)

	// We get the contract to deploy
	const MockUSDT = await ethers.getContractFactory("MockUSDT")
	const mockUSDT = await MockUSDT.deploy(ethers.parseEther("10000"))

	console.log("MockUSDT deployed to:", await mockUSDT.getAddress())
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
deploy()
	.then(() => process.exit(0))
	.catch((error) => {
		console.error(error)
		process.exit(1)
	})
