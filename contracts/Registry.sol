pragma solidity ^0.4.24;

import "./openzeppelin-solidity/contracts/ownership/Ownable.sol";

/**
 * @title Registry
 * @dev Registry Contract used to set domain and permission
 * The contracts used by the permissioned user in ShowMe references permission in this contract.
 * Not only contract address but also general address can be set in this contract.
 * Owner should set domain and permission.
 */
contract Registry is Ownable{
    
    mapping(bytes32=>address) public contracts;
    mapping(bytes32=>mapping(address=>bool)) public permissions;

    /**
    * @dev Function to set contract(can be general address) domain
    * Only owner can use this function
    * @param _name name
    * @param _addr address
    * @return A boolean that indicates if the operation was successful.
    */
    function setContractDomain(bytes32 _name, address _addr) onlyOwner public {
        require(_addr != address(0x0));
        contracts[_name] = _addr;
        //TODO should decide whether to set 0x00 to destoryed contract or not
        

    }
    /**
    * @dev Function to get contract(can be general address) address
    * Anyone can use this function
    * @param _name _name
    * @return An address of the _name
    */
    function getContractAddress(bytes32 _name) public constant returns(address) {
        require(contracts[_name] != address(0x0));
        return contracts[_name];
    }
    /**
    * @dev Function to set permission on contract
    * contract using modifier 'permissioned' references mapping variable 'permissions'
    * Only owner can use this function
    * @param _contract contract name
    * @param _granted granted address
    * @param _status true = can use, false = cannot use. default is false
    * @return A boolean that indicates if the operation was successful.
    */
    function setPermission(bytes32 _contract, address _granted, bool _status) onlyOwner public returns(bool) {
        require(_granted != address(0x0));
        permissions[_contract][_granted] = _status;
        return true;
    }

    /**
    * @dev Function to get permission on contract
    * contract using modifier 'permissioned' references mapping variable 'permissions'
    * @param _contract contract name
    * @param _granted granted address
    * @return permission result
    */
    function getPermission(bytes32 _contract, address _granted) public constant returns(bool) {
        return permissions[_contract][_granted];
    }
    //TODO
    
}