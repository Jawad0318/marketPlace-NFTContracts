require('@nomicfoundation/hardhat-toolbox');
require('dotenv').config();
require('@nomiclabs/hardhat-etherscan');

const PK = process.env.PRIVATE_KEY
const URL = process.env.RPC_URL
/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  solidity: '0.8.7',
  networks: {
    hardhat: {
      chainId: 1337
    },
    mumbai: {
      url: process.env.RPC_URL,
      accounts: [process.env.PRIVATE_KEY],
    },
  },
  etherscan: {
    apiKey: process.env.APIKEY,
  },
  customChains: [
    {
      network: 'polygonMumbai',
      chainId: 80001,
      urls: {
        apiURL: 'https://api-testnet.polygonscan.com',
        browserURL: 'https://mumbai.polygonscan.com',
      },
    },
  ],
};