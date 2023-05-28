/**
 * 1) npx hardhat test --network sepolia --grep "Contract Address on /contracts.json are not valid"
 * 2) npx hardhat test --network sepolia --grep "Contract Address on /contracts.json are valid"
 * 3) npx hardhat test --network sepolia --grep "CoolDown Period not over"
 * 4) npx hardhat test --network sepolia --grep "CoolDown Period is over"
 */


const hre = require("hardhat");
const { assert, expect } = require("chai");

describe("Domain Registry Test", function () {

  let DRC, DomainContractRegistry, domainName, DRCAddress;
  beforeEach(async function () {
    const {deployer} = await hre.getNamedAccounts()
    DRC = await hre.ethers.getContract("DRC", deployer);
    DomainContractRegistry = await hre.ethers.getContract("DomainContractRegistry", deployer);
    domainName = "eth-to-weth.vercel.app";
    DRCAddress = DRC.address;
  })
  
  describe("Registration of domain", function async() {

    describe("Contract Address on /contracts.json are not valid" ,async function () {

        it("Should not update registry ", async function () {
            const transactionResponse = await DomainContractRegistry.setDappRegistry( domainName, DRCAddress);
            await transactionResponse.wait(4);
            var result = await DomainContractRegistry.getDappRegistry(domainName);
            assert.equal(result.toString(), "0x0000000000000000000000000000000000000000");
            result = await DomainContractRegistry.getAdmin(domainName);
            assert.equal(result.toString(), "0x0000000000000000000000000000000000000000");
        })
    })

    describe("Contract Address on /contracts.json are valid" ,async function () {
        
        it("Should update registry ", async function () {
            const addr = ["0x33bAe0949E0Bb7df7Cd7d63E6808CFacE42EdbC2","0x518E679d48F7f3CF82D51a6cB1f3CfcFbad83Aeb","0x71354912666ff3128C36B26834C0cDF6d23fbd30"]
            for(var i=0; i<addr.length; i++) {
                const transactionResponse = await DRC.addAddress(addr[i])
                await transactionResponse.wait();
            }
            transactionResponse = await DomainContractRegistry.setDappRegistry( domainName, DRCAddress);
            await transactionResponse.wait(4);

            var result = await DomainContractRegistry.getDappRegistry(domainName);
            assert.equal(result.toString(), DRCAddress);
            result = await DomainContractRegistry.getAdmin(domainName);
            const {deployer} = await hre.getNamedAccounts()
            assert.equal(result.toString(), deployer);
        })
    })
  })



    describe("Update domain Registry", async function () {
        let newDappRegistry
        beforeEach(async function () {
            newDappRegistry = "0x837c7E69B89e465680f28309ea37F0FeED01e428"
            DRC = await hre.ethers.getContractAt("DRC", newDappRegistry);
        })

        describe("msg.sender is admin", function() {

            describe("Contract Address on /contracts.json are not valid" ,async function () {
                it("Should not update Dapp registry ", async function () {
                    const oldDappRegistry = await DomainContractRegistry.getDappRegistry(domainName);
                    const transactionResponse = await DomainContractRegistry.setDappRegistry( domainName, newDappRegistry);
                    await transactionResponse.wait(4);
                    const result = await DomainContractRegistry.getDappRegistry(domainName);
                    assert.equal(result.toString(), oldDappRegistry.toString());
                })
            })

            describe("Contract Address on /contracts.json are valid" ,async function () {
                it("Should update Dapp registry ", async function () {
                    const addr = ["0x33bAe0949E0Bb7df7Cd7d63E6808CFacE42EdbC2","0x518E679d48F7f3CF82D51a6cB1f3CfcFbad83Aeb","0x71354912666ff3128C36B26834C0cDF6d23fbd30"]
                    for(var i=0; i<addr.length; i++) {
                        const transactionResponse = await DRC.addAddress(addr[i])
                        await transactionResponse.wait()
                    }
                    const transactionResponse = await DomainContractRegistry.setDappRegistry( domainName, newDappRegistry);
                    await transactionResponse.wait(4)
                    const result = await DomainContractRegistry.getDappRegistry(domainName)
                    assert.equal(result.toString(), newDappRegistry)
                })
            })       
        })


        describe("msg.sender is not admin", function() {
            let oldRecordTransition
            beforeEach(async function() {
                const { newAdmin } = await getNamedAccounts()
                DomainContractRegistry = await hre.ethers.getContract("DomainContractRegistry", newAdmin)
                oldRecordTransition = await DomainContractRegistry.getRecordTransition(domainName);
            })
            
            describe("Contract Address on /contracts.json are not valid", async function() {
                it("Should not record Transition", async function() {
                    const transactionResponse = await DomainContractRegistry.setDappRegistry( domainName, newDappRegistry)
                    await transactionResponse.wait(4)
                    const result = await DomainContractRegistry.getRecordTransition(domainName)
                    assert.equal(result.toString(), oldRecordTransition.toString())
                })
            })

            describe("Contract Address on /contracts.json are valid", async function() {
                it("Should record transition", async function() {
                    const addr = ["0x33bAe0949E0Bb7df7Cd7d63E6808CFacE42EdbC2","0x518E679d48F7f3CF82D51a6cB1f3CfcFbad83Aeb","0x71354912666ff3128C36B26834C0cDF6d23fbd30"]
                    for(var i=0; i<addr.length; i++) {
                        const transactionResponse = await DRC.addAddress(addr[i])
                        await transactionResponse.wait()
                    }
                    const transactionResponse = await DomainContractRegistry.setDappRegistry( domainName, newDappRegistry);
                    await transactionResponse.wait(4)
                    const result = await DomainContractRegistry.getRecordTransition(domainName)
                    assert.equal(result[0].toString(), newDappRegistry)
                })
            })
        })


        describe("Transition is already recorded", async function() {

            beforeEach(async function() {
                const { newAdmin } = await getNamedAccounts()
                DomainContractRegistry = await hre.ethers.getContract("DomainContractRegistry", newAdmin)
                const transactionResponse = await DomainContractRegistry.setDappRegistry( domainName, newDappRegistry)
                await transactionResponse.wait(4)
            })
            
            describe("CoolDown Period not over", function() {
                it("Should be reverted", async function() {
                    await expect( DomainContractRegistry.setDappRegistry( domainName, newDappRegistry)).to.be.reverted
                })
            }) 
            
            describe("CoolDown Period is over", function() {
                it("Should update Dapp Registry", async function() {
                    var result = await DomainContractRegistry.getDappRegistry(domainName)
                    assert.equal(result.toString(), newDappRegistry)
                    result = await DomainContractRegistry.getAdmin(domainName)
                    const { newAdmin } = await getNamedAccounts()
                    assert.equal(result.toString(), newAdmin)
                })
            }) 
        }) 
    })
})
