import assertRevert from './helpers/assertRevert'
import EVMRevert from './helpers/EVMRevert'

const BigNumber = web3.BigNumber

require('chai').use(require('chai-as-promised')).use(require('chai-bignumber')(BigNumber)).should()


const Registry = artifacts.require('Registry.sol')
const MetaIdentity = artifacts.require('MetaIdentity.sol')
const TopicRegistry = artifacts.require('TopicRegistry.sol')
const AchievementManager = artifacts.require('AchievementManager.sol')
const Achievement = artifacts.require('Achievement.sol')

contract('Achievement Manager', function ([deployer, identity1, aa1, user1, user2, issuer1, issuer2, issuer3]) {
    let registry, topicRegistry, achievementManager, metaIdentity, achievement
    let ether1 = 1000000000000000000
    let _topics, _issuers, _topicExplanations, _achievementExplanation, _reward, _uri
    let _scheme = 1;
    beforeEach(async () => {
        // deploy all

        registry = await Registry.new()
        topicRegistry = await TopicRegistry.new()
        achievementManager = await AchievementManager.new()
        achievement = await Achievement.new("Achievement", "MACH")
        metaIdentity = await MetaIdentity.new(identity1, { from: identity1 })

        // set domain & permission
        await registry.setContractDomain("TopicRegistry", topicRegistry.address)
        await registry.setContractDomain("Achievement", achievement.address)
        await registry.setPermission("Achievement", achievementManager.address, "true")

        await achievementManager.setRegistry(registry.address)
        await achievement.setRegistry(registry.address)

    });

    describe('Create an achievement', function () {
        beforeEach(async () => {

        });

        it('any user can make achievement', async () => {
        });

        it('user who has enough claims can get achievement', async () => {

        });

        it.only('user who has enough claims can get achievement(all topics not registered and above 1024)', async () => {
            _topics = [1025, 1026, 1027]
            _issuers = [issuer1, issuer2, issuer3]
            _topicExplanations = ['0xab00', '0xcd00', '0xef00']
            _achievementExplanation = '0x12'
            _reward = 0.1 * 10 ** 18
            _uri = '0x3be095406c14a224018c2e749ef954073b0f71f8cef30bb0458aab8662a447a0'

            let _signatures = [];
            let _datas = ['facebook user', 'twitter user', 'google user'];
            let _signingDatas = [];
            let _uris = ["claim1uri", "claim2uri", "claim3uri"];
            let _topicPacked = ["0000000000000000000000000000000000000000000000000000000000000401", "0000000000000000000000000000000000000000000000000000000000000402", "0000000000000000000000000000000000000000000000000000000000000403"]
            // create achievement
            await achievementManager.createAchievement(_topics, _issuers, _topicExplanations, _achievementExplanation, _reward, _uri, { from: aa1, value: ether1 })

            let bal = await web3.eth.getBalance(achievementManager.address)
            assert.equal(bal, ether1)

            // register claims to identity1
            _datas = _datas.map((v) => { return web3.sha3(metaIdentity.address + v, { encoding: 'hex' }) })
            _signingDatas = _datas.map((v, i) => { return web3.sha3(metaIdentity.address + _topicPacked[i] + v.slice(2), { encoding: 'hex' }) })
            _signatures = _signingDatas.map((v, i) => { return web3.eth.sign(_issuers[i], v) })

            await metaIdentity.addClaim(_topics[0], _scheme, _issuers[0], _signatures[0], _datas[0], _uris[0], { from: identity1 })
            await metaIdentity.addClaim(_topics[1], _scheme, _issuers[1], _signatures[1], _datas[1], _uris[1], { from: identity1 })
            await metaIdentity.addClaim(_topics[2], _scheme, _issuers[2], _signatures[2], _datas[2], _uris[2], { from: identity1 })

            // request achievement
            //let addKeyData = await identity.contract.addKey.getData(keys.action[3], Purpose.ACTION, KeyType.ECDSA);
            let _achievementId = await achievementManager.getAchievementId(aa1, _topics, _issuers)
            let _requestData = await achievementManager.contract.requestAchievement.getData(_achievementId)
            
            await metaIdentity.execute(achievementManager.address, 0, _requestData, { from: identity1})

            let achiBal = await achievement.balanceOf(metaIdentity.address)
            assert.equal(achiBal, 1)
            /*
            const { logs } = 
            assert.equal(logs.length, 1);
            assert.equal(logs[0].event, 'Transfer');
            assert.equal(logs[0].args.from, owner);
            assert.equal(logs[0].args.to, to);
            assert(logs[0].args.value.eq(amount));
            */
            //let achievementCnt = await 

        });

        it('user who has enough claims can get achievement(some topics not registered)', async () => {

        });

        it('user who has enough claims can get achievement(all topics registered)', async () => {

        });

    });

});

// ganache-cli -d -m '' -l 10000000
// aa create achievement -> register to topic, register to aa
// ask achievement -> mint achievement erc721
// update achievement
// delete achievement

// deploy registry
// deploy identity manager
// deploy identity using identity manager
// add self claim