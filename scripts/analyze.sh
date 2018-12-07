#!/bin/sh

rm -rf reports
mkdir -p reports

npm run flatten

echo "Analyzing contracts with Mythril..."

myth -x tmp/TopicRegistry.sol:TopicRegistry -o markdown >> reports/TopicRegistry_Mythril.md
myth -x tmp/MetaIdentity.sol:MetaIdentity -o markdown >> reports/MetaIdentity_Mythril.md
myth -x tmp/AchievementManager.sol:AchievementManager -o markdown >> reports/AchievementManager_Mythril.md
myth -x tmp/AttestationAgencyRegistry.sol:AttestationAgencyRegistry -o markdown >> reports/AttestationAgencyRegistry_Mythril.md
myth -x tmp/IdentityManager.sol:IdentityManager -o markdown >> reports/IdentityManager_Mythril.md
