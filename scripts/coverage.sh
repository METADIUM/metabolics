#!/usr/bin/env bash
#./node_modules/.bin/solidity-coverage
touch allFiredEvents
SOLIDITY_COVERAGE=true scripts/test.sh
