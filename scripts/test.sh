#!/usr/bin/env bash

# Exit script as soon as a command fails.
set -o errexit

# Executes cleanup function at script exit.
trap cleanup EXIT

cleanup() {
  # Kill the ganache instance that we started (if we started one and if it's still running).
  if [ -n "$ganache_pid" ] && ps -p $ganache_pid > /dev/null; then
    kill -9 $ganache_pid
  fi
}

if [ "$SOLIDITY_COVERAGE" = true ]; then
  ganache_port=8555
else
  ganache_port=8545
fi

ganache_running() {
  nc -z localhost "$ganache_port"
}

start_ganache() {
  # We define 10 accounts with balance 1000M ether.
  local accounts=(
    --account="0x4d6574616469756d476f7665726e616e6365536d617274436f6e747261637400,1000000000000000000000000000"
    --account="0x4d6574616469756d476f7665726e616e6365536d617274436f6e747261637401,1000000000000000000000000000"
    --account="0x4D6574616469756D476F7665726E616E6365536D617274436F6E747261637402,1000000000000000000000000000"
    --account="0x4D6574616469756D476F7665726E616E6365536D617274436F6E747261637403,1000000000000000000000000000"
    --account="0x4D6574616469756D476F7665726E616E6365536D617274436F6E747261637404,1000000000000000000000000000"
    --account="0x4D6574616469756D476F7665726E616E6365536D617274436F6E747261637405,1000000000000000000000000000"
    --account="0x4D6574616469756D476F7665726E616E6365536D617274436F6E747261637406,1000000000000000000000000000"
    --account="0x4D6574616469756D476F7665726E616E6365536D617274436F6E747261637407,1000000000000000000000000000"
    --account="0x4D6574616469756D476F7665726E616E6365536D617274436F6E747261637408,1000000000000000000000000000"
    --account="0x4D6574616469756D476F7665726E616E6365536D617274436F6E747261637409,1000000000000000000000000000"
  )

  if [ "$SOLIDITY_COVERAGE" = true ]; then
    node_modules/.bin/testrpc-sc --gasLimit 0xffffffffffff --port "$ganache_port" "${accounts[@]}" > /dev/null &
  else
    node_modules/.bin/testrpc-sc --gasLimit 0xffffffffffff --port "$ganache_port" "${accounts[@]}" > /dev/null &
    # node_modules/.bin/ganache-cli --gasLimit=7984452 --gasPrice=2000000000 "${accounts[@]}" > /dev/null &
  fi

  ganache_pid=$!
}

if ganache_running; then
  echo "Using existing ganache instance"
else
  echo "Starting our own ganache instance"
  start_ganache
fi

if [ "$SOLC_NIGHTLY" = true ]; then
  echo "Downloading solc nightly"
  wget -q https://raw.githubusercontent.com/ethereum/solc-bin/gh-pages/bin/soljson-nightly.js -O /tmp/soljson.js && find . -name soljson.js -exec cp /tmp/soljson.js {} \;
fi

truffle version

if [ "$SOLIDITY_COVERAGE" = true ]; then
  node_modules/.bin/solidity-coverage

  if [ "$CONTINUOUS_INTEGRATION" = true ]; then
    cat coverage/lcov.info | node_modules/.bin/coveralls
  fi
else
  truffle test "$@"
fi