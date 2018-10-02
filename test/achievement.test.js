import assertRevert from './helpers/assertRevert';
import EVMRevert from './helpers/EVMRevert';

const BigNumber = web3.BigNumber;

require('chai').use(require('chai-as-promised')).use(require('chai-bignumber')(BigNumber)).should();


const IdentityManager = artifacts.require('IdentityManager.sol')
const Registry = artifacts.require('Registry.sol')
const MetaIdentity = artifacts.require('MetaIdentity.sol');


contract('Metadium Identity Manager', function ([deployer, owner, proxy1, proxy2, user1, user2]) {

    beforeEach(async () => {

    });

    describe('Create MetaID', function () {
        beforeEach(async () => {

        });

        it('any user can make achievement', async () => {


        });

        it('user who has enough claims can get achievement', async () => {

        });

        it('user who has enough claims can get achievement', async () => {

        });

    });

});

// aa create achievement -> register to topic, register to aa
// ask achievement -> mint achievement erc721
// update achievement
// delete achievement

// deploy registry
// deploy identity manager
// deploy identity using identity manager
// add self claim