'use strict'
const Identity = artifacts.require("./Identity.sol");
const TestContract = artifacts.require("./TestContract.sol");

const Registry = artifacts.require('Registry.sol')
const IdentityManager = artifacts.require('IdentityManager.sol')
const TopicRegistry = artifacts.require('TopicRegistry.sol')
const AchievementManager = artifacts.require('AchievementManager.sol')
const AARegistry = artifacts.require('AttestationAgencyRegistry.sol')
const Achievement = artifacts.require('Achievement.sol')
const MetaIdentity = artifacts.require('MetaIdentity.sol')

const fs = require('fs');
const proxy1 = '0x084f8293F1b047D3A217025B24cd7b5aCe8fC657'; //node3 account[1]
const selfClaimAddress = '0xFFfFfFffFFfffFFfFFfFFFFFffFFFffffFfFFFfF'

async function deploy(deployer, network, accounts) {
    let reg, mim, tr, am, ar, achiv
    const args = process.argv.slice()

    if (args[3] == 'all') {
        deployer.then(async () => {
            [reg, mim, tr, am, ar, achiv] = await deployContracts(deployer, network, accounts)
            await basicRegistrySetup(deployer, network, accounts, reg, mim, tr, am, ar, achiv)
            let metaHand = await defaultAASetup(accounts, reg, mim, tr, am, ar, achiv)
            await defaultAchievementSetup(accounts, reg, mim, tr, am, ar, achiv)
            await registerSystemTopics(accounts, reg, mim, tr, am, ar, achiv)
            await writeToContractsJson(reg, mim, tr, am, ar, achiv, metaHand)

        })
    } else if (args[3] == 'updateIdentityManager') {
        deployer.then(async () => {
            let currentRegistryAddress = '0xd8f3fcd161c4771c07bf09bc6136da1663a05929' // put the current registry address
            let reg = Registry.at(currentRegistryAddress)

            mim = await deployer.deploy(IdentityManager)
            await reg.setContractDomain("IdentityManager", mim.address)
            
            await mim.setRegistry(reg.address)

        })
        // deploy contract
        // setContractDomain
        // setRegistry


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

    } else if (args[3] == 'registerSystemAAMetaHand') {


    } else {
        //deployer.deploy(Identity, [], [], 1, 1, [], [], '', '', '', []);
        
        //need for test
        deployer.deploy(TestContract);
    }
}

async function deployContracts(deployer, network, accounts) {
    //proxy create metaID instead user for now. Because users do not have enough fee.
    let reg, mim, tr, am, ar, achiv

    reg = await deployer.deploy(Registry)
    mim = await deployer.deploy(IdentityManager)
    tr = await deployer.deploy(TopicRegistry)
    am = await deployer.deploy(AchievementManager)
    ar = await deployer.deploy(AARegistry)
    achiv = await deployer.deploy(Achievement, "Achievement", "MACH")

    return [reg, mim, tr, am, ar, achiv]

}

async function basicRegistrySetup(deployer, network, accounts, reg, mim, tr, am, ar, achiv) {

    await reg.setContractDomain("IdentityManager", mim.address)
    await reg.setContractDomain("Achievement", achiv.address)
    await reg.setContractDomain("AchievementManager", am.address)
    await reg.setContractDomain("TopicRegistry", tr.address)
    await reg.setContractDomain("AttestationAgencyRegistry", ar.address)

    await reg.setPermission("IdentityManager", proxy1, "true")
    await reg.setPermission("IdentityManager", accounts[0], "true")
    await reg.setPermission("AttestationAgencyRegistry", proxy1, "true")
    await reg.setPermission("AttestationAgencyRegistry", accounts[0], "true")
    await reg.setPermission("Achievement", am.address, "true")
    await reg.setPermission("TopicRegistry", accounts[0], "true")
    await reg.setPermission("TopicRegistry", proxy1, "true")

    await mim.setRegistry(reg.address)
    await am.setRegistry(reg.address)
    await achiv.setRegistry(reg.address)
    await ar.setRegistry(reg.address)
    await tr.setRegistry(reg.address)

}

