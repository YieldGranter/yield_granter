const networkConfig = {
    31337: {
        name: "localhost",
        gauge: "0xafd2c84b9d1cd50e7e18a55e419749a6c9055e1f",
        router: "0x9c12939390052919af3155f41bf4160fd3666a6f",
        usdc: "0x7F5c764cBc14f9669B88837ca1490cCa17c31607",
        dola: "0x8aE125E8653821E851F12A49F7765db9a9ce7384",
        lpToken: "0x6c5019d345ec05004a7e7b0623a91a0d9b8d590d",
        velo: "0x3c8b650257cfb5f272f799f5e2b4e65093a11a05",
    },
    10: {
        name: "optimism",
        gauge: "0xafd2c84b9d1cd50e7e18a55e419749a6c9055e1f",
        router: "0x9c12939390052919af3155f41bf4160fd3666a6f",
        usdc: "0x7F5c764cBc14f9669B88837ca1490cCa17c31607",
        dola: "0x8aE125E8653821E851F12A49F7765db9a9ce7384",
        lpToken: "0x6c5019d345ec05004a7e7b0623a91a0d9b8d590d",
        velo: "0x3c8b650257cfb5f272f799f5e2b4e65093a11a05",
    }
}

const developmentChains = ["hardhat", "localhost"]

module.exports = {
    networkConfig,
    developmentChains,
}
