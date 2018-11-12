# Metadium Metadium Identity Manager Smart Contract
[![Generic badge](https://img.shields.io/badge/build-passing-green.svg)](https://shields.io/)    [![Generic badge](https://img.shields.io/badge/licence-MIT-blue.svg)](https://shields.io/)

This is Metadium 2.0 Smart Contract.

Metadium Smart Contracts consist of followings

**Registry**
* Registry(System Registry)
* Attestation Agency Registry
* Topic Registry
 
**Identity**  
* Identity Manager
* Identity(Library Contract used to delegatecall)
* UpgradableProxyIdentity

**Achievement**
* Achievement Manager
* Achievement(ERC721)


## Deployed Contracts

## Setup

## Testing

## Misc



### Meta ID CRUD functions

### Identity Manager
------------------------------------------
```
function createMetaId(address _managementKey) permissioned public returns (bool)
function getDeployedMetaIds() public view returns(address[])
function getLengthOfMetaIds() public view returns(uint256)
function isMetaId(address _addr) public view returns(bool found)
```
Permissioned user can make MetaID through Identity Manager using **createMetaId**.


### MetaID
------------------------------------------
Each MetaID consists of following functions:

**ERC725**
```
Public
function getKey(bytes32 _key) public constant returns(uint256 purpose, uint256 keyType, bytes32 key);
function getKeysByPurpose(uint256 _purpose) public constant returns(bytes32[] keys);
function addKey(bytes32 _key, uint256 _purpose, uint256 _keyType) public returns (bool success);
function execute(address _to, uint256 _value, bytes _data) public returns (uint256 executionId);
function approve(uint256 _id, bool _approve) public returns (bool success);
function removeKey(bytes32 _key, uint256 _purpose) public returns (bool success);
```


**ERC735**
```
Public
function getClaim(bytes32 _claimId) public constant returns(uint256 claimType, uint256 scheme, address issuer, bytes signature, bytes data, string uri);
function getClaimIdsByType(uint256 _claimType) public constant returns(bytes32[] claimIds);
function addClaim(uint256 _claimType, uint256 _scheme, address issuer, bytes _signature, bytes _data, string _uri) public returns (bytes32 claimRequestId);
function removeClaim(bytes32 _claimId) public returns (bool success);
function addClaimByProxy(uint256 _topic, uint256 _scheme, address issuer, bytes _signature, bytes _data, string _uri, bytes _idSignature) public returns (uint256 claimRequestId);
function getClaimLength() public view returns (uint256 length);
function getAllClaims(uint256 start, uint256 end) public view returns (uint256[] topics);
```
**general**

Public
```
function delegatedExecute(address _to, uint256 _value, bytes _data, uint256 nonce, bytes signature) public returns (bool)
```
user submit user tx to proxy identity with his/her signature. If _to have type of delegateKey storing proxy identity, execute.


```
function changeImplementation(address newIm) managementOrSelf public returns (bool);
```

### System Registry
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

### Topic Registry
```
function registerTopic(bytes32 _title, bytes32 _explanation) public returns (uint256 topicId)
```
Register topic. Only AA can register or permissioned user can register topic(1025~).

```
function registerTopicBySystem(uint256 _id, bytes32 _title, bytes32 _explanation) permissioned public returns (uint256 topicId)
```
Only system admin can register the topic(0~1024)
```
function updateTopic(uint256 _id, bytes32 _explanation) public returns (bool success)
```
Update topic's explanation
```
function getTotal() view public returns (uint256 length)
```
Get total topic length
```
function getTopic(uint256 _id) view public returns(address issuer, bytes32 title, bytes32 explanation, uint256 createdAt)
```
Get topic by id
```
function getTopicFromTo(uint256 _from, uint256 _to) view public returns(address[] addrs, bytes32[] titles, bytes32[] explans, uint256[] createds)
```
Batch read for topic

### Attestation Agency Registry
```
function registerAttestationAgency(address _addr, bytes32 _title, bytes32 _explanation) permissioned public returns (bool success)
```
Register Attestation Agency, only permissioned user can register AA.
```
function updateAttestationAgency(uint256 _num, address _addr, bytes32 _title, bytes32 _explanation) permissioned public returns (bool success)
```
Update AA info.
```
function getAttestationAgencySingle(uint256 _num) view public returns(address addr, bytes32 title, bytes32 explanation, uint256 createdAt)
```
Get a single Attestation Agency Info
```
function getAttestationAgenciesFromTo(uint256 _from, uint256 _to) view public returns(address[] addrs, bytes32[] titles, bytes32[] descs, uint256[] createds)
```
Batch read for AA info 

### Achievement
**Achievement Manager**
Public
```
function createAchievement(uint256[] _topics, address[] _issuers, bytes32 _achievementExplanation, uint256 _reward, string _uri) onlyAttestationAgency public payable returns (bool);
```
Create Achievement. Topics are registered before to the topic registry with descriptions. The creator should send enough balance for rewards.
```
function updateAchievement(bytes32 _achievementId, uint256 _reward) public payable returns (bool);
```
Update Achievement can charge fund, and can change reward
```
function deleteAchievement(bytes32 achievementId) public returns(bool);
```
Delete Achievement and refund balance.
```
function requestAchievement(bytes32 achievementId) public returns(bool);
```
User can request achievement if he or she has enough claims for achievement. Then the achievement ERC1155(ERC721) is minted and the user get the reward from the contract(staked by achievement issuer).

When you mint ERC721 token, ERC721 tokenId = uint256(keccak256(abi.encodePacked(msg.sender, _achievementId)))

```
function getAllAchievementList() pure public returns(bytes32[])
```
Returns current all achievement list(doesn't matter staked reward is enough or not)

```
function getActiveAchievementList() pure public returns(bytes32[])
```
Returns current active achievement list(staked reward is enough)

```
function getAchievementId(address creator, uint256[] topics) pure public returns(bytes32)
```
Get achievement ID. Achievement Id = keccak256(abi.encodePacked(creator, topics[0], issuer[0], topics[1], issuer[1], ...))
```
function getLengthOfAchievements() view public returns(uint256 length);
```
Get total length of achievements
```
function getAchievementById(bytes32 _achievementId) view public returns(bytes32 id, address creator, address[] issuers, uint256[] claimTopics, bytes32 title, bytes32 explanation, uint256 reward, string uri, uint256 createdAt)
```
Get achievement by Id
```
function getAchievementByIndex(uint256 _index) view public returns(bytes32 id, address creator, address[] issuers, uint256[] claimTopics, bytes32 title, bytes32 explanation, uint256 reward, string uri, uint256 createdAt);
```
Get achievement by index

**Achievement(ERC721/1155)**
The owner enable/disable transfer and approve. Transfer and Approve is disabled at first.

```
function getAllOf(address owner) pure public returns(uint256 ids, uint256[] uris)
```
Returns the achievements of the the specific user.

```
interface ERC1155Metadata {
    /**
        @notice A distinct Uniform Resource Identifier (URI) for a given asset
        @dev URIs are defined in RFC 3986
        @return  URI string
    */
    function uri(uint256 _id) external view returns (string);

    /**
        @dev Returns a human readable string that identifies a CryptoItem, similar to ERC20
        @param _id  ID of the CryptoItem
        @return     The name of the CryptoItem type
     */
    function name(uint256 _id) external view returns (string);
}
```

# solidity_flattener


* Original ERC725-735 Source Code From : https://github.com/mirceapasoi/erc725-735