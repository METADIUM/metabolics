# Metadium Metadium Identity Manager Smart Contract
[![Generic badge](https://img.shields.io/badge/build-passing-green.svg)](https://shields.io/)    [![Generic badge](https://img.shields.io/badge/licence-MIT-blue.svg)](https://shields.io/)

This is Metadium 2.0 Smart Contract.

Metadium Smart Contracts consist of followings:
* Registry
* Identity(Claim Holder)
* Identity Manager


### Meta ID CRUD functions



### Identity Manager
------------------------------------------
```
function createMetaId(address _managementKey) permissioned public returns (bool)
function getDeployedMetaIds() public view returns(address[])
function getLengthOfMetaIds() public view returns(uint256)
```
Permissioned user can make MetaID through Identity Manager using **createMetaId**.


### MetaID
------------------------------------------
Each MetaID consists of following functions:

**ERC725**
```
function getKey(bytes32 _key) public constant returns(uint256 purpose, uint256 keyType, bytes32 key);
function getKeyPurpose(bytes32 _key) public constant returns(uint256 purpose);
function getKeysByPurpose(uint256 _purpose) public constant returns(bytes32[] keys);
function addKey(bytes32 _key, uint256 _purpose, uint256 _keyType) public returns (bool success);
function execute(address _to, uint256 _value, bytes _data) public returns (uint256 executionId);
function approve(uint256 _id, bool _approve) public returns (bool success);
function removeKey(bytes32 _key, uint256 _purpose) public returns (bool success);
```


**ERC735**
```
function getClaim(bytes32 _claimId) public constant returns(uint256 claimType, uint256 scheme, address issuer, bytes signature, bytes data, string uri);
function getClaimIdsByType(uint256 _claimType) public constant returns(bytes32[] claimIds);
function addClaim(uint256 _claimType, uint256 _scheme, address issuer, bytes _signature, bytes _data, string _uri) public returns (bytes32 claimRequestId);
function removeClaim(bytes32 _claimId) public returns (bool success);
function addClaimByProxy(uint256 _topic, uint256 _scheme, address issuer, bytes _signature, bytes _data, string _uri, bytes _idSignature) public returns (uint256 claimRequestId)
```


### Registry
------------------------------------------
```
/**
* @dev Function to set contract(can be general address) domain
* Only owner can use this function
* @param _name name
* @param _addr address
* @return A boolean that indicates if the operation was successful.
*/
function setContractDomain(bytes32 _name, address _addr) onlyOwner public
```
Only MetaGovernance can set domain now.


```
/**
* @dev Function to get contract(can be general address) address
* Anyone can use this function
* @param _name _name
* @return An address of the _name
*/
function getContractAddress(bytes32 _name) public constant returns(address)
```
You can get the specific address of contract you want to read.

## TODO
--------------------
1. Move assets to the key owner when destruct the meta identity