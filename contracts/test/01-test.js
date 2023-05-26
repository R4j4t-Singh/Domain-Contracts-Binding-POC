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

        describe("First time registartion", function () {
            
        })

    })
}

module.exports.tags = ["all"]

