pragma solidity ^0.4.24;

import "../openzeppelin-solidity/contracts/ownership/Ownable.sol";
/// @title TopicRegistry
/// @author genie
/// @notice Topic Registry.
/// @dev  Topics can be registered when create achievement or the permissioned.
contract TopicRegistry {
    
    
    struct Topic {
        uint256 id;
        address issuer;
        bytes32 explanation;
    }

    uint256 public topicNonce;
    mapping(uint256 => Topic) topics;
/*
    constructor() {
        topicNonce = 1024;
    }
*/
    function registerTopic(uint256 id, address issuer, bytes32 explanation) /* permissioned */public {
        
    }    

    function getTopic(uint256 id) view public returns(address, bytes32){
        return (topics[id].issuer, topics[id].explanation);
    }

    function getTopics() view public returns(address[] issuers, bytes32[] explanations) {

    }
}
