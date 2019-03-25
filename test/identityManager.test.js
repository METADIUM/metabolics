require('chai')
  .use(require('chai-bignumber')(web3.BigNumber))
  .should();

const IdentityManager = artifacts.require('IdentityManager.sol');
const Registry = artifacts.require('Registry.sol');
const MetaIdentity = artifacts.require('MetaIdentity.sol');

contract('Metadium Identity Manager', function ([deployer, owner, proxy1, proxy2, user1, user2]) {
  let identityManager, registry;

  beforeEach(async function () {
    identityManager = await IdentityManager.new();
    registry = await Registry.new();
    await identityManager.setRegistry(registry.address);
    await registry.setContractDomain('IdentityManager', identityManager.address);
    await registry.setPermission('IdentityManager', proxy1, 'true');
  });

  describe('Create MetaID', function () {
    it('basic Meta ID creation and add self claim(issuer == managementkey)', async function () {
      // uint256 _topic, uint256 _scheme, address issuer, bytes _signature, bytes _data, string _uri
      const _topic = 1; // MetaID_TOPIC
      const _scheme = 1; // ECDSA_SCHEME
      const _issuer = user1;
      const _data = '0x1b442640e0333cb03054940e3cda07da982d2b57af68c3df8d0557b47a77d0bc'; // metaID
      const _uri = 'MetaPrint';

      // abi.encodePacked(subject, topic, data) -> topic with uint256 packed 32bytes
      const topicPacked = '0000000000000000000000000000000000000000000000000000000000000001';
      let signingData = topicPacked + '1b442640e0333cb03054940e3cda07da982d2b57af68c3df8d0557b47a77d0bc';

      await identityManager.createMetaId(user1, { from: proxy1 });

      const metaIds = await identityManager.getDeployedMetaIds();
      const metaId = await MetaIdentity.at(metaIds[0]);

      signingData = metaIds[0] + signingData;
      signingData = web3.sha3(signingData, { encoding: 'hex' });

      const _signature = web3.eth.sign(user1, signingData);

      await metaId.addClaim(_topic, _scheme, _issuer, _signature, _data, _uri, { from: user1 });

      const nClaims = await metaId.numClaims();
      assert.equal(nClaims, 1);
    });
  });

  describe('Basic functions', function () {
    beforeEach(async function () {
      await identityManager.createMetaId(user1, { from: proxy1 });
    });

    it('Add already existing Meta Id', async () => {
      let meta2 = await MetaIdentity.new(proxy2);
      await identityManager.addMetaId(meta2.address, proxy2, { from: proxy1 });

      const s = await identityManager.isMetaId(meta2.address);
      assert.equal(s, true);
    });

    it('Check Meta Id exists', async () => {
      const metaIds = await identityManager.getDeployedMetaIds();

      const s = await identityManager.isMetaId(metaIds[0]);
      assert.equal(s, true);
    });
  });
});
