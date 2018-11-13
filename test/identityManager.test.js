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
    let identityManager, registry 
    const defaultGas = 8000000;

    beforeEach(async function () {
        identityManager = await IdentityManager.new();
        registry = await Registry.new();
        await identityManager.setRegistry(registry.address);
        await registry.setContractDomain("IdentityManager", identityManager.address );

        await registry.setPermission("IdentityManager", proxy1, "true");

    });

    describe('Create MetaID', function () {
        beforeEach(async function () {

        });

        it('basic Meta ID creation and add self claim(issuer == managementkey)', async function () {
            //uint256 _topic, uint256 _scheme, address issuer, bytes _signature, bytes _data, string _uri
            let _topic = 1 // MetaID_TOPIC
            let _scheme = 1 // ECDSA_SCHEME
            let _issuer = user1
            let _data = "0x1b442640e0333cb03054940e3cda07da982d2b57af68c3df8d0557b47a77d0bc" // metaID
            let _uri = "MetaPrint"

            //abi.encodePacked(subject, topic, data) -> topic with uint256 packed 32bytes
            let topicPacked = "0000000000000000000000000000000000000000000000000000000000000001"
            let signingData = topicPacked+"1b442640e0333cb03054940e3cda07da982d2b57af68c3df8d0557b47a77d0bc"

            await identityManager.createMetaId(user1, { from: proxy1 })

            let metaIds = await identityManager.getDeployedMetaIds()
            let metaId = await MetaIdentity.at(metaIds[0])
            
            signingData = metaIds[0] + signingData
            signingData = web3.sha3(signingData, { encoding: 'hex' })
            
            let _signature = web3.eth.sign(user1, signingData)
            
            await metaId.addClaim(_topic, _scheme, _issuer, _signature, _data, _uri, { from: user1 })

            let nClaims = await metaId.numClaims();
            assert.equal(nClaims, 1)

        });
    });

    describe('Basic functions', function () {
        beforeEach(async function () {
            await identityManager.createMetaId(user1, { from: proxy1})
        });

        it('Add already existing Meta Id', async () => {
            await identityManager.addMetaId(user2, proxy2, { from: proxy1})

            let s = await identityManager.isMetaId(user2)
            assert.equal(s, true)
        })

        it('Check Meta Id exists', async () => {
            let metaIds = await identityManager.getDeployedMetaIds()

            let s = await identityManager.isMetaId(metaIds[0])
            assert.equal(s, true)
        })
    })

});
