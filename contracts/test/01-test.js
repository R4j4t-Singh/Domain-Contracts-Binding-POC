const hre = require("hardhat")
const { assert, expect } = require("chai");

module.exports = async ({ getNamedAccounts, deployments}) => {
    const { deployer } = await getNamedAccounts()

    describe("Test 01", function () {
        let DRC, DomainContractRegistry
        beforeEach(async function() {
            DRC = await hre.deployments.get("DRC")
            DomainContractRegistry = await hre.deployments.get("DomainContractRegistry")
        })

        describe("Registration of domain", function () {
            
            it("Should record transtion when a user register domain", async function () {
                const domainName = "eth-to-weth.vercel.app"
                const DRCAddress = DRC.address
                const response = await DomainContractRegistry.setDappRegistry(domainName, DRCAddress)

            })
        })

    })
}

module.exports.tags = ["all"]

