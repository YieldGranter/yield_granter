require('dotenv').config()
const ipfsClient = require("ipfs-http-client")

class Project {
    constructor(
        name,
        address,
        description,
        donationGoal,
    ) {
        this.name = name
        this.address = address
        this.description = description
        this.donationGoal = donationGoal
        this.donationAmount = 0
    }
}

class Ipfs {

    constructor(
        ipfsStorageContract,
        donationAmountStorageContract,
    ) {
        this.ipfsStorageContract = ipfsStorageContract
        this.donationAmountStorageContract = donationAmountStorageContract

        const projectId = process.env.INFURA_PROJECT_ID
        const projectSecret = process.env.INFURA_PROJECT_SECRET
        const auth =
            'Basic ' + Buffer.from(projectId + ':' + projectSecret).toString('base64')
        this.client = ipfsClient.create({
            host: 'ipfs.infura.io',
            port: 5001,
            protocol: 'https',
            headers: {
                authorization: auth,
            },
        })
    }

    async saveProject(project) {
        const jsonString = JSON.stringify(project)
        await this.client.add(jsonString).then((res) => {
            const cidV0 = res.cid.toV0().toString()
            this.ipfsStorageContract.saveCID(cidV0)
        });
    }

    async getProject(cid) {
        const resp = await this.client.cat(cid)
        let content = []
        for await (const chunk of resp) {
            content = [...content, ...chunk]
        }
        const raw = Buffer.from(content).toString('utf8')
        return JSON.parse(raw)
    }

    async getAllProjects() {
        const cids = await this.ipfsStorageContract.cids
        let projects = []
        for (const cid of cids) {
            const project = await this.getProject(cid)
            project.donatedAmount =
                await this.donationAmountStorageContract.getDonationAmount(project.address)
            projects.push(project)
        }
        return projects
    }
}
