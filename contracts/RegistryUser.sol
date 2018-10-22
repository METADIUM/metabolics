pragma solidity ^0.4.24;

import "./openzeppelin-solidity/contracts/ownership/Ownable.sol";
import "./Registry.sol";

contract RegistryUser is Ownable {
    
    Registry public REG;
    bytes32 public THIS_NAME;
    event Per(address addr, bytes32 name, bool go);
    function setRegistry(address _addr) public onlyOwner {
        REG = Registry(_addr);
    }
    
    modifier permissioned() {
        require(isPermitted(msg.sender));
        _;
    }
    function isPermitted(address _addr) public returns(bool) {
        return REG.getPermission(THIS_NAME, _addr);
    }
}