const {ethers, network} = require("hardhat");
const {networkConfig, developmentChains} = require("../helper-hardhat-config");

module.exports = async function ({getNamedAccounts, deployments}) {
    if (developmentChains.includes(network.name)) {
        const {deploy, log} = deployments
        const {deployer} = await getNamedAccounts()
        console.log(deployer)

        const ipfsStorage = await deploy("IpfsStorage", {
            from: deployer,
            args: [],
            log: true,
            waitConfirmations: network.config.blockConfirmations || 1,
        })

        log("IpsfStorage deployed to:", ipfsStorage.address);

        if (process.env.ETHERSCAN_API_KEY) {
            log("Verifying")
        }
        log("--------------")
    }
}

module.exports.tags = ["all", "ipfs-storage"]
