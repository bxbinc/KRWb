'use strict';

require('babel-register');
require('babel-polyfill');
require("dotenv").config();

const HDWalletProvider = require("truffle-hdwallet-provider");

module.exports = {
    networks: {
        local: {
            host: 'localhost',
            port: 7545,
            gas: 5000000,
            gasPrice: 5e9,
            network_id: '*'
        },
        ropsten: {
            provider: () =>
                new HDWalletProvider(process.env.ROPSTEN_MNEMONIC, process.env.ROPSTEN_PROVIDER_URL, 0, 10),
            network_id: 3,
            gasPrice: 20000000000
        },
        coverage: {
            host: "localhost",
            network_id: "*",
            port: 8555,         // <-- If you change this, also set the port option in .solcover.js.
            gas: 0xfffffffffff, // <-- Use this high gas value
            gasPrice: 0x01      // <-- Use this low gas price
        }
    }
};
