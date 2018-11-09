import assertRevert from './helpers/assertRevert'
import EVMRevert from './helpers/EVMRevert'

const BigNumber = web3.BigNumber

require('chai').use(require('chai-as-promised')).use(require('chai-bignumber')(BigNumber)).should()

const Registry = artifacts.require('Registry.sol')
const TopicRegistry = artifacts.require('TopicRegistry.sol')
const AttestationAgencyRegistry = artifacts.require('AttestationAgencyRegistry.sol')

contract('Topic Registry', function ([deployer, identity1, aa1, aa2, user2, issuer1, issuer2, issuer3, proxy1]) {
    let registry, topicRegistry, aaRegistry

    beforeEach(async () => {

    });
    describe('When Registry initiated,', function () {
        beforeEach(async () => {
            registry = await Registry.new()
            aaRegistry = await AttestationAgencyRegistry.new()
            topicRegistry = await TopicRegistry.new()

            await registry.setContractDomain("TopicRegistry", topicRegistry.address)
            await registry.setContractDomain("AttestationAgencyRegistry", aaRegistry.address);
            await registry.setPermission("TopicRegistry", proxy1, "true")
            await registry.setPermission("AttestationAgencyRegistry", proxy1, "true");
            
            await topicRegistry.setRegistry(registry.address)
            await aaRegistry.setRegistry(registry.address)
            await aaRegistry.registerAttestationAgency(aa1, 'metadiumAA', 'metadiumAADes', { from: proxy1 })

        });
        describe('System Topic(<=1024)', function () {
            beforeEach(async () => {
                
            });

            it('can be registered by permissioned user', async () => {
                await topicRegistry.registerTopicBySystem(2, 'Name', 'First', { from: proxy1 })

            });

            it('cannot be registered by AA or general user', async () => {
                await assertRevert(topicRegistry.registerTopicBySystem(2, 'Name', 'First', { from: user2 }))
                await assertRevert(topicRegistry.registerTopicBySystem(2, 'Name', 'First', { from: aa1 }))
            });

            it('cannot be registered over 1024', async () => {
                await assertRevert(topicRegistry.registerTopicBySystem(1025, 'Name', 'First', { from: proxy1 }))
                
            });

        });

        describe('General Topics(>1024)', function () {
            beforeEach(async () => {
            
            });

            it('can be registered by Attestation Agency and Permissioned', async () => {
                await topicRegistry.registerTopic('CustomName', 'CustomName', { from: aa1 })
                await topicRegistry.registerTopic('CustomName2', 'CustomName2', { from: proxy1 })
            });

            it('cannot be registered by general user', async () => {
                await assertRevert(topicRegistry.registerTopic('CustomName', 'CustomName', { from: user2 })) 
            });
        });

        describe('Topics', function () {
            beforeEach(async () => {

            });

            it('can be updated by creator', async () => {
                await topicRegistry.registerTopic('CustomName', 'CustomName', { from: aa1 })
                await topicRegistry.updateTopic(1025, 'CustomName3', { from: aa1 })

            });
            it('cannot be updated by non-creator', async () => {
                await topicRegistry.registerTopic('CustomName', 'CustomName', { from: aa1 })
                await assertRevert(topicRegistry.updateTopic(1025, 'CustomName3', { from: proxy1 }))
            });


        });

        describe('Any User', function () {
            it('can check topic is registered by id', async () => {
                await topicRegistry.registerTopic('CustomName', 'CustomName', { from: aa1 })
                let found = await topicRegistry.isRegistered(1025)
                assert.equal(found, true)

            });
        })
    })

});
