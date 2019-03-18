import { getAndClearGas, measureTx, contractAddress, assertBlockGasLimit } from '../util';

const Identity = artifacts.require('Identity');

// Constants
export const Purpose = {
  MANAGEMENT: 1,
  ACTION: 2,
  CLAIM: 3,
  ENCRYPT: 4,
  ASSIST: 5,
  DELEGATE: 6,
  RESTORE: 7,
  CUSTOM: 8,
};

export const KeyType = {
  ECDSA: 1,
};

export const Topic = {
  BIOMETRIC: 1,
  RESIDENCE: 2,
  REGISTRY: 3,
  PROFILE: 4,
  LABEL: 5,
};

export const Scheme = {
  ECDSA: 1,
  RSA: 2,
  CONTRACT: 3,
};

export const assertKeyCount = async (identity, purpose, count) => {
  const keys = await identity.getKeysByPurpose(purpose);
  assert.equal(keys.length, count);
};

// Setup test environment
export const setupTest = async (accounts, init, total, claims = [], managementThreshold = 1, actionThreshold = 1, blockGasLimit = 10000000) => {
  const totalSum = total.reduce((a, b) => a + b);
  const initSum = init.reduce((a, b) => a + b);
  let addr = {}, keys = {};

  // Check we have enough accounts
  assert(initSum <= totalSum && totalSum + 1 <= accounts.length, 'Not enough accounts');

  // Check block gas limit is appropriate
  assertBlockGasLimit(blockGasLimit);

  // Use deployed identity for other identity
  // TODO deploy other identity here
  // let otherIdentity = await Identity.deployed();
  const otherIdentity = await Identity.new([], [], 1, 1, [], [], '', '', '', []);
  addr.other = accounts[0];
  keys.other = await otherIdentity.addrToKey(accounts[0]);

  // Slice accounts (0 is used above) and generate keys using keccak256
  const accountTuples = [];
  for (const addr of accounts.slice(1)) {
    const key = await otherIdentity.addrToKey(addr);
    accountTuples.push([addr, key]);
  }
  // Sort by keys (useful for identity constructor)
  accountTuples.sort((a, b) => a[1].localeCompare(b[1]));
  // ßconsole.log(`account Tuples : ${accountTuples}`)
  // Put keys in maps
  // ({ identity, addr, keys } = await setupTest(accounts, [3, 3, 0, 0], [4, 4, 1, 0]));
  const idxToPurpose = ['manager', 'action', 'claim', 'encrypt'];
  // 0 0~3
  // 1 4~7
  // 2 8
  // 3 9
  for (let i = 0, j = 0; i < total.length; i++) {
    // Slice total[i] accounts
    const slice = accountTuples.slice(j, j + total[i]);
    j += total[i];
    const purpose = idxToPurpose[i];
    addr[purpose] = slice.map(a => a[0]);
    keys[purpose] = slice.map(a => a[1]);
  }

  // Init keys to be sent in constructor
  let initKeys = [], initPurposes = [];
  for (let i = 0; i < init.length; i++) {
    const purpose = idxToPurpose[i];
    const k = keys[purpose].slice(0, init[i]);
    const p = Array(init[i]).fill(i + 1); // Use numeric value for purpose
    initKeys = initKeys.concat(k);
    initPurposes = initPurposes.concat(p);
  }

  // Init self-claims to be sent in constructor
  const willDeployAt = contractAddress(addr.manager[0]);
  const signatures = [];
  if (claims.length > 0) {
    // Must have at least one claim address if making claim
    assert(addr.claim.length > 0);
    // First, sort claims by issuer, topic
    claims.sort((c1, c2) => {
      if (c1.self == c2.self) return c1.type - c2.type;
      const a1 = c1.self ? willDeployAt : otherIdentity.address;
      const a2 = c2.self ? willDeployAt : otherIdentity.address;
      return a1.localeCompare(a2);
    });
    for (const { type, data, self } of claims) {
      // Claim hash
      const toSign = await otherIdentity.claimToSign(willDeployAt, type, data);
      // Sign using CLAIM_SIGNER_KEY
      const claimSigner = self ? addr.claim[0] : addr.other;
      const signature = web3.eth.sign(claimSigner, toSign);
      signatures.push(signature);
    }
  }

  // N bytes are encoded as a 2N+2 hex string (0x prefix, plus 2 characters per byte)
  let sizes = claims.map((c, i) => [(signatures[i].length - 2) / 2, c.data.length, c.uri.length]);
  sizes = [].concat(...sizes);

  // Deploy identity
  const identity = await Identity.new(
    // Keys
    initKeys,
    initPurposes,
    // Thresholds
    managementThreshold,
    actionThreshold,
    // Claims
    claims.map(c => c.self ? willDeployAt : otherIdentity.address),
    claims.map(c => c.type),
    // strip 0x prefix from each signature
    '0x' + signatures.map(s => s.slice(2)).join(''),
    claims.map(c => c.data).join(''),
    claims.map(c => c.uri).join(''),
    sizes,
    // Use max gas for deploys
    { from: addr.manager[0], gas: blockGasLimit }
  );
    // Make sure it matches address used for signatures
  assert.equal(identity.address, willDeployAt);
  // Measure gas usage
  await measureTx(identity.transactionHash);

  // Check init keys
  const contractKeys = await identity.numKeys();
  contractKeys.should.be.bignumber.equal(initSum);
  // Check init claims
  const contractClaims = await identity.numClaims();
  contractClaims.should.be.bignumber.equal(claims.length);

  getAndClearGas();

  return {
    identity,
    addr,
    keys,
    otherIdentity,
  };
};
