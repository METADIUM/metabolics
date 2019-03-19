const { reverting } = require('openzeppelin-solidity/test/helpers/shouldFail');

require('chai')
  .use(require('chai-bignumber')(web3.BigNumber))
  .should();

const Registry = artifacts.require('Registry.sol');
const AttestationAgencyRegistry = artifacts.require('AttestationAgencyRegistry.sol');

contract('Registry', function ([deployer, identity1, aa1, aa2, user2, issuer1, issuer2, issuer3, proxy1]) {
  let registry, aaRegistry;

  beforeEach(async () => {
    registry = await Registry.new();
    aaRegistry = await AttestationAgencyRegistry.new();
  });

  describe('Owner ', function () {
    it('can set Contract Domain', async () => {
      await registry.setContractDomain('AttestationAgencyRegistry', aaRegistry.address);
      const domain = await registry.getContractAddress('AttestationAgencyRegistry');
      assert.equal(domain, aaRegistry.address);
    });

    it('can set permission', async () => {
      await registry.setPermission('AttestationAgencyRegistry', proxy1, 'true');
      const per = await registry.getPermission('AttestationAgencyRegistry', proxy1);
      assert.equal(per, true);
    });
  });

  describe('Other users ', function () {
    it('cannot set Contract Domain', async () => {
      await reverting(registry.setContractDomain('AttestationAgencyRegistry', aaRegistry.address, { from: aa1 }));
    });

    it('cannot set permission', async () => {
      await reverting(registry.setPermission('AttestationAgencyRegistry', proxy1, 'true', { from: aa1 }));
    });
  });

  describe('Registry User Contract', function () {
    beforeEach(async () => {
      await registry.setContractDomain('AttestationAgencyRegistry', aaRegistry.address);
      await registry.setPermission('AttestationAgencyRegistry', proxy1, 'true');
    });

    it('can set registry address', async () => {
      await aaRegistry.setRegistry(registry.address);
      const regAddress = await aaRegistry.REG();
      assert.equal(regAddress, registry.address);
    });

    it('can act as permission', async () => {
      await aaRegistry.setRegistry(registry.address);

      // register aa
      await aaRegistry.registerAttestationAgency(aa1, 'metadiumAA', 'metadiumAADes', { from: proxy1 });
      // update aa
      await aaRegistry.updateAttestationAgency(aa1, 'metadiumBB', 'metadiumBBDes', { from: proxy1 });
      const [addr, title, expl, createdAt] = await aaRegistry.getAttestationAgencySingle(1);

      assert.equal(title, '0x6d6574616469756d424200000000000000000000000000000000000000000000');
      assert.equal(expl, '0x6d6574616469756d424244657300000000000000000000000000000000000000');

      await reverting(aaRegistry.registerAttestationAgency(aa1, 'metadiumAA', 'metadiumAADes', { from: user2 }));
    });
  });
});
