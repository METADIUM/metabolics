pragma solidity ^0.4.24;

import "./openzeppelin-solidity/contracts/ownership/Ownable.sol";
import "./Registry.sol";

/**
 * @title RegistryUser
 * @dev RegistryUser Contract that uses Registry contract
 */
contract RegistryUser is Ownable {
    
    Registry public REG;
    bytes32 public THIS_NAME;
    event Per(address addr, bytes32 name, bool go);

    /**
     * @dev Function to set registry address. Contract that wants to use registry should setRegistry first.
     * @param _addr address of registry
     * @return A boolean that indicates if the operation was successful.
     */
    function setRegistry(address _addr) public onlyOwner {
        REG = Registry(_addr);
    }
    
    modifier permissioned() {
        require(isPermitted(msg.sender));
        _;
    }

    /**
     * @dev Function to check the permission
     * @param _addr address of sender to check the permission
     * @return A boolean that indicates if the operation was successful.
     */
    function isPermitted(address _addr) public returns(bool found) {
        return REG.getPermission(THIS_NAME, _addr);
    }
}