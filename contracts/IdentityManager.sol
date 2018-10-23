pragma solidity ^0.4.24;

import "./openzeppelin-solidity/contracts/ownership/Ownable.sol";
import "./identity/MetaIdentity.sol";
import "./RegistryUser.sol";


/**
 * @title IdentityManager
 * @dev IdentityManager is factory contract to make identity
 * permissoined sender can create metadium identity through this contract
 */
contract IdentityManager is RegistryUser {
    //Hold the list of MetaIds
    //CreateMetaId
    
    address[] public metaIds;
    mapping(address=>bool) metaIdExistence;

    event CreateMetaId(address indexed managementKey, address metaId);
    
    function IdentityManager() public {
        THIS_NAME = "IdentityManager";
    }


    /**
     * @dev Create Metadium Identity which is based upon erc725-735 
     * @param _managementKey basic managementKey to use
     * @return A boolean that indicates if the operation was successful.
     */
    function createMetaId(address _managementKey) permissioned public returns (bool) {
        require(_managementKey != address(0));

        address newMetaId = new MetaIdentity(_managementKey);
        metaIds.push(newMetaId);
        metaIdExistence[newMetaId] = true;
        //give reward to newMetaId

        //give first achievement to new MetaId

        emit CreateMetaId(_managementKey, newMetaId);

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