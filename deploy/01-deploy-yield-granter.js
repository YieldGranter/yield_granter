const {ethers, network} = require("hardhat");
const {networkConfig, developmentChains} = require("../helper-hardhat-config");
const ERC20_ABI = require("../contracts/abi/ERC20.json");

module.exports = async function ({getNamedAccounts, deployments}) {
    if (developmentChains.includes(network.name)) {
        const {deploy, log} = deployments
        const {deployer} = await getNamedAccounts()
        console.log(deployer)

        const args = [
            networkConfig[31337].gauge,
            networkConfig[31337].router,
            networkConfig[31337].usdc,
            networkConfig[31337].dola,
            networkConfig[31337].lpToken,
            networkConfig[31337].velo,
        ]
        const proxyContract = await deploy("YieldGranter", {
            from: deployer,
            args: args,
            log: true,
            waitConfirmations: network.config.blockConfirmations || 1,
        })

        const deployerSigner = await ethers.getSigner(deployer)
        const token1Contract = new ethers.Contract(networkConfig[31337].usdc, ERC20_ABI, deployerSigner);
        const token2Contract = new ethers.Contract(networkConfig[31337].dola, ERC20_ABI, deployerSigner);

        await token1Contract.approve(proxyContract.address, ethers.utils.parseUnits("100", "ether"));
        await token2Contract.approve(proxyContract.address, ethers.utils.parseUnits("100", "ether"));
        log("YieldGranter deployed to:", proxyContract.address);

        if (process.env.ETHERSCAN_API_KEY) {
            log("Verifying")
        }
        log("--------------")
    }
}

module.exports.tags = ["all", "proxy", "main"]
