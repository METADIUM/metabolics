#!/bin/sh

rm -rf tmp
mkdir -p tmp

alias flatten="solidity_flattener --solc-paths=\"../=/Users/coinplug/BangGijin/metabolics2.0/contracts/\""

flatten contracts/IdentityManager.sol --output tmp/IdentityManager.sol
flatten contracts/identity/MetaIdentity.sol --output tmp/MetaIdentity.sol
flatten contracts/property/AchievementManager.sol --output tmp/AchievementManager.sol
flatten contracts/registry/AttestationAgencyRegistry.sol --output tmp/AttestationAgencyRegistry.sol
flatten contracts/registry/TopicRegistry.sol --output tmp/TopicRegistry.sol
flatten contracts/identity/MetaIdentityLib.sol --output tmp/MetaIdentityLib.sol