require('babel-register');
require('babel-polyfill');

module.exports = {
    norpc: true,
    copyNodeModules: false,
    skipFiles:['Migrations.sol']
};