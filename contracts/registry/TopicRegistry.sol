pragma solidity ^0.4.24;

import "../RegistryUser.sol";
import "../interface/IAttestationAgencyRegistry.sol";

/// @title TopicRegistry
/// @author genie
/// @notice Topic Registry.
/// @dev  Topics can be registered when create achievement or the permissioned.
contract TopicRegistry is RegistryUser {
    
    struct Topic {
        uint256 id;
        address issuer;
        bytes32 explanation;
    }

    uint256 public total;
    uint256 public constant RESERVED_TOPICS = 1024;
    
    mapping(uint256 => Topic) public topics;
    mapping(uint256 => bool) isTopicRegistered;

    event RegisterTopic(uint256 indexed id, address indexed issuer, bytes32 explanation);
    event UpdateTopic(uint256 indexed id, address indexed issuer, bytes32 explanation);

    constructor() public {

        total = RESERVED_TOPICS + 1;

    }

    function registerTopicBySystem(uint256 _id, address _issuer, bytes32 _explanation) permissioned public returns (uint256) {

        // check topic doen't exist
        require(topics[_id].id == 0 && _id < RESERVED_TOPICS);

        Topic memory t;
        t.id = _id;
        t.issuer = _issuer;
        t.explanation = _explanation;
        topics[_id] = t;

        isTopicRegistered[_id] = true;

        emit RegisterTopic(_id, _issuer, _explanation);
        
        return _id;
    }   

    function registerTopic(address _issuer, bytes32 _explanation) public returns (uint256) {
        IAttestationAgencyRegistry ar = IAttestationAgencyRegistry(REG.getContractAddress("AttestationAgencyRegistry"));
        require(ar.isRegistered(msg.sender) != 0 || isPermitted(msg.sender)); //Only Attestation Agency or permissioned can register topic

        Topic memory t;
        t.id = total;
        t.issuer = _issuer;
        t.explanation = _explanation;
        topics[total] = t;
        
        isTopicRegistered[total] = true;

        emit RegisterTopic(total, _issuer, _explanation);

        total++;

        return total-1; // return new topic id
    }    
    
    function updateTopic(uint256 _id, bytes32 _explanation) public returns (bool) {
        
        require(topics[_id].issuer == msg.sender);

        topics[_id].explanation = _explanation;

        emit UpdateTopic(_id, msg.sender , _explanation);

    }

    function isRegistered(uint256 _id) view public returns (bool) {
        return isTopicRegistered[_id];
    }

    function getTotal() view public returns (uint256) {
        return total;
    }
    
    function getTopic(uint256 _id) view public returns(address, bytes32){
        return (topics[_id].issuer, topics[_id].explanation);
    }

    function getTopicFromTo(uint256 _from, uint256 _to) view public returns(address[], bytes32[]){
        require(_to>_from);
        address[] memory saddrs = new address[](_to-_from+1);
        bytes32[] memory sexplans = new bytes32[](_to-_from+1);

        for(uint256 i=_from;i<=_to;i++){
            saddrs[i-_from] = topics[i].issuer;
            sexplans[i-_from] = topics[i].explanation;
        }

        return (saddrs, sexplans);
    }

}
