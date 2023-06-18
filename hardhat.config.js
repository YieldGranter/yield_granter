require("@nomiclabs/hardhat-waffle")
require("@nomiclabs/hardhat-etherscan")
require("hardhat-deploy")
require("solidity-coverage")
require("hardhat-gas-reporter")
require("hardhat-contract-sizer")
require("dotenv").config()

/** @type import('hardhat/config').HardhatUserConfig */

const OPTIMISM_RPC_URL =
    process.env.OPTIMISM_RPC_URL ||
    "https://optimism.publicnode.com"
const PRIVATE_KEY = process.env.PRIVATE_KEY || "0x"

module.exports = {
    defaultNetwork: "optimism",
    networks: {
        hardhat: {
            chainId: 31337,
            blockConfirmations: 1,
        },
        optimism: {
            url: OPTIMISM_RPC_URL,
            accounts: PRIVATE_KEY !== undefined ? [PRIVATE_KEY] : [],
            chainId: 10,
            blockConfirmations: 1,
        },
    },
    solidity: "0.8.18",
    namedAccounts: {
        deployer: {
            default: 0,
        },
    },
};
