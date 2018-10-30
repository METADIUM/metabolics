'use strict'
const Identity = artifacts.require("./Identity.sol");
const TestContract = artifacts.require("./TestContract.sol");

const Registry = artifacts.require('Registry.sol')
const IdentityManager = artifacts.require('IdentityManager.sol')
const TopicRegistry = artifacts.require('TopicRegistry.sol')
const AchievementManager = artifacts.require('AchievementManager.sol')
const AARegistry = artifacts.require('AttestationAgencyRegistry.sol')
const Achievement = artifacts.require('Achievement.sol')
const fs = require('fs');
async function deploy(deployer, network, accounts) {
    const args = process.argv.slice()

    //let _gas = 6000000
    //let _gasPrice = 1 * 10 ** 11

    if (args[3] == 'all') {
        //proxy create metaID instead user for now. Because users do not have enough fee.
        let proxy1 = '0x084f8293F1b047D3A217025B24cd7b5aCe8fC657'; //node3 account[1]

        //async await for deployer.deploy do not work well. Tx is made, but information in not printed
        return deployer.deploy(Registry).then(async (reg) => {
            return deployer.deploy(IdentityManager).then(async (mim) => {
                return deployer.deploy(TopicRegistry).then(async (tr) => {
                    return deployer.deploy(AchievementManager).then(async (am) => {
                        return deployer.deploy(AARegistry).then(async (ar) => {
                            return deployer.deploy(Achievement, "Achievement", "MACH").then(async (achiv) => {

                                //reg: name, permission setup
                                await reg.setContractDomain("IdentityManager", mim.address)
                                await reg.setContractDomain("Achievement", achiv.address)
                                await reg.setContractDomain("AchievementManager", am.address)
                                await reg.setContractDomain("TopicRegistry", tr.address)
                                await reg.setContractDomain("AttestationAgencyRegistry", ar.address)

                                await reg.setPermission("IdentityManager", proxy1, "true")
                                await reg.setPermission("AttestationAgencyRegistry", proxy1, "true")
                                await reg.setPermission("Achievement", am.address, "true")
                                await reg.setPermission("TopicRegistry", accounts[0], "true")
                                await reg.setPermission("TopicRegistry", proxy1, "true")

                                await mim.setRegistry(reg.address)
                                await am.setRegistry(reg.address)
                                await achiv.setRegistry(reg.address)
                                await ar.setRegistry(reg.address)
                                await tr.setRegistry(reg.address)

                                // register creator as default aa
                                console.log(`register default aa and topics`)

                                //let defaultAA = //"0x08aa639ee52c20386984a740c4a5c0972f4849bb"
                                let defaultAA = await reg.owner();
                                console.log(`owner is ${JSON.stringify(defaultAA)}`)
                                await reg.setPermission("AttestationAgencyRegistry", defaultAA, "true")
                                await ar.registerAttestationAgency(defaultAA, 'Metadium Enterprise', 'Metadium Authority')

                                // register topics 
                                await tr.registerTopic('Name', 'Metadium Name')
                                await tr.registerTopic('NickName', 'Metadium Nickname')
                                await tr.registerTopic('Email', 'Metadium Email')

                                let _topics = [1025, 1026, 1027]
                                let _issuers = [defaultAA, defaultAA, defaultAA]
                                let _achievementExplanation = 'Meta Hero'
                                let _reward = 0.1 * 10 ** 18
                                let _uri = 'You are METAHero'

                                // register achievement
                                await am.createAchievement(_topics, _issuers, 'Metadium', _achievementExplanation, _reward, _uri, { value: '0xDE0B6B3A7640000' })

                                // write contract addresses to json file for share


                                let contractData = {}
                                contractData["Registry"] = reg.address
                                contractData["IdentityManager"] = mim.address
                                contractData["AchievementManager"] = am.address
                                contractData["Achievement"] = achiv.address
                                contractData["TopicRegistry"] = tr.address
                                contractData["AttestationAgencyRegistry"] = ar.address

                                fs.writeFile('contracts.json', JSON.stringify(contractData), 'utf-8', function (e) {
                                    if (e) {
                                        console.log(e);
                                    } else {
                                        console.log('contracts.json updated!');
                                    }
                                });

                            })
                        })
                    })
                })
            })
        })

    } else if (args[3] == 'updateIdentityManager') {
        // deploy contract
        // setContractDomain
        // setPermission
        // setRgistry


    } else if (args[3] == 'updateAttestationAgencyRegistry') {

        // for(var propName in Registry) {
        //     propValue = Registry[propName]
        //     console.log(`${propName} : ${propValue}`)
        // }

        return deployer.deploy(AARegistry).then(async (ar) => {
            console.log('Change Attestation Agency Registry')
            let currentRegistryAddress = '0x840c3d9c19c356d0569974ead5fb917ebfcac9e6' // put the current registry address
            let reg = Registry.at(currentRegistryAddress)

            await reg.setContractDomain("AttestationAgencyRegistry", ar.address)
            await ar.setRegistry(reg.address)

            let defaultAA = await reg.owner();
            console.log(`current owner is ${JSON.stringify(defaultAA)}`)
            await ar.registerAttestationAgency(defaultAA, 'Metadium Enterprise', 'Metadium Authority')

            //update to contracts.json
        })

    } else if (args[3] == 'registerSystemTopics') {
        deployer.then(async () => {
            console.log('Register System Topics')
            let currentTopicRegistryAddress = '0xb4901ded699dba8d2265cb84eb5c50e78bf24795' // put the current registry address
            let tr = TopicRegistry.at(currentTopicRegistryAddress)

            let systemTopics = readTopicsFromFile() //[{ id: 888, title: 'MetaPrint', explanation: 'You are MetaUser' },{ id: 889, title: 'Avatar', explanation: 'Your Avatar' },{ id: 890, title: 'NickName', explanation: 'Your NickName' },]

            for (const tp of systemTopics) {
                try {
                    await tr.registerTopicBySystem(tp.id, tp.title, tp.explanation)
                    console.log(`${tp.id}th system topic registered`)
                } catch (e) {
                    console.log(`${tp.id}th system topic NOT registered : ${e}`)
                }

            }
            console.log('Register System Topics End')
        })

    } else {
        deployer.deploy(Identity, [], [], 1, 1, [], [], '', '', '', []);
        deployer.deploy(TestContract);
    }
}

function readTopicsFromFile() {
    var fullLines = fs.readFileSync('./config/systemTopics.txt').toString().split("\n");
    let systemTopics = []
    for (let i in fullLines) {
        let l = fullLines[i].split(" ")
        let t = { id: parseInt(l[0]), title: l[1], explanation: l[2] }
        systemTopics.push(t)
    }
    return systemTopics
}


module.exports = deploy