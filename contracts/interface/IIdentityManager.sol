pragma solidity ^0.4.24;

contract IIdentityManager {
    function isMetaId(address _addr) public view returns(bool);
}