pragma solidity ^0.4.24;

import "openzeppelin-solidity/contracts/ownership/Ownable.sol";
import "./identity/MetaIdentity.sol";
import "./RegistryUser.sol";


/**
 * @title IdentityManager
 * @dev IdentityManager is factory contract to make identity
 * permissoined sender can create metadium identity through this contract
 */
contract IdentityManager is RegistryUser {
    address[] public metaIds;
    mapping(address=>bool) internal metaIdExistence;

    event CreateMetaId(address indexed managementKey, address metaId);
    
    constructor() public {
        THIS_NAME = "IdentityManager";
    }

    /**
     * @dev Create Metadium Identity which is based upon erc725-735 
     * @param _managementKey basic managementKey to use
     * @return A boolean that indicates if the operation was successful.
     */
    function createMetaId(address _managementKey) public permissioned returns (bool success) {
        require(_managementKey != address(0), "address is 0x0");

        address newMetaId = new MetaIdentity(_managementKey);
        metaIds.push(newMetaId);
        metaIdExistence[newMetaId] = true;

        emit CreateMetaId(_managementKey, newMetaId);

        return true;
    }

    /**
     * @dev Add MetaId to the list. This function is for migration.
     * @param _metaId meta id address
     * @return A boolean that indicates if the operation was successful.
     */
    function addMetaId(address _metaId, address _managementKey) public permissioned returns (bool success) {
        metaIds.push(_metaId);
        metaIdExistence[_metaId] = true;

        emit CreateMetaId(_managementKey, _metaId);
        
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