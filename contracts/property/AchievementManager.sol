pragma solidity ^0.4.24;

import "../openzeppelin-solidity/contracts/math/SafeMath.sol";
import "../identity/ERC735.sol";
import "../RegistryUser.sol";
import "../registry/TopicRegistry.sol";
import "../interface/IAchievement.sol";
import "../interface/IIdentityManager.sol";
import "../interface/IAttestationAgencyRegistry.sol";

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

    event CreateAchievement(bytes32 indexed achievementId, uint256[] topics, address[] issuers, uint256 staked, string uri, uint256 timestamp);
    event UpdateAchievement(bytes32 indexed achievementId, uint256 reward, uint256 charge);
    event DeleteAchievement(bytes32 indexed achievementId, uint256 refund);
    event RequestAchievement(bytes32 indexed achievementId, address indexed receiver, uint256 reward);

    struct Achievement {
        bytes32 id;
        address creator;
        address[] issuers;
        uint256[] claimTopics;
        bytes32 explanation;
        uint256 reward;
        string uri;
        uint256 createdAt;
    }

    function isAAttestationAgency(address _addr) public returns(bool found) {
        
        IAttestationAgencyRegistry ar = IAttestationAgencyRegistry(REG.getContractAddress("AttestationAgencyRegistry"));
        require(ar.isRegistered(_addr) != 0);

        return true;
    }

    modifier onlyAttestationAgency() {
        require(isAAttestationAgency(msg.sender));
        _;
    }


    function AchievementManager() public {
        THIS_NAME = "AchievementManager";
    }

    /**
     * @dev Create Achievement. Topics should be registered first.
     * @param _topics registered topics
     * @param _issuers issuers for each topic
     * @param _achievementExplanation achievement explanation
     * @param _reward reward in meta when user request acievement
     * @param _uri basically used for ipfs id or something
     * @return A boolean that indicates if the operation was successful.
     */
    function createAchievement(uint256[] _topics, address[] _issuers, bytes32 _achievementExplanation, uint256 _reward, string _uri) onlyAttestationAgency public payable returns (bool success) {

        //check if achievement is already registered
        bytes32 achievementId = getAchievementId(msg.sender, _topics, _issuers);
        require(achievements[achievementId].id == 0);

        //check staking amount used for reward
        require(msg.value >= minimumDeposit);

        //topics should be registered already
        TopicRegistry topicRegistry = TopicRegistry(REG.getContractAddress("TopicRegistry"));
        for(uint256 i=0;i<_topics.length;i++){
            require(topicRegistry.isRegistered(_topics[i]), 'topic not registered');
        }
        
        Achievement memory newAc;
        newAc.id = achievementId;
        newAc.creator = msg.sender;
        newAc.issuers = _issuers;
        newAc.claimTopics = _topics;
        newAc.explanation = _achievementExplanation;
        newAc.uri = _uri;
        newAc.reward = _reward;
        newAc.createdAt = now;

        achievements[newAc.id] = newAc;
        allAchievements.push(achievementId);
        balance[achievementId] = msg.value;

        emit CreateAchievement(achievementId, _topics, _issuers, msg.value, _uri, now);

        return true;
    }

    //TODO createAchievementWithNewTopics
    // /**
    //  * @dev Create Achievement. If topic is not exist, register it to the topic registry.
    //  * @param _topics registered topics
    //  * @param _newTopicExaplanations explanations of new topics
    //  * @param _issuers issuers for each topic
    //  * @param _achievementExplanation achievement explanation
    //  * @param _reward reward in meta when user request acievement
    //  * @param _uri basically used for ipfs id or something
    //  * @return A boolean that indicates if the operation was successful.
    //  */
    // function createAchievementWithNewTopics(uint256[] _topics, bytes32[] _newTopicExaplanations, address[] _issuers, bytes32 _achievementExplanation, uint256 _reward, string _uri) onlyAttestationAgency public payable returns (bool) {

    //     require((_topics.length + _newTopicExaplanations.length) == issuers.length);

    //     //check staking amount used for reward
    //     require(msg.value >= minimumDeposit);
    //     TopicRegistry topicRegistry = TopicRegistry(REG.getContractAddress("TopicRegistry"));

    //     uint256[] memory allTopics = new uint[](_topics.length + _newTopicExaplanations.length);

    //     uint256 i;
    //     for(i=0;i<_topics.length;i++){
    //         allTopics[i] = _topics[i];
    //     }

    //     for(i=_topics.length;i<_topics.length+_newTopicExaplanations.length;i++) {
    //         allTopics[i] = topicRegistry.registerTopic(msg.sender, _newTopicExaplanations[i]);
    //     }

    //     //check if achievement is already registered
    //     bytes32 achievementId = getAchievementId(msg.sender, topics, issuers);
    //     require(achievements[achievementId].id == 0);
    //     Achievement memory newAc;
    //     newAc.id = achievementId;
    //     newAc.creator = msg.sender;
    //     newAc.issuers = issuers;
    //     newAc.claimTopics = topics;
    //     newAc.explanation = achievementExplanation;
    //     newAc.uri = uri;
    //     newAc.reward = reward;

    //     achievements[newAc.id] = newAc;
    //     allAchievements.push(achievementId);
    //     balance[achievementId] = msg.value;

    //     return true;
    // }
    

    /**
     * @dev Update Achievement. Fund can be charged through this, and reward can be set newly.
     * @param _achievementId achievementId
     * @param _reward new reward
     * @return A boolean that indicates if the operation was successful.
     */
    function updateAchievement(bytes32 _achievementId, uint256 _reward) public payable returns (bool success) {
        //Only creator can charge fund
        require(achievements[_achievementId].creator == msg.sender);

        achievements[_achievementId].reward = _reward;
        balance[_achievementId] = msg.value;
        emit UpdateAchievement(_achievementId, _reward, msg.value);
        return true;
    }

    /**
     * @dev Delete Achievement. This function DOES NOT actually delete achievement.
     * Just refund to the creator.
     * @param _achievementId achievementId
     * @return A boolean that indicates if the operation was successful.
     */
    function deleteAchievement(bytes32 _achievementId) public returns (bool success) {
        //Only creator can refund
        require(achievements[_achievementId].creator == msg.sender);

        uint256 rest = balance[_achievementId];
        
        balance[_achievementId] = 0;
        msg.sender.transfer(rest);
        
        emit DeleteAchievement(_achievementId, rest);

        return true;
    }
    /**
     * @dev Request achievement. If user have proper claims, user get acievement(ERC721) token and meta reward
     * @param _achievementId _achievementId user want to request
     * @return A boolean that indicates if the operation was successful.
     */
    function requestAchievement(bytes32 _achievementId) public returns (bool success) {
        // check whether msg.sender is deployed using IdentityManager
        IIdentityManager im = IIdentityManager(REG.getContractAddress("IdentityManager"));
        require(im.isMetaId(msg.sender), 'msg.sender is not identity created by IdentityManager');
        
        uint256 i;
        ERC735 identity = ERC735(msg.sender);
        // // check if sender has enough claims
        for(i=0;i<achievements[_achievementId].claimTopics.length;i++) {
            address issuer;
            // claimId is made by topic and issuer.
            bytes32 claimId = keccak256(abi.encodePacked(achievements[_achievementId].issuers[i], achievements[_achievementId].claimTopics[i]));
            (, , issuer, , , ) = identity.getClaim(claimId); // getClaim returns (topic, scheme, issuer, signature, data, uri)

            require(issuer != address(0));

        }
        
        // give reward to msg.sender(identity contract)
        require(balance[_achievementId] >= achievements[_achievementId].reward);
        balance[_achievementId] = balance[_achievementId].sub(achievements[_achievementId].reward);
        msg.sender.transfer(achievements[_achievementId].reward);

        // mint achievement erc721 to msg.sender;
        IAchievement achievement = IAchievement(REG.getContractAddress("Achievement"));
        require(achievement.mint(msg.sender, uint256(keccak256(abi.encodePacked(msg.sender, _achievementId))), string(abi.encodePacked(now,achievements[_achievementId].uri))));
        
        emit RequestAchievement(_achievementId, msg.sender, achievements[_achievementId].reward);

        return true;
    }
   
    function getAllAchievementList() view public returns (bytes32[] list) {
        return allAchievements;
    }
   
    function getActiveAchievementList() view public returns(bytes32[] list) {

    }

    function getLengthOfAchievements() view public returns(uint256 length) {
        return allAchievements.length;
    }

    function getAchievementById(bytes32 _achievementId) view public returns(bytes32 id, address creator, address[] issuers, uint256[] claimTopics, bytes32 explanation, uint256 reward, string uri, uint256 timestamp) {
        Achievement memory ac = achievements[_achievementId];
        return (
            ac.id, 
            ac.creator, 
            ac.issuers, 
            ac.claimTopics, 
            ac.explanation, 
            ac.reward, 
            ac.uri,
            ac.createdAt
            );
    }

    function getAchievementByIndex(uint256 _index) view public returns(bytes32 id, address creator, address[] issuers, uint256[] claimTopics, bytes32 explanation, uint256 reward, string uri, uint256 timestamp) {
        bytes32 _achievementId = allAchievements[_index];
        return (
            achievements[_achievementId].id, 
            achievements[_achievementId].creator, 
            achievements[_achievementId].issuers, 
            achievements[_achievementId].claimTopics, 
            achievements[_achievementId].explanation, 
            achievements[_achievementId].reward, 
            achievements[_achievementId].uri,
            achievements[_achievementId].createdAt
            );

    }

    /**
     * @dev Get achievement id. an achievement ID is unique with given params.
     * achievementId = keccak256(abi.encodePacked(creator, topic1, issuer1, topic2, issuer2, ...))
     * @param creator achievement creator
     * @param topics topics achievement requirements
     * @param issuers issuers achievement requirements
     * @return A boolean that indicates if the operation was successful.
     */
    function getAchievementId(address creator, uint256[] topics, address[] issuers) pure public returns(bytes32 id) {
        bytes memory idBytes;
        
        require(topics.length == issuers.length);
        
        idBytes = abi.encodePacked(idBytes, creator);

        for(uint i=0;i<topics.length;i++){
            idBytes = abi.encodePacked(idBytes, topics[i], issuers[i]);
        }
        return keccak256(idBytes);
    }

}
