require('chai')
  .use(require('chai-bignumber')(web3.BigNumber))
  .should();

// Track gas
let gasUsed = 0;
let totalGas = 0;

const RLP = require('rlp');

export const contractAddress = (deployedBy) => {
  // https://ethereum.stackexchange.com/questions/2527/is-there-a-way-to-find-an-accounts-current-transaction-nonce
  const nonce = web3.eth.getTransactionCount(deployedBy);
  // https://stackoverflow.com/questions/18879880/how-to-display-nodejs-raw-buffer-data-as-hex-string
  const rlp = RLP.encode([deployedBy, nonce]).toString('hex');
  // https://ethereum.stackexchange.com/questions/760/how-is-the-address-of-an-ethereum-contract-computed
  const hash = web3.sha3(rlp, { encoding: 'hex' });
  const address = '0x' + hash.slice(26);
  return address;
};

export const getAndClearGas = () => {
  const t = gasUsed;
  gasUsed = 0;
  return t;
};

export const printTestGas = () => {
  totalGas += gasUsed;
  console.log(`\tTest only: ${getAndClearGas().toLocaleString()} gas`.grey);
};

// Measure gas
export const measureTx = async (txHash) => {
  const receipt = await web3.eth.getTransactionReceipt(txHash);
  gasUsed += receipt.gasUsed;
};

export const assertOkTx = async promise => {
  const r = await promise;
  gasUsed += r.receipt.gasUsed;
  assert.isOk(r);
  return r;
};

export const assertBlockGasLimit = (atLeast) => {
  const block = web3.eth.getBlock('latest');
  const limit = block.gasLimit;
  assert.isAtLeast(limit, atLeast);
};