async function defaultAASetup(accounts, reg, mim, tr, am, ar, achiv) {
    // register creator as default aa
    console.log(`register default aa and topics`)

    let defaultAA = accounts[0] // await reg.owner();
    console.log(`owner is ${JSON.stringify(defaultAA)}`)
    await reg.setPermission("AttestationAgencyRegistry", defaultAA, "true")
    await ar.registerAttestationAgency(defaultAA, 'Metadium Enterprise', 'Metadium Authority')


    console.log(`Registering Meta Hand ...... `)
    // create metaHand identity
    await mim.createMetaId('0xa408fcd6b7f3847686cb5f41e52a7f4e084fd3cc')

    // register metaHand identity as AA
    let metaIds = await mim.getDeployedMetaIds()
    // let metaHandAddress = await MetaIdentity.at(metaIds[0])
    await ar.registerAttestationAgency(metaIds[0], 'MetaHand', 'Metadium Hand')

    console.log(`Meta Hand Registered`)
    return metaIds[0]

}

async function defaultAchievementSetup(accounts, reg, mim, tr, am, ar, achiv) {
    console.log('Registering default topics and achievement......')
    // register topics 
    await tr.registerTopic('Name', 'Metadium Name')
    await tr.registerTopic('NickName', 'Metadium Nickname')
    await tr.registerTopic('Email', 'Metadium Email')

    let _topics = [1025, 1026, 1027]
    let _issuers = [accounts[0], accounts[0], accounts[0]]
    let _achievementExplanation = 'Meta Hero'
    let _reward = 0.1 * 10 ** 18
    let _uri = 'You are METAHero'

    // register achievement
    await am.createAchievement(_topics, _issuers, 'Metadium', _achievementExplanation, _reward, _uri, { value: '0xDE0B6B3A7640000' })

    console.log('Default topics and achievement Registered')
}

async function registerSystemTopics(accounts, reg, mim, tr, am, ar, achiv) {
    console.log('Register System Topics')

    let systemTopics = readTopicsFromFile() //[{ id: 888, title: 'MetaPrint', explanation: 'You are MetaUser' },{ id: 889, title: 'Avatar', explanation: 'Your Avatar' },{ id: 890, title: 'NickName', explanation: 'Your NickName' },]

    for (const tp of systemTopics) {
        try {
            await tr.registerTopicBySystem(tp.id, tp.title, tp.explanation)
            console.log(`${tp.id}th : ${tp.title} - system topic registered`)
        } catch (e) {
            console.log(`${tp.id}th : ${tp.title} - system topic NOT registered : ${e}`)
        }

    }
    console.log('System Topics are registered')

    console.log('Registering achievements with system topics......')
    let _topics = [10, 11, 20, 30]
    let _issuers = [selfClaimAddress, selfClaimAddress, accounts[0], accounts[0]]
    let _achievementtitle = 'Basic Profile'
    let _achievementExplanation = 'Name/Phone/Email'
    let _reward = 0.1 * 10 ** 18
    let _uri = 'You registered your basic profile!'

    // register achievement

    //Basic Profile
    await am.createAchievement(_topics, _issuers, _achievementtitle, _achievementExplanation, _reward, _uri, { value: '0xDE0B6B3A7640000' })

    //Birth Info
    await am.createAchievement([3,4], [selfClaimAddress, selfClaimAddress], 'Birth Info', 'Date Of Birth And Gender', _reward, 'You have birth and gender!', { value: '0xDE0B6B3A7640000' })

    //Nationality
    await am.createAchievement([70, 80], [selfClaimAddress, selfClaimAddress], 'Nationality', 'Nationality And Language', _reward, 'You have Nationality and Language', { value: '0xDE0B6B3A7640000' })

    //Name Card
    await am.createAchievement([90, 100], [selfClaimAddress, selfClaimAddress], 'Name Card', 'Occupation And SNS', _reward, 'You have Occupation and SNS', { value: '0xDE0B6B3A7640000' })

    console.log('System achievements are registered')
}


async function writeToContractsJson(reg, mim, tr, am, ar, achiv, metaHand) {
    console.log(`Writing Contract Address To contracts.json`)
    let contractData = {}
    contractData["Registry"] = reg.address
    contractData["IdentityManager"] = mim.address
    contractData["AchievementManager"] = am.address
    contractData["Achievement"] = achiv.address
    contractData["TopicRegistry"] = tr.address
    contractData["AttestationAgencyRegistry"] = ar.address
    contractData["MetaHand"] = metaHand

    fs.writeFile('contracts.json', JSON.stringify(contractData), 'utf-8', function (e) {
        if (e) {
            console.log(e);
        } else {
            console.log('contracts.json updated!');
        }
    });
    
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