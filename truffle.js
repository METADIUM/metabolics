require('babel-register')

var HDWalletProvider = require("truffle-hdwallet-provider");

const config = require('config')
const _mnemonic = config.get("mnemonic")
const _provider = config.get("provider")
const _network_id = config.get("network_id")
const _gasPrice = config.get("gasPrice")

module.exports = {
  networks: {
    development: {
      host: "localhost",
      port: 8545,
      network_id: "*", // Match any network id
      gas: 10000000
    },
    metadiumTestnet: {
      provider: function () {
        return new HDWalletProvider(_mnemonic, _provider);
      },
      network_id: _network_id,
      gas: 6000000,
      gasPrice: _gasPrice
    }
  },
  solc: {
    optimizer: {
      enabled: true,
      runs: 200
    }
  },
  mocha: {
    reporter: 'eth-gas-reporter',
    reporterOptions: {
      currency: 'USD',
      gasPrice: 21
    }
  }

  // See <http://truffleframework.com/docs/advanced/configuration>
  // to customize your Truffle configuration!
}
