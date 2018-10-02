pragma solidity ^0.4.24;

//import "../Registry.sol";
import "../RegistryUser.sol";
import "../registry/TopicRegistry.sol";

/**
 * @title AchievementManager
 * @dev AchievementManager Contract used to manage achievement system in metadium
 * The permissinoed participant can CRUD the achievement.
 */
contract AchievementManager is RegistryUser{
    
    uint256 public minimumDeposit = 1 * 10 ** 18;

    mapping(uint256 => Achievement) public achievements; // achievementId => achievement
    mapping(uint256 => uint256) public balance; // achievementId => balance

    uint256[] public allAchievements;

    struct Achievement {
        uint256 id;
        address issuer;
        uint256[] claimTopics;
        bytes32 explanation;
        string uri;
    }

    function AchievementManager() public {
        THIS_NAME = "AchievementManager";
    }

    function createAchievement(uint256[] topics, address[] issuers, bytes32[] topicExplanations, bytes32 achievementExplanation, uint256 reward, string uri) public payable returns (bool) {
        
        //check if achievement is already registered
        uint256 achievementId = getAchievementId(msg.sender, topics);
        require(achievements[achievementId].id == 0);

        //check staking amount used for reward
        require(msg.value >= minimumDeposit);
        TopicRegistry topicRegistry = TopicRegistry(REG.getContractAddress("TopicRegistry"));

        //check topics. Register topics if not exist on the topic registry
        //revert if topic and explanation do not match on the topic registry
        for(uint i=0;i<topics.length;i++) {
            uint256 _id;
            address _issuer;
            bytes32 _explanation;
            (_issuer, _explanation) = topicRegistry.getTopic(topics[i]);
            if(_issuer == address(0)) {
                //if topic is not registered, register topic
                //require(topicRegistry.registerTopic(topics[i], issuers[i], topicExplanations[i]), 'New Topic cannot be registered');
                require(topicRegistry.registerTopic(topics[i], issuers[i], topicExplanations[i]));
            } else {
                //if topic is not registered, check the topic and explanation
                require(_issuer == issuers[i], 'Topic issuer Mismatch');
                require(_explanation == topicExplanations[i], 'Topic explanation Mismatch');
                
            }
        }
        
        Achievement memory newAc;
        newAc.id = achievementId;
        newAc.issuer = msg.sender;
        newAc.claimTopics = topics;
        newAc.explanation = achievementExplanation;
        newAc.uri = uri;

        achievements[newAc.id] = newAc;

        return true;
    }
   
    function updateAchievement(uint256 achievementId, uint256[] topics, bytes32[] topicExplanations, bytes32 achievementExplanation, uint256 reward, string ipfs) public payable returns (bool) {
    }
   
    function deleteAchievement(uint256 achievementId) public returns (bool) {

    }
   
    function requestAchievement(uint256 achievementId) public returns (bool) {

    }
   
    function getAllAchievementList() pure public returns (uint256[]) {

    }
   
    function getActiveAchievementList() pure public returns(uint256[]) {

    }

    function getAchievementId(address creator, uint256[] topics) pure public returns(uint256) {
        bytes memory idBytes;
        idBytes = abi.encodePacked(idBytes, creator);
        for(uint i=0;i<topics.length;i++){
            idBytes = abi.encodePacked(idBytes, topics[i]);
        }
        return uint256(keccak256(idBytes));
    }
}
