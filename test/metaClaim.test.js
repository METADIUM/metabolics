// deploy registry
// deploy identity manager
// deploy identity using identity manager
// add self claim
import assertRevert from './helpers/assertRevert';
import EVMRevert from './helpers/EVMRevert';

const BigNumber = web3.BigNumber;

require('chai').use(require('chai-as-promised')).use(require('chai-bignumber')(BigNumber)).should();

const IdentityManager = artifacts.require('IdentityManager.sol');
const Registry = artifacts.require('Registry.sol');
const MetaIdentity = artifacts.require('MetaIdentity.sol');

contract('Metadium Identity Meta Claim', function ([deployer, owner, proxy1, proxy2, user1, user2, issuerKey, aa1]) {
  const ZERO_ADDRESS = '0x0000000000000000000000000000000000000000';
  const defaultGas = 8000000;
  const defaultGasPrice = 10;

  beforeEach(async function () {
    this.identityManager = await IdentityManager.new();
    this.registry = await Registry.new();
    await this.identityManager.setRegistry(this.registry.address);
    await this.registry.setContractDomain('IdentityManager', this.identityManager.address);

    await this.registry.setPermission('IdentityManager', proxy1, 'true');
  });

  describe('Create MetaID', function () {
    beforeEach(async function () {

    });

    it('create Meta ID and add self claim(issuer == managementkey)', async function () {
      // uint256 _topic, uint256 _scheme, address issuer, bytes _signature, bytes _data, string _uri
      const _topic = 1; // MetaID_TOPIC
      const _scheme = 1; // ECDSA_SCHEME
      const _issuer = user1;
      const _data = '0x1b442640e0333cb03054940e3cda07da982d2b57af68c3df8d0557b47a77d0bc'; // metaPrint
      const _uri = 'MetaPrint';

      // abi.encodePacked(subject, topic, data) -> topic with uint256 packed 32bytes
      const topicPacked = '0000000000000000000000000000000000000000000000000000000000000001';
      let signingData = topicPacked + '1b442640e0333cb03054940e3cda07da982d2b57af68c3df8d0557b47a77d0bc';

      await this.identityManager.createMetaId(user1, { from: proxy1, gas: defaultGas });

      // 637ce7ee7858ae3599330d8435f75b2488f0fc8f73e85a6d7a3b1e8751ed9d0b, 0xeedbabac60f6cb77a94fc8bf82a168b318c8d204
      console.log(`user1 : ${user1}`);
      console.log('address : 0xeedbabac60f6cb77a94fc8bf82a168b318c8d204');

      const metaIds = await this.identityManager.getDeployedMetaIds();
      const metaId = await MetaIdentity.at(metaIds[0]);

      signingData = metaIds[0] + signingData;
      console.log(`_topic: ${_topic}`);
      console.log(`_scheme: ${_scheme}`);

      console.log(`metaId: ${metaId}`);
      console.log(`metaId: ${metaIds[0]}`);

      console.log(`signing Data before sha3: ${signingData}`);

      signingData = web3.sha3(signingData, { encoding: 'hex' });

      console.log(`signing Data after sha3: ${signingData}`);

      const _signature = web3.eth.sign(user1, signingData);

      console.log(`_signature: ${_signature}`);

      await metaId.addClaim(_topic, _scheme, _issuer, _signature, _data, _uri, { from: user1, gas: defaultGas });

      const nClaims = await metaId.numClaims();
      assert.equal(nClaims, 1);

      // let claimId = await metaId.getClaimId(user1, _topic)
      // let claim = await metaId.getClaim(claimId)

      // console.log(JSON.stringify(claim));

      // console.log(JSON.stringify(nClaims));
      // let _nonce = await metaId.nonce();
      // console.log(JSON.stringify(_nonce));
    });
    it('create Meta ID and add self claim(issuer == metaId)', async function () {
      // uint256 _topic, uint256 _scheme, address issuer, bytes _signature, bytes _data, string _uri
      const _topic = 1; // MetaID_TOPIC
      const _scheme = 1; // ECDSA_SCHEME
      let _issuer = user1;
      const _data = '0x1b442640e0333cb03054940e3cda07da982d2b57af68c3df8d0557b47a77d0bc'; // metaID
      const _uri = 'MetaPrint';

      // abi.encodePacked(subject, topic, data) -> topic with uint256 packed 32bytes
      const topicPacked = '0000000000000000000000000000000000000000000000000000000000000001';
      let signingData = topicPacked + '1b442640e0333cb03054940e3cda07da982d2b57af68c3df8d0557b47a77d0bc';

      await this.identityManager.createMetaId(user1, { from: proxy1, gas: defaultGas });

      const metaIds = await this.identityManager.getDeployedMetaIds();
      const metaId = await MetaIdentity.at(metaIds[0]);

      signingData = metaIds[0] + signingData;
      signingData = web3.sha3(signingData, { encoding: 'hex' });

      const _signature = web3.eth.sign(user1, signingData);

      _issuer = metaIds[0];
      await metaId.addClaim(_topic, _scheme, _issuer, _signature, _data, _uri, { from: user1, gas: defaultGas });

      const nClaims = await metaId.numClaims();
      assert.equal(nClaims, 1);

      // let claimId = await metaId.getClaimId(user1, _topic)
      // let claim = await metaId.getClaim(claimId)

      // console.log(JSON.stringify(claim));

      // console.log(JSON.stringify(nClaims));
      // let _nonce = await metaId.nonce();
      // console.log(JSON.stringify(_nonce));
    });

    it('create Meta ID and add self claim by proxy', async function () {
      // uint256 _topic, uint256 _scheme, address issuer, bytes _signature, bytes _data, string _uri
      const _topic = 1; // MetaID_TOPIC
      const _scheme = 1; // ECDSA_SCHEME
      const _issuer = user1;
      const _data = '0x1b442640e0333cb03054940e3cda07da982d2b57af68c3df8d0557b47a77d0bc'; // metaPrint
      const _uri = 'MetaPrint';

      // abi.encodePacked(subject, topic, data) -> topic with uint256 packed 32bytes
      const topicPacked = '0000000000000000000000000000000000000000000000000000000000000001';
      let signingData = topicPacked + '1b442640e0333cb03054940e3cda07da982d2b57af68c3df8d0557b47a77d0bc';

      await this.identityManager.createMetaId(user1, { from: proxy1, gas: defaultGas });

      const metaIds = await this.identityManager.getDeployedMetaIds();
      const metaId = await MetaIdentity.at(metaIds[0]);

      signingData = metaIds[0] + signingData;
      signingData = web3.sha3(signingData, { encoding: 'hex' });

      const _signature = web3.eth.sign(user1, signingData);

      const schmePacked = '0000000000000000000000000000000000000000000000000000000000000001';
      let managementKeySigningData = '0x' + topicPacked + schmePacked + _issuer.slice(2) + _signature.slice(2) + _data.slice(2);

      // In solidity, abi.encodePacked(string) -> byte encodeing("ab" -> 0x6162)
      managementKeySigningData += Buffer.from(_uri, 'utf8').toString('hex');
      managementKeySigningData = web3.sha3(managementKeySigningData, { encoding: 'hex' });

      const managementKeySignature = web3.eth.sign(user1, managementKeySigningData);

      await metaId.addClaimByProxy(_topic, _scheme, _issuer, _signature, _data, _uri, managementKeySignature, { from: user1, gas: defaultGas });

      const nClaims = await metaId.numClaims();
      assert.equal(nClaims, 1);
    });

    it('create Meta ID and addClaim by DelegatedExcute', async function () {
      // uint256 _topic, uint256 _scheme, address issuer, bytes _signature, bytes _data, string _uri
      const _topic = 1; // MetaID_TOPIC
      const _scheme = 1;// ECDSA_SCHEME
      const _issuer = user1;
      const _data = '0x1b442640e0333cb03054940e3cda07da982d2b57af68c3df8d0557b47a77d0bc'; // metaID
      const _uri = 'MetaPrint';

      // abi.encodePacked(subject, topic, data) -> topic with uint256 packed 32bytes
      const topicPacked = '0000000000000000000000000000000000000000000000000000000000000001';
      let signingData = topicPacked + '1b442640e0333cb03054940e3cda07da982d2b57af68c3df8d0557b47a77d0bc';

      await this.identityManager.createMetaId(user1, { from: proxy1, gas: defaultGas });

      const metaIds = await this.identityManager.getDeployedMetaIds();
      const metaId = await MetaIdentity.at(metaIds[0]);
      console.log(`metaId[0] : ${metaIds[0]}`);
      console.log(`_topic : ${_topic}`);
      console.log(`_scheme : ${_scheme}`);
      console.log(`_issuer : ${_issuer}`);
      console.log(`_data : ${_data}`);
      console.log(`_uri : ${_uri}`);

      signingData = metaIds[0] + signingData;
      console.log(`signingData before hash : ${signingData}`);
      signingData = web3.sha3(signingData, { encoding: 'hex' });
      console.log(`signingData after hash : ${signingData}`);
      const _signature = web3.eth.sign(user1, signingData);
      console.log(`_signature : ${_signature}`);

      const addClaimData = await metaId.contract.addClaim.getData(_topic, _scheme, _issuer, _signature, _data, _uri);
      console.log(`addClaimData : ${addClaimData}`);
      const _nonce = 1;
      const noncePacked = '000000000000000000000000000000000000000000000000000000000000000' + _nonce;
      const valuePacked = '0000000000000000000000000000000000000000000000000000000000000000';
      let managementKeySigningData = '0x' + metaIds[0].slice(2) + valuePacked + addClaimData.slice(2) + noncePacked;

      console.log(`managementKeySigningData : ${managementKeySigningData}`);

      // In solidity, abi.encodePacked(string) -> byte encodeing("ab" -> 0x6162)
      // managementKeySigningData += Buffer.from(_uri, 'utf8').toString('hex')
      managementKeySigningData = web3.sha3(managementKeySigningData, { encoding: 'hex' });

      console.log(`managementKeySigningData Sha3 Hashed : ${managementKeySigningData}`);

      const managementKeySignature = web3.eth.sign(user1, managementKeySigningData);

      console.log(`managementKeySignature : ${managementKeySignature}`);

      await metaId.delegatedExecute(metaIds[0], 0, addClaimData, _nonce, managementKeySignature, { from: user2 });
      // delegatedExecute(address _to, uint256 _value, bytes _data, uint256 _nonce, bytes _sig)

      const nClaims = await metaId.numClaims();
      assert.equal(nClaims, 1);
    });

    describe('various addClaim -> approve', async function () {
      // uint256 _topic, uint256 _scheme, address issuer, bytes _signature, bytes _data, string _uri
      const _topic = 1; // MetaID_TOPIC
      const _scheme = 1;// ECDSA_SCHEME
      const _issuer = aa1;
      const _data = '0x1b442640e0333cb03054940e3cda07da982d2b57af68c3df8d0557b47a77d0bc'; // metaID
      const _uri = 'MetaPrint';

      // abi.encodePacked(subject, topic, data) -> topic with uint256 packed 32bytes
      const topicPacked = '0000000000000000000000000000000000000000000000000000000000000001';
      let signingData = topicPacked + '1b442640e0333cb03054940e3cda07da982d2b57af68c3df8d0557b47a77d0bc';
      let metaId, metaIds;

      beforeEach(async function () {
        await this.identityManager.createMetaId(user1, { from: proxy1, gas: defaultGas });
        metaIds = await this.identityManager.getDeployedMetaIds();
        metaId = await MetaIdentity.at(metaIds[0]);
      });

      it('direct addClaim on the user1 identity from AA(key) -> DelegateApprove', async function () {
        signingData = metaIds[0] + signingData;
        signingData = web3.sha3(signingData, { encoding: 'hex' });

        // direct call to addClaim on the user identity By AA
        let _signature = web3.eth.sign(aa1, signingData);
        // let d = await metaId.getSignatureAddress(signingData, _signature)
        // console.log(_issuer)
        // console.log(aa1)

        await metaId.addClaim(_topic, _scheme, _issuer, _signature, _data, _uri, { from: aa1 });

        let nClaims = await metaId.numClaims();
        assert.equal(nClaims, 0);

        // delegatedApprove by User
        const _nonce = 2;
        const noncePacked = '000000000000000000000000000000000000000000000000000000000000000' + _nonce;
        const addClaimData = await metaId.contract.addClaim.getData(_topic, _scheme, _issuer, _signature, _data, _uri);

        // function getExecutionId( address self,address _to, uint256 _value, bytes _data, uint _nonce)
        const _id = await metaId.getExecutionId(metaIds[0], metaIds[0], 0, addClaimData, 1);
        const idhex = _id.toString(16);

        // (_id to hex convert) + approve(bool) + _nonce pack
        let approveSigningData = '0x' + idhex + '01' + noncePacked;
        approveSigningData = web3.sha3(approveSigningData, { encoding: 'hex' });
        _signature = web3.eth.sign(user1, approveSigningData);

        await metaId.delegatedApprove('0x' + idhex, 'true', _nonce, _signature, { from: proxy1 });

        nClaims = await metaId.numClaims();
        assert.equal(nClaims, 1);
      });
    });
  });
});
