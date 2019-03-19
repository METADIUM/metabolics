![meta logo](./miscs/Metadium_Logo_Vertical_PNG.png)
# Metabolics - Metadium System Smart Contracts
[![Generic badge](https://img.shields.io/badge/build-passing-green.svg)](https://shields.io/)
[![Generic badge](https://img.shields.io/badge/licence-MIT-blue.svg)](https://shields.io/)

Metadium 2.0 Smart Contract.

## Deployed Contracts

Registry : [0x29712f5fe784356f75955a884229080690887f11](https://testnetexplorer.metadium.com/addresses/0x29712f5fe784356f75955a884229080690887f11)

Identity Manager : [0xbb1d771b79de3d2c6e62c03f8ddc4ed7807c1334](https://testnetexplorer.metadium.com/addresses/0xbb1d771b79de3d2c6e62c03f8ddc4ed7807c1334)

Achievement Manager : [0x95ba0154ed7b037a4770b1bf12b9ac9f8ba268ff](https://testnetexplorer.metadium.com/addresses/0x95ba0154ed7b037a4770b1bf12b9ac9f8ba268ff)

## Test

```
$ npm install
$ npm install -g ganache-cli
$ ganache-cli -l 10000000
$ truffle test
```

## Flatten
Install [solidity-flattener](https://github.com/BlockCatIO/solidity-flattener)
```
$ npm run flatten
```

## Compile
```
$ truffle compile
```

## Misc
* Important : When you use MetaIdentityLib, **YOU MUST INIT YOUR MetaIdentityLib FIRST**!

## Reference
* [Original Work : ERC725-735 by mirceapasoi](https://github.com/mirceapasoi/erc725-735)
* [Origin Protocal](https://github.com/OriginProtocol)