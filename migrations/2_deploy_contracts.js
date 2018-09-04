const IdentityManager = artifacts.require('IdentityManager.sol')
const Registry = artifacts.require('Registry.sol')

async function deploy(deployer) {
    const args = process.argv.slice()
    _gas = 6000000
    _gasPrice = 1000
    if (args[3] == 'all') {
        //proxy create metaID instead user for now. Because users do not have enough fee.
        var proxy1 = '0x084f8293F1b047D3A217025B24cd7b5aCe8fC657'; //node3 account[1]
        return deployer.deploy(Registry, { gas: _gas, gasPrice: _gasPrice }).then((reg) => {
            return deployer.deploy(IdentityManager, { gas: _gas, gasPrice: _gasPrice }).then(async function initialSetup(mim) {

                //reg: name, permission setup
                await reg.setContractDomain("IdentityManager", mim.address, { gas: _gas, gasPrice: _gasPrice })
                await reg.setPermission("IdentityManager", proxy1, "true", { gas: _gas, gasPrice: _gasPrice })

                await mim.setRegistry(reg.address, { gas: _gas, gasPrice: _gasPrice })

            })
        })
    }

}

module.exports = deploy
