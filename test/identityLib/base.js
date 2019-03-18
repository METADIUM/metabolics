import { getAndClearGas, assertBlockGasLimit } from '../util';

const Identity = artifacts.require('Identity');
const MetaIdentityLib = artifacts.require('MetaIdentityLib.sol');
const MetaIdentityUsingLib = artifacts.require('MetaIdentityUsingLib.sol');
const Registry = artifacts.require('Registry.sol');

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

  // deploy metaIdLib, metaIdUsingLib
  const metaIdLib = await MetaIdentityLib.new();
  const registry = await Registry.new();

  await registry.setContractDomain('MetaIdLibraryV1', metaIdLib.address);

  // Init self-claims to be sent in constructor
  let willDeployAt; // = contractAddress(addr.manager[0]);

  let metaId, metaIdUsingLib;
  // catch the first management key
  let firstMgmt;
  // if there is no initial key, should add msg.sender as mgmt, action, claim key at first.
  for (const [i, k] of initKeys.entries()) {
    if (initPurposes[i] == 1) {
      firstMgmt = i;
      metaId = await MetaIdentityUsingLib.new(registry.address, initKeys[i]);
      metaIdUsingLib = await MetaIdentityLib.at(metaId.address);
      willDeployAt = metaId.address;
      // metaId basically register first key as management, action and claim key
      // for the test remove key for action and claim
      await metaIdUsingLib.removeKey(initKeys[i], 2, { from: addr.manager[0] }); // action
      await metaIdUsingLib.removeKey(initKeys[i], 3, { from: addr.manager[0] }); // claim
      break;
    }
  }

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

  // register other keys
  for (const [i, k] of initKeys.entries()) {
    if (i != firstMgmt) {
      await metaIdUsingLib.addKey(initKeys[i], initPurposes[i], KeyType.ECDSA, { from: addr.manager[0] });
    }
  }

  for (const [i, c] of claims.entries()) {
    const claimSigner = c.self ? addr.claim[0] : addr.other;
    const issuer = c.self ? willDeployAt : otherIdentity.address;
    await metaIdUsingLib.addClaim(c.type, Scheme.ECDSA, issuer, signatures[i], c.data, c.uri, { from: addr.manager[0] });
  }

  const identity = metaIdUsingLib;
  // // Check init keys
  const contractKeys = await identity.numKeys();
  contractKeys.should.be.bignumber.equal(initSum);

  // Check init claims
  // let contractClaims = await identity.numClaims();
  const contractClaims = await identity.numClaims();
  const nonce = await identity.nonce();
  // console.log(`num Claims : ${contractClaims}`)
  // console.log(`nonce : ${nonce}`)
  contractClaims.should.be.bignumber.equal(claims.length);

  getAndClearGas();

  return {
    identity,
    addr,
    keys,
    otherIdentity,
  };
};
