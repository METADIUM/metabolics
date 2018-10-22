pragma solidity ^0.4.24;

contract IAttestationAgencyRegistry {
    function isRegistered(address _addr) view public returns(uint256);

}