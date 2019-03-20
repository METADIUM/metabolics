import { setupTest, Purpose, KeyType } from './base';
import { assertOkTx, printTestGas } from '../util';

const TestContract = artifacts.require('TestContract');

contract('KeyGetters', async (accounts) => {
  let identity, addr, keys;

  afterEach('print gas', printTestGas);

  beforeEach('new contract', async () => {
    ({ identity, addr, keys } = await setupTest(accounts, [2, 2, 0, 0], [3, 3, 1, 1]));
  });

  // Getters
  describe('keyHasPurpose', async () => {
    it('should return keys that exist', async () => {
      assert.isTrue(await identity.keyHasPurpose(keys.manager[1], Purpose.MANAGEMENT));
      assert.isTrue(await identity.keyHasPurpose(keys.action[0], Purpose.ACTION));
    });

    it('should not return keys that don\'t exist', async () => {
      assert.isFalse(await identity.keyHasPurpose(keys.manager[0], Purpose.ACTION));
      assert.isFalse(await identity.keyHasPurpose(keys.action[1], Purpose.MANAGEMENT));
    });
  });

  describe('getKey', async () => {
    it('should return key data', async () => {
      const [purposes, keyType, key] = await identity.getKey(keys.manager[0]);
      keyType.should.be.bignumber.equal(KeyType.ECDSA);
      key.should.be.bignumber.equal(keys.manager[0]);
      assert.equal(purposes.length, 1);
      purposes[0].should.be.bignumber.equal(Purpose.MANAGEMENT);
    });

    it('should return multiple purposes', async () => {
      await assertOkTx(identity.addKey(keys.action[0], Purpose.MANAGEMENT, KeyType.ECDSA, { from: addr.manager[0] }));
      const [purposes, keyType, key] = await identity.getKey(keys.action[0]);
      keyType.should.be.bignumber.equal(KeyType.ECDSA);
      key.should.be.bignumber.equal(keys.action[0]);
      assert.equal(purposes.length, 2);
      purposes[0].should.be.bignumber.equal(Purpose.ACTION);
      purposes[1].should.be.bignumber.equal(Purpose.MANAGEMENT);
    });

    it('should not return keys without purpose', async () => {
      const [purposes, keyType, key] = await identity.getKey(keys.claim[0]);
      keyType.should.be.bignumber.equal(0);
      key.should.be.bignumber.equal(0);
      assert.equal(purposes.length, 0);
    });
  });

  describe('getKeysByPurpose', async () => {
    it('should return all management keys', async () => {
      const k = await identity.getKeysByPurpose(Purpose.MANAGEMENT);
      assert.equal(k.length, 2);
      assert.equal(keys.manager[0], k[0]);
      assert.equal(keys.manager[1], k[1]);
    });

    it('should return all action keys', async () => {
      const k = await identity.getKeysByPurpose(Purpose.ACTION);
      assert.equal(k.length, 2);
      assert.equal(keys.action[0], k[0]);
      assert.equal(keys.action[1], k[1]);
    });

    it('should not return keys that haven\'t been added', async () => {
      const k = await identity.getKeysByPurpose(Purpose.CLAIM);
      assert.equal(k.length, 0);
    });
  });

  describe('keyCanExcute', async () => {
    it('should return false when function is not registerd for the key', async () => {
      const k = await identity.keyCanExecute(keys.action[0], addr.manager[0], '0xabcd1234');
      assert.equal(k, false);
    });

    it('should return true when function is registered for the key', async () => {
      const testContract = await TestContract.deployed();
      await assertOkTx(identity.setFunc(keys.action[0], testContract.address, '0xabcd1234', 'true', { from: addr.manager[0] }));
      const k = await identity.keyCanExecute(keys.action[0], testContract.address, '0xabcd1234');
      assert.equal(k, true);
    });
  });
});
