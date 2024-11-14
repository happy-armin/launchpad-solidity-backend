import { ethers } from "hardhat"

async function deploy() {
	const [deployer] = await ethers.getSigners()

	console.log("Deploying contracts with the account:", deployer.address)

	// We get the contract to deploy
	const IDOFactory = await ethers.getContractFactory("IDOFactory")
	const idoFactory = await IDOFactory.deploy(deployer)

	console.log("IDOFactory deployed to:", await idoFactory.getAddress())
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
deploy()
	.then(() => process.exit(0))
	.catch((error) => {
		console.error(error)
		process.exit(1)
	})
