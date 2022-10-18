require("@nomicfoundation/hardhat-toolbox");
require("dotenv").config();

const PK = process.env.PRIVATE_KEY
const URL = process.env.RPC_URL
/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  networks: {
    hardhat: {
      chainId: 1337
    },
    mumbai: {
      url: URL,
      accounts: [PK]
    },
  },
  solidity: "0.8.7",
};