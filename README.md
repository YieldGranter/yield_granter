# yield_granter
<img width="935" height="450" alt="Screen Shot 2023-06-18 at 16 35 44" src="https://github.com/YieldGranter/yield_granter/assets/61376884/3c5a9704-da24-4978-97e8-1595dec05eb8">

Front: https://github.com/YieldGranter/yield_granter_front

## Description
YieldGranter is an innovative donation platform that allows users to donate a portion of their farming yield on a regular basis. Our app stores project's information on the IPFS, which means project can apply for donation in a decentralized manner without any centralized approval. In the future, we plan to integrate with rating protocols to solve the problem of spam projects.

We allow users to direct a portion of their profits from farming platforms like Aave, Balancer, Convex, Aura, Velodrome, etc. This mechanism fosters sustained support for projects. Currently we established a connection to the Velodrome USDC-sUSD pool, where 10% of the farmed yield will go to the project of your choice.

 Our platform's key feature is its completely community-based nature, with no backend or centralized power. Thanks to IPFS and Filecoin, we can achieve this and allow projects to add to our platform permissionesly.

 ## Archeticture & tech
 YieldGranter's interface is built using React. The backend, powered by smart contracts, utilizes a proxy contract that adheres to ERC20 and ERC4626 standards. This contract mediates interactions with farming platforms, granting our tokens to users upon deposit and facilitating withdrawals.

The project application process combines IPFS and smart contracts. Project data is stored on IPFS, while a smart contract retains the corresponding CID. This approach employs IPFS and smart contracts for a streamlined, transparent project application system.
