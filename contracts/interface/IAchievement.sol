pragma solidity ^0.4.24;

contract IAchievement {
    function mint(address _to, uint256 _tokenId, string _uri) public returns (bool);
    function burn(uint256 _tokenId) public returns (bool);
    
}