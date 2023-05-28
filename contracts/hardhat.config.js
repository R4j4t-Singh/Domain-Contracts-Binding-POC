require("@nomicfoundation/hardhat-toolbox");
require("hardhat-deploy")
require("dotenv").config()

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  solidity: "0.8.17",
  defaultNetwork: "hardhat",
  mocha: {
    timeout: "200000"
  },
  networks: {
    "hardhat" : {
      chainId: 31337,
    },
    "sepolia" : {
      url: process.env.SEPOLIA_RPC_URL,
      blockchainConfirmations: 6,
      chainId: 11155111,
      accounts: [process.env.PRIVATE_KEY, process.env.SECOND_PRIVATE_KEY],
      saveDeployments: true,
    },
  },
  namedAccounts: {
    deployer: {
      default: 0,
    },
    newAdmin : {
      default: 1
    }
  }
};
