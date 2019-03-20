const { reverting } = require('openzeppelin-solidity/test/helpers/shouldFail');

require('chai')
  .use(require('chai-bignumber')(web3.BigNumber))
  .should();

const MetaIdentity = artifacts.require('MetaIdentity.sol');
const Registry = artifacts.require('Registry.sol');
const TopicRegistry = artifacts.require('TopicRegistry.sol');
const AttestationAgencyRegistry = artifacts.require('AttestationAgencyRegistry.sol');
const AchievementManager = artifacts.require('AchievementManager.sol');
const Achievement = artifacts.require('Achievement.sol');
const IdentityManager = artifacts.require('IdentityManager.sol');

contract('Achievement Manager', function ([deployer, identity1, aa1, user1, identity2, issuer1, issuer2, issuer3, proxy1]) {
  let registry, topicRegistry, aaRegistry, identityManager, achievementManager, metaIdentity, achievement;
  let metaIdentity2;
  const ether1 = 1000000000000000000;
  let _topics, _issuers, _title, _achievementExplanation, _reward, _uri;
  const _scheme = 1;

  beforeEach(async () => {
    // deploy all
    registry = await Registry.new();
    aaRegistry = await AttestationAgencyRegistry.new();
    topicRegistry = await TopicRegistry.new();
    achievementManager = await AchievementManager.new();
    identityManager = await IdentityManager.new();
    achievement = await Achievement.new('Achievement', 'MACH');
    // metaIdentity = await MetaIdentity.new(identity1, { from: identity1 })

    // set domain & permission
    await registry.setContractDomain('TopicRegistry', topicRegistry.address);
    await registry.setContractDomain('Achievement', achievement.address);
    await registry.setContractDomain('IdentityManager', identityManager.address);
    await registry.setContractDomain('AttestationAgencyRegistry', aaRegistry.address);

    await registry.setPermission('Achievement', achievementManager.address, 'true');
    await registry.setPermission('IdentityManager', proxy1, 'true');
    await registry.setPermission('AttestationAgencyRegistry', proxy1, 'true');

    await identityManager.setRegistry(registry.address);

    await achievementManager.setRegistry(registry.address);
    await achievement.setRegistry(registry.address);
    await aaRegistry.setRegistry(registry.address);
    await topicRegistry.setRegistry(registry.address);

    await identityManager.createMetaId(identity1, { from: proxy1 });
    await identityManager.createMetaId(identity2, { from: proxy1 });

    const metaIds = await identityManager.getDeployedMetaIds();
    metaIdentity = await MetaIdentity.at(metaIds[0]);
    metaIdentity2 = await MetaIdentity.at(metaIds[1]);
  });

  describe('Create achievement', function () {
    beforeEach(async () => {
      await registerTopics();
    });

    it('AA with enough balance can create achievement', async () => {
      await achievementManager.createAchievement(_topics, _issuers, _title, _achievementExplanation, _reward, _uri, { from: aa1, value: ether1 });

      const achiv = await achievementManager.getAchievementByIndex(0);
      assert.equal(achiv[1], aa1);

      const bal = await web3.eth.getBalance(achievementManager.address);
      assert.equal(bal, ether1);
    });

    it('AA with not enough balance cannot create achievement', async () => {
      await reverting(achievementManager.createAchievement(_topics, _issuers, _title, _achievementExplanation, _reward, _uri, { from: aa1, value: 10000 }));
    });

    it('AA cannot create with not registered topic', async () => {
      _topics = [1025, 1026, 1029];
      await reverting(achievementManager.createAchievement(_topics, _issuers, _title, _achievementExplanation, _reward, _uri, { from: aa1, value: ether1 }));
    });

    it('AA cannot create achievement withs same achievementId(same topic-issuers-creator)', async () => {
      _topics = [1025, 1025, 1026];
      _issuers = [issuer1, issuer1, issuer3];
      await reverting(achievementManager.createAchievement(_topics, _issuers, _title, _achievementExplanation, _reward, _uri, { from: aa1, value: ether1 }));
    });

    it('non-AA cannot create achievement', async () => {
      await reverting(achievementManager.createAchievement(_topics, _issuers, _title, _achievementExplanation, _reward, _uri, { from: user1, value: ether1 }));
    });

    it('topics can be any order', async () => {
      _topics = [1025, 1027, 1026];
      await achievementManager.createAchievement(_topics, _issuers, _title, _achievementExplanation, _reward, _uri, { from: aa1, value: ether1 });
    });
  });

  describe('Update achievement', function () {
    let achivId;

    beforeEach(async () => {
      await registerTopics();

      await achievementManager.createAchievement(_topics, _issuers, _title, _achievementExplanation, _reward, _uri, { from: aa1, value: ether1 });

      const achiv = await achievementManager.getAchievementByIndex(0);
      achivId = achiv[0];
    });

    it('achievement creator can charge the fund and change the reward', async () => {
      await achievementManager.updateAchievement(achivId, ether1, { from: aa1, value: ether1 });

      const achiv = await achievementManager.getAchievementByIndex(0);
      assert.equal(achiv[6], ether1);

      const bal = await web3.eth.getBalance(achievementManager.address);
      assert.equal(bal, ether1 * 2);
    });

    it('other users cannot charge the fund and cannot change the reward', async () => {
      await reverting(achievementManager.updateAchievement(achivId, ether1, { from: user1, value: ether1 }));
    });
  });

  describe('Request achievement', function () {
    let achivId, _achievementId, _requestData;

    beforeEach(async () => {
      await registerTopics();
      await achievementManager.createAchievement(_topics, _issuers, _title, _achievementExplanation, _reward, _uri, { from: aa1, value: ether1 });

      const achiv = await achievementManager.getAchievementByIndex(0);
      achivId = achiv[0];

      await registerUserClaim(identity1, metaIdentity);

      _achievementId = await achievementManager.getAchievementId(aa1, _topics, _issuers);
      _requestData = await achievementManager.contract.requestAchievement.getData(_achievementId);
    });

    it('user with enough claim can request achievement', async () => {
      const IdentityBal = await web3.eth.getBalance(identity1);

      const r = await metaIdentity.execute(achievementManager.address, 0, _requestData, { from: identity1 });

      const achiBal = await achievement.balanceOf(metaIdentity.address);
      assert.equal(achiBal, 1);

      const gasPrice = await web3.eth.getTransaction(r.tx).gasPrice.toNumber();

      // when the reward goes to the identity's 0th management key
      // let expectedBal = IdentityBal - (gasPrice * r.receipt.gasUsed) + _reward
      // IdentityBal = await web3.eth.getBalance(identity1)
      // assert.equal(IdentityBal, expectedBal)
    });

    it('user without metaId cannot request achievement', async () => {
      await reverting(metaIdentity.execute(achievementManager.address, 0, _requestData, { from: user1 }));
    });

    it('user cannot get achievement if there is no balance for that achievement', async () => {
      await registerUserClaim(identity2, metaIdentity2);
      await metaIdentity.execute(achievementManager.address, 0, _requestData, { from: identity1 });

      await metaIdentity2.execute(achievementManager.address, 0, _requestData, { from: identity2 });

      const achiBal = await achievement.balanceOf(metaIdentity.address);
      assert.equal(achiBal, 1);

      const achiBal2 = await achievement.balanceOf(metaIdentity2.address);
      assert.equal(achiBal2, 0);
    });

    it('user cannot request same achievement twice', async () => {
      await metaIdentity.execute(achievementManager.address, 0, _requestData, { from: identity1 });

      let achiBal = await achievement.balanceOf(metaIdentity.address);
      assert.equal(achiBal, 1);

      // this request fails but, not revert. ExcutionFail event emitted
      await metaIdentity.execute(achievementManager.address, 0, _requestData, { from: identity1 });

      achiBal = await achievement.balanceOf(metaIdentity.address);
      assert.equal(achiBal, 1);
    });

    it('user with self-claim can get achievement', async () => {
      // AA create achievement
      _topics = [1025, 1026, 1027];
      _issuers = ['0xFFfFfFffFFfffFFfFFfFFFFFffFFFffffFfFFFfF', '0xFFfFfFffFFfffFFfFFfFFFFFffFFFffffFfFFFfF', '0xFFfFfFffFFfffFFfFFfFFFFFffFFFffffFfFFFfF'];// [issuer1, issuer2, issuer3]
      _title = '0x1234';
      _achievementExplanation = '0x12';
      _reward = 0.1 * 10 ** 18;
      _uri = '0x3be095406c14a224018c2e749ef954073b0f71f8cef30bb0458aab8662a447a0';

      let _signatures = [];
      let _datas = ['facebook user', 'twitter user', 'google user'];
      let _signingDatas = [];
      const _uris = ['claim1uri', 'claim2uri', 'claim3uri'];
      const _topicPacked = ['0000000000000000000000000000000000000000000000000000000000000401', '0000000000000000000000000000000000000000000000000000000000000402', '0000000000000000000000000000000000000000000000000000000000000403'];
      // create achievement
      await achievementManager.createAchievement(_topics, _issuers, _title, _achievementExplanation, _reward, _uri, { from: aa1, value: ether1 });

      const bal = await web3.eth.getBalance(achievementManager.address);
      assert.equal(bal, ether1 * 2);

      // register claims to identity1
      _datas = _datas.map((v) => { return web3.sha3(metaIdentity.address + v, { encoding: 'hex' }); });
      _signingDatas = _datas.map((v, i) => { return web3.sha3(metaIdentity.address + _topicPacked[i] + v.slice(2), { encoding: 'hex' }); });
      _signatures = _signingDatas.map((v, i) => { return web3.eth.sign(identity1, v); });

      await metaIdentity.addClaim(_topics[0], _scheme, identity1, _signatures[0], _datas[0], _uris[0], { from: identity1 });
      await metaIdentity.addClaim(_topics[1], _scheme, identity1, _signatures[1], _datas[1], _uris[1], { from: identity1 });
      await metaIdentity.addClaim(_topics[2], _scheme, identity1, _signatures[2], _datas[2], _uris[2], { from: identity1 });

      // request achievement
      // let addKeyData = await identity.contract.addKey.getData(keys.action[3], Purpose.ACTION, KeyType.ECDSA);
      const _achievementId = await achievementManager.getAchievementId(aa1, _topics, _issuers);
      const _requestData = await achievementManager.contract.requestAchievement.getData(_achievementId);

      await metaIdentity.execute(achievementManager.address, 0, _requestData, { from: identity1 });

      const achiBal = await achievement.balanceOf(metaIdentity.address);
      assert.equal(achiBal, 1);

      // let IdentityBal = await web3.eth.getBalance(metaIdentity.address)
      // assert.equal(IdentityBal, _reward)
    });
  });

  describe('Delete achievement', function () {
    let achivId;

    beforeEach(async () => {
      await registerTopics();

      await achievementManager.createAchievement(_topics, _issuers, _title, _achievementExplanation, _reward, _uri, { from: aa1, value: ether1 });

      const achiv = await achievementManager.getAchievementByIndex(0);
      achivId = achiv[0];
    });

    it('creator can refund the rest', async () => {
      await achievementManager.deleteAchievement(achivId, { from: aa1 });

      const bal = await web3.eth.getBalance(achievementManager.address);
      assert.equal(bal, 0);
    });

    it('other users cannot refund the rest', async () => {
      await reverting(achievementManager.deleteAchievement(achivId, { from: user1 }));
    });
  });

  // need to be cleaned up
  describe.skip('achievement basic ', function () {
    it('contract can make achievementId by the protocol', async () => {

    });

    it('user who has enough claims can get achievement(all topics not registered and above 1024)', async () => {
      // system register AA to AA registry
      await aaRegistry.registerAttestationAgency(aa1, 'metadiumAA', 'metadiumAADes', { from: proxy1 });

      // AA register topics to topic registry
      await topicRegistry.registerTopic('name', 'thisisname', { from: aa1 });
      await topicRegistry.registerTopic('nickname', 'this is nickname', { from: aa1 });
      await topicRegistry.registerTopic('email', 'this is email', { from: aa1 });

      // AA create achievement
      _topics = [1025, 1026, 1027];
      _issuers = [issuer1, issuer2, issuer3];
      _title = '0x1234';
      _achievementExplanation = '0x12';
      _reward = 0.1 * 10 ** 18;
      _uri = '0x3be095406c14a224018c2e749ef954073b0f71f8cef30bb0458aab8662a447a0';

      let _signatures = [];
      let _datas = ['facebook user', 'twitter user', 'google user'];
      let _signingDatas = [];
      const _uris = ['claim1uri', 'claim2uri', 'claim3uri'];
      const _topicPacked = ['0000000000000000000000000000000000000000000000000000000000000401', '0000000000000000000000000000000000000000000000000000000000000402', '0000000000000000000000000000000000000000000000000000000000000403'];
      // create achievement
      await achievementManager.createAchievement(_topics, _issuers, _title, _achievementExplanation, _reward, _uri, { from: aa1, value: ether1 });

      const bal = await web3.eth.getBalance(achievementManager.address);
      assert.equal(bal, ether1);

      // register claims to identity1
      _datas = _datas.map((v) => { return web3.sha3(metaIdentity.address + v, { encoding: 'hex' }); });
      _signingDatas = _datas.map((v, i) => { return web3.sha3(metaIdentity.address + _topicPacked[i] + v.slice(2), { encoding: 'hex' }); });
      _signatures = _signingDatas.map((v, i) => { return web3.eth.sign(_issuers[i], v); });

      await metaIdentity.addClaim(_topics[0], _scheme, _issuers[0], _signatures[0], _datas[0], _uris[0], { from: identity1 });
      await metaIdentity.addClaim(_topics[1], _scheme, _issuers[1], _signatures[1], _datas[1], _uris[1], { from: identity1 });
      await metaIdentity.addClaim(_topics[2], _scheme, _issuers[2], _signatures[2], _datas[2], _uris[2], { from: identity1 });

      // request achievement
      // let addKeyData = await identity.contract.addKey.getData(keys.action[3], Purpose.ACTION, KeyType.ECDSA);
      const _achievementId = await achievementManager.getAchievementId(aa1, _topics, _issuers);
      const _requestData = await achievementManager.contract.requestAchievement.getData(_achievementId);

      await metaIdentity.execute(achievementManager.address, 0, _requestData, { from: identity1 });

      const achiBal = await achievement.balanceOf(metaIdentity.address);
      assert.equal(achiBal, 1);

      const IdentityBal = await web3.eth.getBalance(metaIdentity.address);
      assert.equal(IdentityBal, _reward);

      /*
            const { logs } =
            assert.equal(logs.length, 1);
            assert.equal(logs[0].event, 'Transfer');
            assert.equal(logs[0].args.from, owner);
            assert.equal(logs[0].args.to, to);
            assert(logs[0].args.value.eq(amount));
            */
      // let achievementCnt = await
    });

    it('user can get achievement with achievement which has self-claim term', async () => {
      // system register AA to AA registry
      await aaRegistry.registerAttestationAgency(aa1, 'metadiumAA', 'metadiumAADes', { from: proxy1 });

      // AA register topics to topic registry
      await topicRegistry.registerTopic('name', 'thisisname', { from: aa1 });
      await topicRegistry.registerTopic('nickname', 'this is nickname', { from: aa1 });
      await topicRegistry.registerTopic('email', 'this is email', { from: aa1 });

      // AA create achievement
      _topics = [1025, 1026, 1027];
      _issuers = ['0xFFfFfFffFFfffFFfFFfFFFFFffFFFffffFfFFFfF', '0xFFfFfFffFFfffFFfFFfFFFFFffFFFffffFfFFFfF', '0xFFfFfFffFFfffFFfFFfFFFFFffFFFffffFfFFFfF'];// [issuer1, issuer2, issuer3]
      _title = '0x1234';
      _achievementExplanation = '0x12';
      _reward = 0.1 * 10 ** 18;
      _uri = '0x3be095406c14a224018c2e749ef954073b0f71f8cef30bb0458aab8662a447a0';

      let _signatures = [];
      let _datas = ['facebook user', 'twitter user', 'google user'];
      let _signingDatas = [];
      const _uris = ['claim1uri', 'claim2uri', 'claim3uri'];
      const _topicPacked = ['0000000000000000000000000000000000000000000000000000000000000401', '0000000000000000000000000000000000000000000000000000000000000402', '0000000000000000000000000000000000000000000000000000000000000403'];
      // create achievement
      await achievementManager.createAchievement(_topics, _issuers, _title, _achievementExplanation, _reward, _uri, { from: aa1, value: ether1 });

      const bal = await web3.eth.getBalance(achievementManager.address);
      assert.equal(bal, ether1);

      // register claims to identity1
      _datas = _datas.map((v) => { return web3.sha3(metaIdentity.address + v, { encoding: 'hex' }); });
      _signingDatas = _datas.map((v, i) => { return web3.sha3(metaIdentity.address + _topicPacked[i] + v.slice(2), { encoding: 'hex' }); });
      _signatures = _signingDatas.map((v, i) => { return web3.eth.sign(identity1, v); });

      await metaIdentity.addClaim(_topics[0], _scheme, identity1, _signatures[0], _datas[0], _uris[0], { from: identity1 });
      await metaIdentity.addClaim(_topics[1], _scheme, identity1, _signatures[1], _datas[1], _uris[1], { from: identity1 });
      await metaIdentity.addClaim(_topics[2], _scheme, identity1, _signatures[2], _datas[2], _uris[2], { from: identity1 });

      // request achievement
      // let addKeyData = await identity.contract.addKey.getData(keys.action[3], Purpose.ACTION, KeyType.ECDSA);
      const _achievementId = await achievementManager.getAchievementId(aa1, _topics, _issuers);
      const _requestData = await achievementManager.contract.requestAchievement.getData(_achievementId);

      await metaIdentity.execute(achievementManager.address, 0, _requestData, { from: identity1 });

      const achiBal = await achievement.balanceOf(metaIdentity.address);
      assert.equal(achiBal, 1);

      const IdentityBal = await web3.eth.getBalance(metaIdentity.address);
      assert.equal(IdentityBal, _reward);
    });
  });

  async function registerTopics () {
    // system register AA to AA registry
    await aaRegistry.registerAttestationAgency(aa1, 'metadiumAA', 'metadiumAADes', { from: proxy1 });

    // AA register topics to topic registry
    await topicRegistry.registerTopic('name', 'thisisname', { from: aa1 });
    await topicRegistry.registerTopic('nickname', 'this is nickname', { from: aa1 });
    await topicRegistry.registerTopic('email', 'this is email', { from: aa1 });

    // AA create achievement
    _topics = [1025, 1026, 1027];
    _issuers = [issuer1, issuer2, issuer3];
    _title = '0x1234';
    _achievementExplanation = '0x12';
    _reward = 1 * 10 ** 18;
    _uri = '0x3be095406c14a224018c2e749ef954073b0f71f8cef30bb0458aab8662a447a0';
  }

  async function registerUserClaim (_identity, _metaIdentity) {
    // register claims to identity1
    let _signatures = [];
    let _datas = ['facebook user', 'twitter user', 'google user'];
    let _signingDatas = [];
    const _uris = ['claim1uri', 'claim2uri', 'claim3uri'];
    const _topicPacked = ['0000000000000000000000000000000000000000000000000000000000000401', '0000000000000000000000000000000000000000000000000000000000000402', '0000000000000000000000000000000000000000000000000000000000000403'];

    _datas = _datas.map((v) => { return web3.sha3(_metaIdentity.address + v, { encoding: 'hex' }); });
    _signingDatas = _datas.map((v, i) => { return web3.sha3(_metaIdentity.address + _topicPacked[i] + v.slice(2), { encoding: 'hex' }); });
    _signatures = _signingDatas.map((v, i) => { return web3.eth.sign(_issuers[i], v); });

    await _metaIdentity.addClaim(_topics[0], _scheme, _issuers[0], _signatures[0], _datas[0], _uris[0], { from: _identity });
    await _metaIdentity.addClaim(_topics[1], _scheme, _issuers[1], _signatures[1], _datas[1], _uris[1], { from: _identity });
    await _metaIdentity.addClaim(_topics[2], _scheme, _issuers[2], _signatures[2], _datas[2], _uris[2], { from: _identity });
  }
});
