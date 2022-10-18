const { ethers } = require("hardhat");
const hre = require("hardhat");
const fs = require("fs");

async function main() {
    const [deployer] = await ethers.getSigners();
    const balance = await deployer.getBalance();
    const Marketplace = await ethers.getContractFactory('NFTDepotMarketplace');
    const marketplace = await Marketplace.deploy('NFTDepot');

    // const NFT = await ethers.getContractFactory('testNFT');
    // const nft = await NFT.deploy();

    await marketplace.deployed();
    // await nft.deployed();

    const data = {
        address: marketplace.address,
        abi: JSON.parse(marketplace.interface.format('json'))
    }

    // const nftdata = {
    //     address: nft.address,
    //     abi: JSON.parse(nft.interface.format('json'))
    // }

    // This writes the ABI and Address to the marketplace.json
    fs.writeFileSync('./src/Marketplace.json', JSON.stringify(data))
    // fs.writeFileSync('./src/NFT.json', JSON.stringify(nftdata))
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });