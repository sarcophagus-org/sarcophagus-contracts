require('dotenv').config()
const HDWalletProvider = require('@truffle/hdwallet-provider')

module.exports = {
  networks: {
    mainnet: {
      provider: () => new HDWalletProvider({
        privateKeys: [process.env.MAINNET_PK],
        providerOrUrl: process.env.MAINNET_PROVIDER,
      }),
      network_id: '1',
    },
    rinkeby: {
      provider: () => new HDWalletProvider({
        privateKeys: [process.env.RINKEBY_PK],
        providerOrUrl: process.env.RINKEBY_PROVIDER
      }),
      network_id: '4'
    },
    goerli: {
      provider: () => new HDWalletProvider({
        privateKeys: [process.env.GOERLI_PK],
        providerOrUrl: process.env.GOERLI_PROVIDER,
      }),
      network_id: '5',
    },
  },
  compilers: {
    solc: {
      version: '0.8.1',
      settings: {
        optimizer: {
          enabled: true,
          runs: 200,
        },
      },
    },
  },
  plugins: ["solidity-coverage"],
}
