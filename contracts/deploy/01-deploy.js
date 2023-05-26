const hre = require("hardhat")

module.exports = async ({ getNamedAccounts, deployments }) => {
    const { deploy } = deployments
    const { deployer } = await getNamedAccounts()

    const DRC = await deploy("DRC", {
        from: deployer,
        args: [],
        log: true,
    })

    console.log("DRC deployed to:", DRC.address)

    const DomainContractRegistry = await deploy("DomainContractRegistry", {
        from: deployer,
        args: [],
        log: true,
    })

    console.log("DomainContractRegistry deployed to:", DomainContractRegistry.address)
}