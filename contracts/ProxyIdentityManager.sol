pragma solidity ^0.4.24;

import "./openzeppelin-solidity/contracts/ownership/Ownable.sol";
import "./identity/MetaIdentityUsingLib.sol";
import "./RegistryUser.sol";


/**
 * @title ProxyIdentityManager
 * @dev ProxyIdentityManager is factory contract to make identity
 * permissoined sender can create metadium identity through this contract
 */
contract ProxyIdentityManager is RegistryUser {
    //Hold the list of MetaIds
    //CreateMetaId
    
    address[] public metaIds;
    mapping(address=>bool) metaIdExistence;

    event CreateMetaId(address indexed managementKey, address metaId);
    
    constructor() public {
        THIS_NAME = "IdentityManager";
    }


    /**
     * @dev Create Metadium Identity which is based upon erc725-735 
     * @param _managementKey basic managementKey to use
     * @return A boolean that indicates if the operation was successful.
     */
    function createMetaId(address _managementKey) permissioned public returns (bool success) {
        require(_managementKey != address(0));

        address newMetaId = new MetaIdentityUsingLib();
        metaIds.push(newMetaId);
        metaIdExistence[newMetaId] = true;

        emit CreateMetaId(_managementKey, newMetaId);

        return true;

    }

    function getDeployedMetaIds() public view returns(address[] addrs) {
        return metaIds;
    }

    function isMetaId(address _addr) public view returns(bool found) {
        return metaIdExistence[_addr];
    }

    function getLengthOfMetaIds() public view returns(uint256 length) {
        return metaIds.length;
    }

}