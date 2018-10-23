pragma solidity ^0.4.24;

/**
 * @title IIdentityManager
 * @dev Interface for IdentityManager
 */
contract IIdentityManager {
    function isMetaId(address _addr) public view returns(bool);
}