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


contract('Metadium Identity Meta Claim', function ([deployer, owner, proxy1, proxy2, user1, user2]) {
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

        it.only('create Meta ID and add self claim(issuer == managementkey)', async function () {
            //uint256 _topic, uint256 _scheme, address issuer, bytes _signature, bytes _data, string _uri
            let _topic = 1 // MetaID_TOPIC
            let _scheme = 1 // ECDSA_SCHEME
            let _issuer = user1
            let _data = "0x1b442640e0333cb03054940e3cda07da982d2b57af68c3df8d0557b47a77d0bc" // metaPrint
            let _uri = "MetaPrint"

            //abi.encodePacked(subject, topic, data) -> topic with uint256 packed 32bytes
            let topicPacked = "0000000000000000000000000000000000000000000000000000000000000001"
            let signingData = topicPacked+"1b442640e0333cb03054940e3cda07da982d2b57af68c3df8d0557b47a77d0bc"

            await this.identityManager.createMetaId(user1, { from: proxy1, gas: defaultGas })

            //637ce7ee7858ae3599330d8435f75b2488f0fc8f73e85a6d7a3b1e8751ed9d0b, 0xeedbabac60f6cb77a94fc8bf82a168b318c8d204
            console.log(`user1 : ${user1}`)
            console.log(`address : 0xeedbabac60f6cb77a94fc8bf82a168b318c8d204`)
            

            let metaIds = await this.identityManager.getDeployedMetaIds()
            let metaId = await MetaIdentity.at(metaIds[0])
            

            signingData = metaIds[0] + signingData
            console.log(`_topic: ${_topic}`)
            console.log(`_scheme: ${_scheme}`)
            
            console.log(`metaId: ${metaId}`)

            console.log(`signing Data before sha3: ${signingData}`)

            signingData = web3.sha3(signingData, { encoding: 'hex' })

            console.log(`signing Data after sha3: ${signingData}`)
            
            let _signature = web3.eth.sign(user1, signingData)

            console.log(`_signature: ${_signature}`)
            
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

        it('create Meta ID and add self claim(issuer == metaId)', async function () {
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
            
            _issuer = metaIds[0]
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

        it('create Meta ID and add self claim by proxy', async function () {
            //uint256 _topic, uint256 _scheme, address issuer, bytes _signature, bytes _data, string _uri
            let _topic = 1 // MetaID_TOPIC
            let _scheme = 1 // ECDSA_SCHEME
            let _issuer = user1
            let _data = "0x1b442640e0333cb03054940e3cda07da982d2b57af68c3df8d0557b47a77d0bc" // metaPrint
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

        it('create Meta ID and addClaim by DelegatedExcute', async function () {
            //uint256 _topic, uint256 _scheme, address issuer, bytes _signature, bytes _data, string _uri
            let _topic = 1 // MetaID_TOPIC
            let _scheme = 1// ECDSA_SCHEME
            let _issuer = user1
            let _data = "0x1b442640e0333cb03054940e3cda07da982d2b57af68c3df8d0557b47a77d0bc" // metaID
            let _uri = "MetaPrint"

            //abi.encodePacked(subject, topic, data) -> topic with uint256 packed 32bytes
            let topicPacked = "0000000000000000000000000000000000000000000000000000000000000001"
            let signingData = topicPacked+"1b442640e0333cb03054940e3cda07da982d2b57af68c3df8d0557b47a77d0bc"
            
            await this.identityManager.createMetaId(user1, { from: proxy1, gas: defaultGas })

            let metaIds = await this.identityManager.getDeployedMetaIds()
            let metaId = await MetaIdentity.at(metaIds[0])
            console.log(`metaId[0] : ${metaIds[0]}`)
            console.log(`_topic : ${_topic}`)
            console.log(`_scheme : ${_scheme}`)
            console.log(`_issuer : ${_issuer}`)
            console.log(`_data : ${_data}`)
            console.log(`_uri : ${_uri}`)

            signingData = metaIds[0] + signingData
            console.log(`signingData before hash : ${signingData}`)
            signingData = web3.sha3(signingData, { encoding: 'hex' })
            console.log(`signingData after hash : ${signingData}`)
            let _signature = web3.eth.sign(user1, signingData)
            console.log(`_signature : ${_signature}`)

            let addClaimData = await metaId.contract.addClaim.getData(_topic, _scheme, _issuer, _signature, _data, _uri)
            console.log(`addClaimData : ${addClaimData}`)
            let _nonce = 0
            let noncePacked = "000000000000000000000000000000000000000000000000000000000000000" + _nonce
            let valuePacked = "0000000000000000000000000000000000000000000000000000000000000000"
            let managementKeySigningData = "0x" + metaIds[0].slice(2) + valuePacked + addClaimData.slice(2) + noncePacked

            console.log(`managementKeySigningData : ${managementKeySigningData}`)
            
            //In solidity, abi.encodePacked(string) -> byte encodeing("ab" -> 0x6162)
            // managementKeySigningData += Buffer.from(_uri, 'utf8').toString('hex')
            managementKeySigningData = web3.sha3(managementKeySigningData, { encoding: 'hex' })

            console.log(`managementKeySigningData Sha3 Hashed : ${managementKeySigningData}`)

            let managementKeySignature = web3.eth.sign(user1, managementKeySigningData)

            console.log(`managementKeySignature : ${managementKeySignature}`)

            await metaId.delegatedExecute(metaIds[0], 0, addClaimData, _nonce, managementKeySignature, {from:user2})
            //delegatedExecute(address _to, uint256 _value, bytes _data, uint256 _nonce, bytes _sig)  

            let nClaims = await metaId.numClaims();
            assert.equal(nClaims, 1)
            

        });
/*
        it.only('test test create Meta ID and addClaim by DelegatedExcute', async function () {
            //uint256 _topic, uint256 _scheme, address issuer, bytes _signature, bytes _data, string _uri
            // mgt addr : 0x961c20596e7EC441723FBb168461f4B51371D8aA
            // mgt private key : 01b149603ca8f537bbb4e45d22e77df9054e50d826bb5f0a34e9ce460432b596
            // meta id addr : 0xe052cb04e4fe4d3ca69d247b4eff2aff35613b0e

            let _topic = 1 // MetaID_TOPIC
            let _scheme = 1// ECDSA_SCHEME
            let _issuer = user1
            let _data = "0x1b442640e0333cb03054940e3cda07da982d2b57af68c3df8d0557b47a77d0bc" // metaID
            let _uri = "MetaPrint"

            //abi.encodePacked(subject, topic, data) -> topic with uint256 packed 32bytes
            let topicPacked = "0000000000000000000000000000000000000000000000000000000000000001"
            let signingData = topicPacked+"1b442640e0333cb03054940e3cda07da982d2b57af68c3df8d0557b47a77d0bc"
            
            await this.identityManager.createMetaId(user1, { from: proxy1, gas: defaultGas })

            let metaIds = await this.identityManager.getDeployedMetaIds()
            let metaId = await MetaIdentity.at(metaIds[0])
            console.log(`user1 : ${JSON.stringify(user1)}`)
            console.log(`metaId[0] : 0xe052cb04e4fe4d3ca69d247b4eff2aff35613b0e}`)
            console.log(`_topic : ${_topic}`)
            console.log(`_scheme : ${_scheme}`)
            console.log(`_issuer : ${_issuer}`)
            console.log(`_data : ${_data}`)
            console.log(`_uri : ${_uri}`)


            signingData = '0xe052cb04e4fe4d3ca69d247b4eff2aff35613b0e' + signingData
            console.log(`signingData before hash : ${signingData}`)
            signingData = web3.sha3(signingData, { encoding: 'hex' })
            console.log(`signingData after hash : ${signingData}`)
            let _signature = web3.eth.sign('01b149603ca8f537bbb4e45d22e77df9054e50d826bb5f0a34e9ce460432b596', signingData)
            console.log(`_signature : ${_signature}`)

            let addClaimData = await metaId.contract.addClaim.getData(_topic, _scheme, _issuer, _signature, _data, _uri)
            console.log(`addClaimData : ${addClaimData}`)
            let _nonce = 0
            let noncePacked = "000000000000000000000000000000000000000000000000000000000000000" + _nonce
            let valuePacked = "0000000000000000000000000000000000000000000000000000000000000000"
            let managementKeySigningData = '0xe052cb04e4fe4d3ca69d247b4eff2aff35613b0e' + valuePacked + addClaimData.slice(2) + noncePacked

            console.log(`managementKeySigningData : ${managementKeySigningData}`)
            
            //In solidity, abi.encodePacked(string) -> byte encodeing("ab" -> 0x6162)
            // managementKeySigningData += Buffer.from(_uri, 'utf8').toString('hex')
            managementKeySigningData = web3.sha3(managementKeySigningData, { encoding: 'hex' })

            console.log(`managementKeySigningData Sha3 Hashed : ${managementKeySigningData}`)

            let managementKeySignature = web3.eth.sign('01b149603ca8f537bbb4e45d22e77df9054e50d826bb5f0a34e9ce460432b596', managementKeySigningData)

            console.log(`managementKeySignature : ${managementKeySignature}`)

            //await metaId.delegatedExecute(metaIds[0], 0, addClaimData, _nonce, managementKeySignature, {from:user2})
            //delegatedExecute(address _to, uint256 _value, bytes _data, uint256 _nonce, bytes _sig)  

            // let nClaims = await metaId.numClaims();
            // assert.equal(nClaims, 1)
            

        });
*/
    });

});
