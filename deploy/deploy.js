const { ethers } = require("hardhat");
const hre = require("hardhat");
const fs = require("fs");

async function main() {
    const [deployer] = await ethers.getSigners();
    const balance = await deployer.getBalance();
    const Marketplace = await ethers.getContractFactory('NFTDepotMarketplace');
    const marketplace = await Marketplace.deploy('NFTDepot');

    const data = {
        address: marketplace.address,
        abi: JSON.parse(marketplace.interface.format('json'))
    }

    // This writes the ABI and Address to the marketplace.json
    fs.writeFileSync('./src/Marketplace.json', JSON.stringify(data))
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });