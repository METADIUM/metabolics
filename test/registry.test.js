import assertRevert from './helpers/assertRevert'
import EVMRevert from './helpers/EVMRevert'

const BigNumber = web3.BigNumber

require('chai').use(require('chai-as-promised')).use(require('chai-bignumber')(BigNumber)).should()

const Registry = artifacts.require('Registry.sol')

contract('Attestation Agency Registry', function ([deployer, identity1, aa1, aa2, user2, issuer1, issuer2, issuer3, proxy1]) {
    let registry

    beforeEach(async () => {

    });
    describe('When Registry initiated,', function () {
        beforeEach(async () => {
            registry = await Registry.new()
            topicRegistry = await TopicRegistry.new()

            await registry.setContractDomain("TopicRegistry", topicRegistry.address)
            await registry.setPermission("TopicRegistry", proxy1, "true")
            
            await topicRegistry.setRegistry(registry.address)

        });
        describe('System Topic(<=1024)', function () {
    

        });

        describe('General Topics(>1024)', function () {
        
        });

        describe('Topics', function () {
    

        });

        describe('Any User', function () {

        })
    })

});
