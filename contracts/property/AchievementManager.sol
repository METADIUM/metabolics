pragma solidity ^0.4.24;

import "../openzeppelin-solidity/contracts/math/SafeMath.sol";
import "../identity/ERC735.sol";
import "../RegistryUser.sol";
import "../registry/TopicRegistry.sol";
import "../interface/IAchievement.sol";


/**
 * @title AchievementManager
 * @dev AchievementManager Contract used to manage achievement system in metadium
 * The permissinoed participant can CRUD the achievement.
 */
contract AchievementManager is RegistryUser {
    using SafeMath for uint256;

    uint256 public minimumDeposit = 1 * 10 ** 18;

    mapping(bytes32 => Achievement) public achievements; // achievementId => achievement
    mapping(bytes32 => uint256) public balance; // achievementId => balance

    bytes32[] public allAchievements;

    struct Achievement {
        bytes32 id;
        address creator;
        address[] issuers;
        uint256[] claimTopics;
        bytes32 explanation;
        uint256 reward;
        string uri;
    }

    function AchievementManager() public {
        THIS_NAME = "AchievementManager";
    }

    function createAchievement(uint256[] topics, address[] issuers, bytes32[] topicExplanations, bytes32 achievementExplanation, uint256 reward, string uri) public payable returns (bool) {
        
        //check if achievement is already registered
        bytes32 achievementId = getAchievementId(msg.sender, topics, issuers);
        require(achievements[achievementId].id == 0);

        //check staking amount used for reward
        require(msg.value >= minimumDeposit);
        TopicRegistry topicRegistry = TopicRegistry(REG.getContractAddress("TopicRegistry"));

        //check topics. Register topics if not exist on the topic registry
        //revert if topic and explanation do not match on the topic registry
        for(uint256 i=0;i<topics.length;i++) {
            
            bytes32 _id;
            address _issuer;
            bytes32 _explanation;
            (_issuer, _explanation) = topicRegistry.getTopic(topics[i]);

            if(_issuer == address(0)) {
                //if topic is not registered, register topic
                //require(topicRegistry.registerTopic(topics[i], issuers[i], topicExplanations[i]), 'New Topic cannot be registered');
                require(topicRegistry.registerTopic(topics[i], msg.sender, topicExplanations[i]));

            } else {

                //if topic is not registered, check the topic and explanation
                // require(_issuer == issuers[i], 'Topic issuer Mismatch');
                require(_explanation == topicExplanations[i], 'Topic explanation Mismatch');
                
            }
        }
        
        Achievement memory newAc;
        newAc.id = achievementId;
        newAc.creator = msg.sender;
        newAc.issuers = issuers;
        newAc.claimTopics = topics;
        newAc.explanation = achievementExplanation;
        newAc.uri = uri;
        newAc.reward = reward;

        achievements[newAc.id] = newAc;
        allAchievements.push(achievementId);
        balance[achievementId] = msg.value;

        return true;
    }
   
    function updateAchievement(bytes32 achievementId, uint256[] topics, bytes32[] topicExplanations, bytes32 achievementExplanation, uint256 reward, string ipfs) public payable returns (bool) {
    }
   
    function deleteAchievement(bytes32 achievementId) public returns (bool) {

    }
   
    function requestAchievement(bytes32 achievementId) public returns (bool) {
        // check if msg.sender implemented erc735
        uint256 i;
        ERC735 identity = ERC735(msg.sender);
        // // check if sender has enough claims
        for(i=0;i<achievements[achievementId].claimTopics.length;i++) {
            uint256 topic;
            uint256 scheme;
            address issuer;
            bytes memory signature;
            bytes memory data;
            string memory uri;
            
            // claimId is made by topic and issuer.
            bytes32 claimId = keccak256(abi.encodePacked(achievements[achievementId].issuers[i], achievements[achievementId].claimTopics[i]));
            (topic, scheme, issuer, signature, data, uri) = identity.getClaim(claimId);

            require(issuer != address(0));

        }
        
        // // give reward to msg.sender(identity contract)
        require(balance[achievementId] >= achievements[achievementId].reward);
        balance[achievementId] = balance[achievementId].sub(achievements[achievementId].reward);
        msg.sender.transfer(achievements[achievementId].reward);

        // // mint achievement erc721 to msg.sender;
        
        IAchievement achievement = IAchievement(REG.getContractAddress("Achievement"));
        require(achievement.mint(msg.sender, uint256(keccak256(abi.encodePacked(msg.sender, achievementId))), string(abi.encodePacked(now))));

        return true;
    }
   
    function getAllAchievementList() view public returns (bytes32[]) {
        return allAchievements;
    }
   
    function getActiveAchievementList() view public returns(bytes32[]) {

    }

    function getAchievementId(address creator, uint256[] topics, address[] issuers) pure public returns(bytes32) {
        bytes memory idBytes;
        
        require(topics.length == issuers.length);
        
        idBytes = abi.encodePacked(idBytes, creator);

        for(uint i=0;i<topics.length;i++){
            idBytes = abi.encodePacked(idBytes, topics[i], issuers[i]);
        }
        return keccak256(idBytes);
    }

}
