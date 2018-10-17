// deploy registry
// deploy identity manager
// deploy identity using identity manager
// add self claim
import assertRevert from './helpers/assertRevert';
import EVMRevert from './helpers/EVMRevert';

const BigNumber = web3.BigNumber;

require('chai').use(require('chai-as-promised')).use(require('chai-bignumber')(BigNumber)).should();


const IdentityManager = artifacts.require('IdentityManager.sol')
const Registry = artifacts.require('Registry.sol')
const MetaIdentity = artifacts.require('MetaIdentity.sol');


contract('Metadium Identity Manager', function ([deployer, owner, proxy1, proxy2, user1, user2]) {
    const ZERO_ADDRESS = '0x0000000000000000000000000000000000000000';
    const defaultGas = 8000000;
    const defaultGasPrice = 10;


    beforeEach(async function () {
        this.identityManager = await IdentityManager.new();
        this.registry = await Registry.new();
        await this.identityManager.setRegistry(this.registry.address);
        await this.registry.setContractDomain("IdentityManager", this.identityManager.address );

        await this.registry.setPermission("IdentityManager", proxy1, "true");

    });

    describe('Create MetaID', function () {
        beforeEach(async function () {

        });

        it('create Meta ID and add self claim', async function () {
            //uint256 _topic, uint256 _scheme, address issuer, bytes _signature, bytes _data, string _uri
            let _topic = 1 // MetaID_TOPIC
            let _scheme = 1 // ECDSA_SCHEME
            let _issuer = user1
            let _data = "0x1b442640e0333cb03054940e3cda07da982d2b57af68c3df8d0557b47a77d0bc" // metaID
            let _uri = "MetaPrint"

            //abi.encodePacked(subject, topic, data) -> topic with uint256 packed 32bytes
            let topicPacked = "0000000000000000000000000000000000000000000000000000000000000001"
            let signingData = topicPacked+"1b442640e0333cb03054940e3cda07da982d2b57af68c3df8d0557b47a77d0bc"

            await this.identityManager.createMetaId(user1, { from: proxy1, gas: defaultGas })

            let metaIds = await this.identityManager.getDeployedMetaIds()
            let metaId = await MetaIdentity.at(metaIds[0])
            
            signingData = metaIds[0] + signingData
            signingData = web3.sha3(signingData, { encoding: 'hex' })
            
            let _signature = web3.eth.sign(user1, signingData)
            
            await metaId.addClaim(_topic, _scheme, _issuer, _signature, _data, _uri, { from: user1, gas: defaultGas })

            let nClaims = await metaId.numClaims();
            assert.equal(nClaims, 1)
            
            // let claimId = await metaId.getClaimId(user1, _topic)
            // let claim = await metaId.getClaim(claimId)
            
            // console.log(JSON.stringify(claim));

            // console.log(JSON.stringify(nClaims));
            // let _nonce = await metaId.nonce();
            // console.log(JSON.stringify(_nonce));


        });

        it.only('create Meta ID and add self claim by proxy', async function () {
            //uint256 _topic, uint256 _scheme, address issuer, bytes _signature, bytes _data, string _uri
            let _topic = 1 // MetaID_TOPIC
            let _scheme = 1 // ECDSA_SCHEME
            let _issuer = user1
            let _data = "0x1b442640e0333cb03054940e3cda07da982d2b57af68c3df8d0557b47a77d0bc" // metaID
            let _uri = "MetaPrint"

            //abi.encodePacked(subject, topic, data) -> topic with uint256 packed 32bytes
            let topicPacked = "0000000000000000000000000000000000000000000000000000000000000001"
            let signingData = topicPacked+"1b442640e0333cb03054940e3cda07da982d2b57af68c3df8d0557b47a77d0bc"
            
            await this.identityManager.createMetaId(user1, { from: proxy1, gas: defaultGas })

            let metaIds = await this.identityManager.getDeployedMetaIds()
            let metaId = await MetaIdentity.at(metaIds[0])
            
            signingData = metaIds[0] + signingData
            signingData = web3.sha3(signingData, { encoding: 'hex' })
            
            let _signature = web3.eth.sign(user1, signingData)
            
            let schmePacked = "0000000000000000000000000000000000000000000000000000000000000001"
            let managementKeySigningData = "0x" + topicPacked + schmePacked + _issuer.slice(2) + _signature.slice(2) + _data.slice(2)
            
            //In solidity, abi.encodePacked(string) -> byte encodeing("ab" -> 0x6162)
            managementKeySigningData += Buffer.from(_uri, 'utf8').toString('hex')
            managementKeySigningData = web3.sha3(managementKeySigningData, { encoding: 'hex' })

            let managementKeySignature = web3.eth.sign(user1, managementKeySigningData)

            await metaId.addClaimByProxy(_topic, _scheme, _issuer, _signature, _data, _uri, managementKeySignature, { from: user1, gas: defaultGas })

            let nClaims = await metaId.numClaims();
            assert.equal(nClaims, 1)
            

        });

        it.only('create Meta ID and addClaim by DelegatedExcute', async function () {
            //uint256 _topic, uint256 _scheme, address issuer, bytes _signature, bytes _data, string _uri
            let _topic = 1 // MetaID_TOPIC
            let _scheme = 1 // ECDSA_SCHEME
            let _issuer = user1
            let _data = "0x1b442640e0333cb03054940e3cda07da982d2b57af68c3df8d0557b47a77d0bc" // metaID
            let _uri = "MetaPrint"

            //abi.encodePacked(subject, topic, data) -> topic with uint256 packed 32bytes
            let topicPacked = "0000000000000000000000000000000000000000000000000000000000000001"
            let signingData = topicPacked+"1b442640e0333cb03054940e3cda07da982d2b57af68c3df8d0557b47a77d0bc"
            
            await this.identityManager.createMetaId(user1, { from: proxy1, gas: defaultGas })

            let metaIds = await this.identityManager.getDeployedMetaIds()
            let metaId = await MetaIdentity.at(metaIds[0])
            
            
            signingData = metaIds[0] + signingData
            signingData = web3.sha3(signingData, { encoding: 'hex' })
            
            let _signature = web3.eth.sign(user1, signingData)

            let addClaimData = await metaId.contract.addClaim.getData(_topic, _scheme, _issuer, _signature, _data, _uri)

            let _nonce = 0
            let noncePacked = "000000000000000000000000000000000000000000000000000000000000000" + _nonce
            let valuePacked = "0000000000000000000000000000000000000000000000000000000000000000"
            let managementKeySigningData = "0x" + metaIds[0].slice(2) + valuePacked + addClaimData.slice(2) + noncePacked

            
            //In solidity, abi.encodePacked(string) -> byte encodeing("ab" -> 0x6162)
            // managementKeySigningData += Buffer.from(_uri, 'utf8').toString('hex')
            managementKeySigningData = web3.sha3(managementKeySigningData, { encoding: 'hex' })

            let managementKeySignature = web3.eth.sign(user1, managementKeySigningData)
            await metaId.delegatedExecute(metaIds[0], 0, addClaimData, _nonce, managementKeySignature, {from:user2})
            //delegatedExecute(address _to, uint256 _value, bytes _data, uint256 _nonce, bytes _sig)  

            let nClaims = await metaId.numClaims();
            assert.equal(nClaims, 1)
            

        });

    });

});
