require("@nomiclabs/hardhat-waffle");
require("@nomiclabs/hardhat-etherscan");
require("dotenv").config();
require("hardhat-gas-reporter");

// This is a sample Hardhat task. To learn how to create your own go to
// https://hardhat.org/guides/create-task.html
task("accounts", "Prints the list of accounts", async () => {
  const accounts = await ethers.getSigners();

  for (const account of accounts) {
    console.log(account.address);
  }
});

const INFURA_API_KEY =
  process.env.INFURA_API_KEY || "69841a6025c9493a83c583199dc278b3";

// You need to export an object to set up your config
// Go to https://hardhat.org/config/ to learn more

const accounts = [process.env.PRIVATE_KEY];
/**
 * @type import('hardhat/config').HardhatUserConfig
 */
module.exports = {
  defaultNetwork: "hardhat",
  networks: {
    hardhat: {
      forking: {
        enabled: false,
        url: `https://mainnet.infura.io/v3/${INFURA_API_KEY}`,
      },
    },
    rinkeby: {
      url: `https://rinkeby.infura.io/v3/${INFURA_API_KEY}`,
      accounts,
      chainId: 4,
    },
    mainnet: {
      url: `https://mainnet.infura.io/v3/${INFURA_API_KEY}`,
      accounts,
      chainId: 1,
    },
  },
  solidity: {
    version: "0.8.10",
    settings: {
      optimizer: {
        enabled: true,
        runs: 200,
      },
    },
  },
  mocha: {
    timeout: 50000,
  },
  etherscan: {
    apiKey: process.env.ETHERSCAN_KEY || "3CTADIA2WUGFSQAUYI1MKBG2BF3ZSFF156",
  },
};
