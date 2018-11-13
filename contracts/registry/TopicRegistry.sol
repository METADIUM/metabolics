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
        bytes32 title;
        address issuer;
        bytes32 explanation;
        uint256 createdAt;
    }

    uint256 public total;
    uint256 public constant RESERVED_TOPICS = 1025; // 0 ~ 1024
    
    mapping(uint256 => Topic) public topics;
    mapping(uint256 => bool) isTopicRegistered;

    event RegisterTopic(uint256 indexed id, address indexed issuer, bytes32 explanation);
    event UpdateTopic(uint256 indexed id, address indexed issuer, bytes32 explanation);

    constructor() public {
        THIS_NAME = "TopicRegistry";
        total = RESERVED_TOPICS;

    }
    
    /**
     * @dev Register new topic by system. this topic numbers should be 0~1024.
     * @param _id basic managementKey to use
     * @param _title title
     * @param _explanation explanation
     * @return new topic id
     */
    function registerTopicBySystem(uint256 _id, bytes32 _title, bytes32 _explanation) public permissioned returns (uint256 topicId) {

        // check topic doesn't exist
        require(topics[_id].id == 0 && _id < RESERVED_TOPICS, "Topic term is wrong");

        Topic memory t;
        t.id = _id;
        t.title = _title;
        t.issuer = msg.sender;
        t.explanation = _explanation;
        t.createdAt = block.timestamp;
        topics[_id] = t;

        isTopicRegistered[_id] = true;

        emit RegisterTopic(_id, msg.sender, _explanation);
        
        return _id;
    }  

    /**
     * @dev Register topic by general user(usually aa). this topic numbers are incrementally set.
     * @param _title title
     * @param _explanation explanation
     * @return new topic id
     */
    function registerTopic(bytes32 _title, bytes32 _explanation) public returns (uint256 topicId) {
        IAttestationAgencyRegistry ar = IAttestationAgencyRegistry(REG.getContractAddress("AttestationAgencyRegistry"));

        //Only Attestation Agency or permissioned can register topic
        require(ar.isRegistered(msg.sender) != 0 || isPermitted(msg.sender),"No permission"); 

        Topic memory t;
        t.id = total;
        t.issuer = msg.sender;
        t.title = _title;
        t.explanation = _explanation;
        t.createdAt = block.timestamp;
        topics[total] = t;
        
        isTopicRegistered[total] = true;

        emit RegisterTopic(total, msg.sender, _explanation);

        total++;

        return total-1; // return new topic id
    }    

    
    /**
     * @dev Update topic by creator.
     * @param _id topic to update
     * @param _explanation explanation
     * @return A boolean that indicates if the operation was successful.
     */
    function updateTopic(uint256 _id, bytes32 _explanation) public returns (bool success) {
        
        require(topics[_id].issuer == msg.sender,"issuer mismatch");

        topics[_id].explanation = _explanation;

        emit UpdateTopic(_id, msg.sender, _explanation);

        return true;

    }


    function isRegistered(uint256 _id) public view returns (bool found) {
        return isTopicRegistered[_id];
    }


    function getTotal() public view returns (uint256 length) {
        return total;
    }
    
    function getTopic(uint256 _id) public view returns(address issuer, bytes32 title, bytes32 explanation, uint256 createdAt) {
        return (topics[_id].issuer, topics[_id].title, topics[_id].explanation, topics[_id].createdAt);
    }

    /**
     * @dev Batch Read functino for topic
     * @param _from from
     * @param _to to
     * @return topic data
     */
    function getTopicFromTo(uint256 _from, uint256 _to) 
    public 
    view
    returns(address[] addrs, bytes32[] titles, bytes32[] explans, uint256[] createds)
    {
        require(_to>_from, "from to mismatch");
        address[] memory saddrs = new address[](_to-_from+1);
        bytes32[] memory sexplans = new bytes32[](_to-_from+1);
        uint256[] memory screateds = new uint256[](_to-_from+1);
        bytes32[] memory stitles = new bytes32[](_to-_from+1);

        for (uint256 i = _from;i<=_to;i++) {
            saddrs[i-_from] = topics[i].issuer;
            sexplans[i-_from] = topics[i].explanation;
            screateds[i-_from] = topics[i].createdAt;
            stitles[i-_from] = topics[i].title;
        }

        return (saddrs, stitles, sexplans, screateds);
    }

}
