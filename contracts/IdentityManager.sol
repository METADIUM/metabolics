pragma solidity ^0.4.24;

import "./openzeppelin-solidity/contracts/ownership/Ownable.sol";
import "./identity/MetaIdentity.sol";
import "./RegistryUser.sol";

contract IdentityManager is RegistryUser {
    //Hold the list of MetaIds
    //CreateMetaId
    // event
    address[] public metaIds;
    mapping(address=>bool) metaIdExistence;

    function IdentityManager() public {
        THIS_NAME = "IdentityManager";
    }
    function createMetaId(address _managementKey) permissioned public returns (bool) {
        address newMetaId = new MetaIdentity(_managementKey);
        metaIds.push(newMetaId);
        metaIdExistence[newMetaId] = true;
        //give reward to newMetaId

        //give first achievement to new MetaId

    }

    function getDeployedMetaIds() public view returns(address[]) {
        return metaIds;
    }
    function isMetaId(address _addr) public view returns(bool) {
        return metaIdExistence[_addr];
    }
    function getLengthOfMetaIds() public view returns(uint256) {
        return metaIds.length;
    }
}