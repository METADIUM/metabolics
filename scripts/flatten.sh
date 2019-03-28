#!/bin/sh

rm -rf flat
mkdir -p flat

alias flatten="solidity_flattener --solc-paths=\"openzeppelin-solidity=/metadium/node_modules/openzeppelin-solidity ../=/metadium/contracts/\""

flatten contracts/IdentityManager.sol --output flat/IdentityManager.sol
flatten contracts/identity/MetaIdentity.sol --output flat/MetaIdentity.sol
flatten contracts/property/AchievementManager.sol --output flat/AchievementManager.sol
flatten contracts/registry/AttestationAgencyRegistry.sol --output flat/AttestationAgencyRegistry.sol
flatten contracts/registry/TopicRegistry.sol --output flat/TopicRegistry.sol
flatten contracts/identity/MetaIdentityLib.sol --output flat/MetaIdentityLib.sol