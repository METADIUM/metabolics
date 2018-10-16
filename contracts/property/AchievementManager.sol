pragma solidity ^0.4.24;

import "../openzeppelin-solidity/contracts/math/SafeMath.sol";
import "../identity/ERC735.sol";
import "../RegistryUser.sol";
import "../registry/TopicRegistry.sol";
import "../interface/IAchievement.sol";
import "../interface/IIdentityManager.sol";


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

    /**
     * @dev Create Achievement. If topic is not exist, register it to the topic registry.
     * @param topics topics need to get the achievement.
     * @param issuers issuers for each topic
     * @param topicExplanations explanations of each topics
     * @param achievementExplanation achievement explanation
     * @param reward reward in meta when user request acievement
     * @param uri basically used for ipfs id
     * @return A boolean that indicates if the operation was successful.
     */
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
    /**
     * @dev Request achievement. If user have proper claims, user get acievement(ERC721) token and meta reward
     * @param achievementId achievementId user want to request
     * @return A boolean that indicates if the operation was successful.
     */
    function requestAchievement(bytes32 achievementId) public returns (bool) {
        // check whether msg.sender is deployed using IdentityManager
        IIdentityManager im = IIdentityManager(REG.getContractAddress("IdentityManager"));
        require(im.isMetaId(msg.sender), 'msg.sender is not identity created by IdentityManager');
        
        uint256 i;
        ERC735 identity = ERC735(msg.sender);
        // // check if sender has enough claims
        for(i=0;i<achievements[achievementId].claimTopics.length;i++) {
            address issuer;
            // claimId is made by topic and issuer.
            bytes32 claimId = keccak256(abi.encodePacked(achievements[achievementId].issuers[i], achievements[achievementId].claimTopics[i]));
            (, , issuer, , , ) = identity.getClaim(claimId); // getClaim returns (topic, scheme, issuer, signature, data, uri)

            require(issuer != address(0));

        }
        
        // give reward to msg.sender(identity contract)
        require(balance[achievementId] >= achievements[achievementId].reward);
        balance[achievementId] = balance[achievementId].sub(achievements[achievementId].reward);
        msg.sender.transfer(achievements[achievementId].reward);

        // mint achievement erc721 to msg.sender;
        IAchievement achievement = IAchievement(REG.getContractAddress("Achievement"));
        require(achievement.mint(msg.sender, uint256(keccak256(abi.encodePacked(msg.sender, achievementId))), string(abi.encodePacked(now))));

        return true;
    }
   
    function getAllAchievementList() view public returns (bytes32[]) {
        return allAchievements;
    }
   
    function getActiveAchievementList() view public returns(bytes32[]) {

    }

    /**
     * @dev Get achievement id. an achievement ID is unique with given params.
     * achievementId = keccak256(abi.encodePacked(creator, topic1, issuer1, topic2, issuer2, ...))
     * @param creator achievement creator
     * @param topics topics achievement requirements
     * @param issuers issuers achievement requirements
     * @return A boolean that indicates if the operation was successful.
     */
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
