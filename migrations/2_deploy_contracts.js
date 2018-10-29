const Identity = artifacts.require("./Identity.sol");
const TestContract = artifacts.require("./TestContract.sol");

const Registry = artifacts.require('Registry.sol')
const IdentityManager = artifacts.require('IdentityManager.sol')
const TopicRegistry = artifacts.require('TopicRegistry.sol')
const AchievementManager = artifacts.require('AchievementManager.sol')
const AARegistry = artifacts.require('AttestationAgencyRegistry.sol')
const Achievement = artifacts.require('Achievement.sol')

async function deploy(deployer, network, accounts) {
    const args = process.argv.slice()
    
    let _gas = 6000000
    let _gasPrice = 1 * 10 ** 11
    
    if (args[3] == 'all') {
        //proxy create metaID instead user for now. Because users do not have enough fee.
        let proxy1 = '0x084f8293F1b047D3A217025B24cd7b5aCe8fC657'; //node3 account[1]
        return deployer.deploy(Registry, { gas: _gas, gasPrice: _gasPrice }).then(async (reg) => {
            return deployer.deploy(IdentityManager, { gas: _gas, gasPrice: _gasPrice }).then(async (mim) => {
                return deployer.deploy(TopicRegistry, { gas: _gas, gasPrice: _gasPrice }).then(async (tr) => {
                    return deployer.deploy(AchievementManager, { gas: _gas, gasPrice: _gasPrice }).then(async (am) => {
                        return deployer.deploy(AARegistry, { gas: _gas, gasPrice: _gasPrice }).then(async (ar) => {
                            return deployer.deploy(Achievement, "Achievement", "MACH", { gas: _gas, gasPrice: _gasPrice}).then(async (achiv) => {
                                //reg: name, permission setup

                                await reg.setContractDomain("IdentityManager", mim.address, { gas: _gas, gasPrice: _gasPrice })
                                await reg.setContractDomain("Achievement", achiv.address, { gas: _gas, gasPrice: _gasPrice})
                                await reg.setContractDomain("AchievementManager", am.address, { gas: _gas, gasPrice: _gasPrice})
                                await reg.setContractDomain("TopicRegistry", tr.address, { gas: _gas, gasPrice: _gasPrice})
                                await reg.setContractDomain("AttestationAgencyRegistry", ar.address, { gas: _gas, gasPrice: _gasPrice})

                                await reg.setPermission("IdentityManager", proxy1, "true", { gas: _gas, gasPrice: _gasPrice })
                                await reg.setPermission("AttestationAgencyRegistry", proxy1, "true", { gas: _gas, gasPrice: _gasPrice })
                                await reg.setPermission("Achievement", am.address, "true", { gas: _gas, gasPrice: _gasPrice })

                                await mim.setRegistry(reg.address, { gas: _gas, gasPrice: _gasPrice })
                                await am.setRegistry(reg.address, { gas: _gas, gasPrice: _gasPrice })
                                await achiv.setRegistry(reg.address, { gas: _gas, gasPrice: _gasPrice })
                                await ar.setRegistry(reg.address, { gas: _gas, gasPrice: _gasPrice })
                                await tr.setRegistry(reg.address, { gas: _gas, gasPrice: _gasPrice })
                                
                                // register creator as default aa
                                console.log(`register default aa and topics`)
                                //let defaultAA = //"0xD351858Dd581c4046693cEAe54C169C9f402E16D"
                                let defaultAA = await reg.owner();
                                console.log(`owner is ${JSON.stringify(defaultAA)}`)
                                await reg.setPermission("AttestationAgencyRegistry", defaultAA, "true", { gas: _gas, gasPrice: _gasPrice })
                                await ar.registerAttestationAgency(defaultAA, 'Metadium Enterprise', 'Metadium Authority', { gas: _gas, gasPrice: _gasPrice})

                                // register topics 
                                await tr.registerTopic('Name', 'Metadium Name', { gas: _gas, gasPrice: _gasPrice})
                                await tr.registerTopic('NickName', 'Metadium Nickname', { gas: _gas, gasPrice: _gasPrice})
                                await tr.registerTopic('Email', 'Metadium Email', { gas: _gas, gasPrice: _gasPrice})

                                let _topics = [1025, 1026, 1027]
                                let _issuers = [defaultAA, defaultAA, defaultAA]
                                let _achievementExplanation = 'Meta Hero'
                                let _reward = 0.1 * 10 ** 18
                                let _uri = 'You are METAHero'

                                // register achievement
                                await am.createAchievement(_topics, _issuers, 'Metadium', _achievementExplanation, _reward, _uri, { gas: _gas, gasPrice: _gasPrice, value: '0xDE0B6B3A7640000' })
                                
                                // write contract addresses to json file for share
                                var fs = require('fs');

                                let contractData = {}
                                contractData["Registry"] = reg.address
                                contractData["IdentityManager"] = mim.address
                                contractData["AchievementManager"] = am.address
                                contractData["Achievement"] = achiv.address
                                contractData["TopicRegistry"] = tr.address
                                contractData["AttestationAgencyRegistry"] = ar.address

                                fs.writeFile('contracts.json', JSON.stringify(contractData), 'utf-8', function(e){
                                    if(e){
                                        console.log(e);
                                    }else{
                                        console.log('contracts.json updated!');
                                    }
                                });

                            })
                        })
                    })
                })
            })
        })

    } else if (args[3] == 'updateIdentityManager'){
        // deploy contract
        // setContractDomain
        // setPermission
        // setRgistry


    } else if (args[3] == 'updateAttestationAgencyRegistry'){

        // for(var propName in Registry) {
        //     propValue = Registry[propName]
        //     console.log(`${propName} : ${propValue}`)
        // }
        
        return deployer.deploy(AARegistry, { gas: _gas, gasPrice: _gasPrice}).then(async (ar) => {
            console.log('Change Attestation Agency Registry')
            let currentRegistryAddress = '0xd3f977d8da3f9be3329d24b2d944257ed5312fed' // put the current registry address
            let reg = Registry.at(currentRegistryAddress)

            await reg.setContractDomain("AttestationAgencyRegistry", ar.address, { gas: _gas, gasPrice: _gasPrice})
            await ar.setRegistry(reg.address, { gas: _gas, gasPrice: _gasPrice })
            
            let defaultAA = await reg.owner();
            console.log(`current owner is ${JSON.stringify(defaultAA)}`)
            await ar.registerAttestationAgency(defaultAA, 'Metadium Enterprise', 'Metadium Authority', { gas: _gas, gasPrice: _gasPrice})
        })

    } else {
        deployer.deploy(Identity, [], [], 1, 1, [], [], '', '', '', []);
        deployer.deploy(TestContract);
    }

}

var getNonce = async (_address) => {
    let nonce = web3.eth.getTransactionCount(_address)
    return nonce
}
module.exports = deploy