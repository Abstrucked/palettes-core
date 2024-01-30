require("@nomicfoundation/hardhat-toolbox");
require("dotenv").config();
require("@nomicfoundation/hardhat-ledger");
require("hardhat-gas-reporter");

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  solidity: "0.8.20",
  settings: {
    optimizer: {
      enabled: true,
      runs: 200
    }
  },
  gasReporter: {
    currency: 'USD',
    showMethodSig: true,
    coinmarketcap: process.env.COINMARKETCAP_APIKEY,
    token: 'ETH',
    gasPriceApi: 'https://api.etherscan.io/api?module=proxy&action=eth_gasPrice',
    enabled: (process.env.REPORT_GAS) ? true : false
  },
  sourcify: {
    // Disabled by default
    // Doesn't need an API key
    enabled: true
  },
  networks: {
    hardhat: {
      ledgerAccounts: [
        "0x307E2701D27032E0663a704B3396163331DD6F72",
        "0xe4e1aEF9c352a6A56e39f502612cA88a3441CFA5",
      ],
    },
  }
};

if(process.env.MAINNET) {
  module.exports.networks.ethereum =  {
    url: process.env.MAINNET,
    ledgerAccounts: [
      "0x307E2701D27032E0663a704B3396163331DD6F72",
    ],
  }
}

if(process.env.ARBITRUM) {
  module.exports.networks.arbitrum =  {
    url: process.env.ARBITRUM,
    ledgerAccounts: [
      "0x307E2701D27032E0663a704B3396163331DD6F72",
    ],
  }
}

if (process.env.SEPOLIA) {
  module.exports.networks.sepolia = {
    url: process.env.SEPOLIA,
    ledgerAccounts: [
      "0x307E2701D27032E0663a704B3396163331DD6F72",
    ],
    // accounts: [
    //   process.env.PRIVATE_KEY
    // ]
  };
}

if (process.env.ETHERSCAN_APIKEY) {
  module.exports.etherscan = {
    apiKey: process.env.ETHERSCAN_APIKEY,
  }
}