pragma solidity ^0.4.24;

import "./openzeppelin-solidity/contracts/ownership/Ownable.sol";
import "./Registry.sol";

contract RegistryUser is Ownable {
    
    Registry public REG;
    bytes32 public THIS_NAME;
    
    function setRegistry(address _addr) public onlyOwner {
        REG = Registry(_addr);
    }
    
    modifier permissioned() {
        require(REG.getPermission(THIS_NAME, msg.sender));
        _;
    }
}