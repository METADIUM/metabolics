pragma solidity ^0.4.24;

import "../openzeppelin-solidity/contracts/math/SafeMath.sol";
import "../identity/ERC735.sol";
import "../identity/ERC725.sol";
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

    event CreateAchievement(bytes32 indexed achievementId, uint256[] topics, address[] issuers, uint256 staked, string uri, uint256 createdAt);
    event UpdateAchievement(bytes32 indexed achievementId, uint256 reward, uint256 charge);
    event DeleteAchievement(bytes32 indexed achievementId, uint256 refund);
    event RequestAchievement(bytes32 indexed achievementId, address indexed receiver, uint256 reward);

    struct Achievement {
        bytes32 id;
        bytes32 title;
        address creator;
        address[] issuers;
        uint256[] claimTopics;
        bytes32 explanation;
        uint256 reward;
        string uri;
        uint256 createdAt;
    }

    function isAAttestationAgency(address _addr) view public returns(bool found) {
        
        IAttestationAgencyRegistry ar = IAttestationAgencyRegistry(REG.getContractAddress("AttestationAgencyRegistry"));
        require(ar.isRegistered(_addr) != 0);

        return true;
    }

    modifier onlyAttestationAgency() {
        require(isAAttestationAgency(msg.sender));
        _;
    }

    constructor() public {
        THIS_NAME = "AchievementManager";
    }

    /**
     * @dev Create Achievement. Topics should be registered first.
     * topic & issuer term cannot be same simultaneously with the previos one.
     * @param _topics registered topics, ascending order (1,10,10, 100)
     * @param _issuers issuers for each topic
     * @param _title title
     * @param _achievementExplanation achievement explanation
     * @param _reward reward in meta when user request acievement
     * @param _uri basically used for ipfs id or something
     * @return A boolean that indicates if the operation was successful.
     */
    function createAchievement(uint256[] _topics, address[] _issuers, bytes32 _title, bytes32 _achievementExplanation, uint256 _reward, string _uri) onlyAttestationAgency public payable returns (bool success) {

        //check staking amount used for reward
        require(msg.value >= minimumDeposit);

        //topics should be registered already
        TopicRegistry topicRegistry = TopicRegistry(REG.getContractAddress("TopicRegistry"));
        for(uint256 i=0;i<_topics.length;i++){
            if( i > 0 ) {
                if(
                    _topics[i] < _topics[i-1] ||
                    (_topics[i] == _topics[i-1] && _issuers[i] == _issuers[i-1])

                ){
                    revert('Topic and Issuer condition is wrong');
                }
            }
            require(topicRegistry.isRegistered(_topics[i]), "topic not registered");
        }

        //check if achievement is already registered
        bytes32 achievementId = getAchievementId(msg.sender, _topics, _issuers);
        require(achievements[achievementId].id == 0);


        Achievement memory newAc;
        newAc.id = achievementId;
        newAc.creator = msg.sender;
        newAc.issuers = _issuers;
        newAc.claimTopics = _topics;
        newAc.title = _title;
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
        require(im.isMetaId(msg.sender), "msg.sender is not identity created by IdentityManager");
        
        uint256 i;
        ERC735 identity = ERC735(msg.sender);
        // // check if sender has enough claims
        for(i=0;i<achievements[_achievementId].claimTopics.length;i++) {
            address issuer;
            // check this claim issuer is for self claim
            if(achievements[_achievementId].issuers[i] == 0xFFfFfFffFFfffFFfFFfFFFFFffFFFffffFfFFFfF){
                //self claim
                //bytes32 claimId = keccak256(abi.encodePacked(msg.sender, achievements[_achievementId].claimTopics[i]));
                //check msg.sender is erc735 implementation
                //
                //identity.getClaimIdsByType(achievements[_achievementId].claimTopics[i]);
                require(hasSelfClaim(msg.sender, achievements[_achievementId].claimTopics[i]));

            }else {
                // claimId is made by topic and issuer.
                bytes32 claimId = keccak256(abi.encodePacked(achievements[_achievementId].issuers[i], achievements[_achievementId].claimTopics[i]));
                (, , issuer, , , ) = identity.getClaim(claimId); // getClaim returns (topic, scheme, issuer, signature, data, uri)
                require(issuer != address(0));
            }

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


    function hasSelfClaim(address _identity, uint256 _topic) public view returns (bool) {
        bytes32[] memory claims = ERC735(_identity).getClaimIdsByType(_topic);
        address c;
        for(uint256 i=0;i<claims.length;i++){
            (, , c, , ,) = ERC735(_identity).getClaim(claims[i]);
            //3: CLAIM signer keys, used to sign claims on other identities which need to be revokable.
            //bytes32(address) : addrToKey(addr)
            if(ERC725(_identity).keyHasPurpose(bytes32(c), 3) || c == msg.sender){
                //true if isuuer is identity's claim key or smart contract identity itself
                return true;
            }
            
        }
        return false;

    }
    function getAllAchievementList() view public returns (bytes32[] list) {
        return allAchievements;
    }

    //TODO : achievement with proper balance
    function getActiveAchievementList() view public returns(bytes32[] list) {
        return allAchievements;
    }

    function getLengthOfAchievements() view public returns(uint256 length) {
        return allAchievements.length;
    }

    function getAchievementById(bytes32 _achievementId) view public returns(bytes32 id, address creator, address[] issuers, uint256[] claimTopics, bytes32 title, bytes32 explanation, uint256 reward, string uri, uint256 createdAt) {
        Achievement memory ac = achievements[_achievementId];
        return (
            ac.id, 
            ac.creator, 
            ac.issuers, 
            ac.claimTopics, 
            ac.title, 
            ac.explanation, 
            ac.reward, 
            ac.uri,
            ac.createdAt
            );
    }

    function getAchievementByIndex(uint256 _index) view public returns(bytes32 id, address creator, address[] issuers, uint256[] claimTopics, bytes32 title, bytes32 explanation, uint256 reward, string uri, uint256 createdAt) {
        bytes32 _achievementId = allAchievements[_index];
        return (
            achievements[_achievementId].id, 
            achievements[_achievementId].creator, 
            achievements[_achievementId].issuers, 
            achievements[_achievementId].claimTopics, 
            achievements[_achievementId].title, 
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
