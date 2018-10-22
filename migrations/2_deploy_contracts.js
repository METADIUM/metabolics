const Identity = artifacts.require("./Identity.sol");
const TestContract = artifacts.require("./TestContract.sol");

const Registry = artifacts.require('Registry.sol')
const IdentityManager = artifacts.require('IdentityManager.sol')
const TopicRegistry = artifacts.require('TopicRegistry.sol')
const AchievementManager = artifacts.require('AchievementManager.sol')
const AARegistry = artifacts.require('AttestationAgencyRegistry.sol')
const Achievement = artifacts.require('Achievement.sol')

// deploy to local test instance
// truffle migrate all --reset

// deploy to testnet
// truffle migrate all --network metadiumTestnet --reset

async function deploy(deployer) {
    const args = process.argv.slice()
    let _nonce = 0x54; // this shuld be current nonce + 2 because of the migration tx

    let _gas = 6000000
    let _gasPrice = 1 * 10 ** 11

    if (args[3] == 'all') {
        //proxy create metaID instead user for now. Because users do not have enough fee.
        var proxy1 = '0x084f8293F1b047D3A217025B24cd7b5aCe8fC657'; //node3 account[1]

        return deployer.deploy(Registry, { gas: _gas, gasPrice: _gasPrice, nonce: _nonce }).then(async (reg) => {
            return deployer.deploy(IdentityManager, { gas: _gas, gasPrice: _gasPrice, nonce: _nonce + 1 }).then(async (mim) => {
                return deployer.deploy(TopicRegistry, { gas: _gas, gasPrice: _gasPrice, nonce: _nonce + 2 }).then(async (tr) => {
                    return deployer.deploy(AchievementManager, { gas: _gas, gasPrice: _gasPrice, nonce: _nonce + 3 }).then(async (am) => {
                        return deployer.deploy(AARegistry, { gas: _gas, gasPrice: _gasPrice, nonce: _nonce + 4 }).then(async (ar) => {
                            return deployer.deploy(Achievement, "Achievement", "MACH", { gas: _gas, gasPrice: _gasPrice, nonce: _nonce + 5}).then(async (achiv) => {
                                //reg: name, permission setup

                                await reg.setContractDomain("IdentityManager", mim.address, { gas: _gas, gasPrice: _gasPrice, nonce: _nonce + 6 })
                                await reg.setContractDomain("Achievement", achiv.address, { gas: _gas, gasPrice: _gasPrice, nonce: _nonce + 7 })
                                await reg.setContractDomain("AchievementManager", am.address, { gas: _gas, gasPrice: _gasPrice, nonce: _nonce + 8 })
                                await reg.setContractDomain("TopicRegistry", tr.address, { gas: _gas, gasPrice: _gasPrice, nonce: _nonce + 9})
                                await reg.setContractDomain("AttestationAgencyRegistry", ar.address, { gas: _gas, gasPrice: _gasPrice, nonce: _nonce + 10})

                                await reg.setPermission("IdentityManager", proxy1, "true", { gas: _gas, gasPrice: _gasPrice, nonce: _nonce + 11 })
                                await reg.setPermission("AttestationAgencyRegistry", proxy1, "true", { gas: _gas, gasPrice: _gasPrice, nonce: _nonce + 12 })
                                await reg.setPermission("Achievement", am.address, "true", { gas: _gas, gasPrice: _gasPrice, nonce: _nonce + 13 })

                                await mim.setRegistry(reg.address, { gas: _gas, gasPrice: _gasPrice, nonce: _nonce + 14 })
                                await am.setRegistry(reg.address, { gas: _gas, gasPrice: _gasPrice, nonce: _nonce + 15 })
                                await achiv.setRegistry(reg.address, { gas: _gas, gasPrice: _gasPrice, nonce: _nonce + 16 })
                                await ar.setRegistry(reg.address, { gas: _gas, gasPrice: _gasPrice, nonce: _nonce + 17 })
                                await tr.setRegistry(reg.address, { gas: _gas, gasPrice: _gasPrice, nonce: _nonce + 18 })

                                
                                // register creator as default aa
                                await reg.setPermission("AttestationAgencyRegistry", deployer, "true", { gas: _gas, gasPrice: _gasPrice, nonce: _nonce + 19 })
                                await aaRegistry.registerAttestationAgency(deployer, 'metadiumAA', 'metadiumAADes', { gas: _gas, gasPrice: _gasPrice, nonce: _nonce + 20})

                                // register topics 
                                await topicRegistry.registerTopic(deployer, 'name', { gas: _gas, gasPrice: _gasPrice, nonce: _nonce + 21})
                                await topicRegistry.registerTopic(deployer, 'nickname', { gas: _gas, gasPrice: _gasPrice, nonce: _nonce + 22})
                                await topicRegistry.registerTopic(deployer, 'email', { gas: _gas, gasPrice: _gasPrice, nonce: _nonce + 23})

                                let _topics = [1025, 1026, 1027]
                                let _issuers = [issuer1, issuer2, issuer3]
                                let _achievementExplanation = 'Metadium'
                                let _reward = 0.01 * 10 ** 18
                                let _uri = '0x3be095406c14a224018c2e749ef954073b0f71f8cef30bb0458aab8662a447a0'

                                // register achievement
                                await achievementManager.createAchievement(_topics, _issuers, _achievementExplanation, _reward, _uri, { gas: _gas, gasPrice: _gasPrice, nonce: _nonce + 24, value: ether1 })
                                
                                // write contract addresses to json file to share

                            })
                        })
                    })
                })

            })
        })

    } else {
        deployer.deploy(Identity, [], [], 1, 1, [], [], '', '', '', []);
        deployer.deploy(TestContract);
    }

}

module.exports = deploy