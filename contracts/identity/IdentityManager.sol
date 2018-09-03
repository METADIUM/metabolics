pragma solidity ^0.4.24;

import "../openzeppelin-solidity/contracts/ownership/Ownable.sol";
import "./ClaimHolder.sol";
import "../Registry.sol";

contract IdentityManager is Ownable {
    //Hold the list of MetaIds
    //CreateMetaId
    //
    Registry public REG;
    address[] public metaIds;

    function createMetaId(address _managementKey) permissioned public returns (bool){

        address newMetaId = new ClaimHolder(_managementKey);
        metaIds.push(newMetaId);

        //give reward to newMetaId

        //give first achievement to new MetaId

    }

    function getDeployedMetaIds() public view returns(address[]){
        return metaIds;
    }

    function getLengthOfMetaIds() public view returns(uint256){
        return metaIds.length;
    }

    function setRegistry(address _addr) public onlyOwner {
        REG = Registry(_addr);
    }
    modifier permissioned() {
        require(REG.getPermission("IdentityManager", msg.sender));
        _;
    }
}