pragma solidity ^0.4.24;


/**
 * @title IAttestationAgencyRegistry
 * @dev Interface for AttestationAgencyRegistry
 */
contract IAttestationAgencyRegistry {
    function isRegistered(address _addr) public view returns (uint256);
}