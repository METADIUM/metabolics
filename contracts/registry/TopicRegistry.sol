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
        uint256 createdAt;
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

    /**
     * @dev Register new topic by system. this topic numbers should be 0~1024.
     * @param _id basic managementKey to use
     * @param _issuer creator of this topic
     * @param _explanation explanation
     * @return A boolean that indicates if the operation was successful.
     */
    function registerTopicBySystem(uint256 _id, address _issuer, bytes32 _explanation) permissioned public returns (uint256) {

        // check topic doesn't exist
        require(topics[_id].id == 0 && _id < RESERVED_TOPICS);

        Topic memory t;
        t.id = _id;
        t.issuer = _issuer;
        t.explanation = _explanation;
        t.createdAt = now;
        topics[_id] = t;

        isTopicRegistered[_id] = true;

        emit RegisterTopic(_id, _issuer, _explanation);
        
        return _id;
    }  

    /**
     * @dev Register topic by general user(usually aa). this topic numbers are incrementally set.
     * @param _issuer creator of this topic
     * @param _explanation explanation
     * @return A boolean that indicates if the operation was successful.
     */
    function registerTopic(address _issuer, bytes32 _explanation) public returns (uint256) {
        IAttestationAgencyRegistry ar = IAttestationAgencyRegistry(REG.getContractAddress("AttestationAgencyRegistry"));
        require(ar.isRegistered(msg.sender) != 0 || isPermitted(msg.sender)); //Only Attestation Agency or permissioned can register topic

        Topic memory t;
        t.id = total;
        t.issuer = _issuer;
        t.explanation = _explanation;
        t.createdAt = now;
        topics[total] = t;
        
        isTopicRegistered[total] = true;

        emit RegisterTopic(total, _issuer, _explanation);

        total++;

        return total-1; // return new topic id
    }    
    
    /**
     * @dev Update topic by creator.
     * @param _id topic to update
     * @param _explanation explanation
     * @return A boolean that indicates if the operation was successful.
     */
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
    
    function getTopic(uint256 _id) view public returns(address, bytes32, uint256){
        return (topics[_id].issuer, topics[_id].explanation, topics[_id].createdAt);
    }

    /**
     * @dev Batch Read functino for topic
     * @param _from from
     * @param _to to
     * @return A boolean that indicates if the operation was successful.
     */
    function getTopicFromTo(uint256 _from, uint256 _to) view public returns(address[], bytes32[], uint256[]){
        require(_to>_from);
        address[] memory saddrs = new address[](_to-_from+1);
        bytes32[] memory sexplans = new bytes32[](_to-_from+1);
        uint256[] memory screateds = new uint256[](_to-_from+1);

        for(uint256 i=_from;i<=_to;i++){
            saddrs[i-_from] = topics[i].issuer;
            sexplans[i-_from] = topics[i].explanation;
            screateds[i-_from] = topics[i].createdAt;
        }

        return (saddrs, sexplans, screateds);
    }

}
