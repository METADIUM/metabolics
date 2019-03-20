pragma solidity ^0.4.24;

import "openzeppelin-solidity/contracts/math/SafeMath.sol";
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

    event CreateAchievement(
        bytes32 indexed achievementId,
        uint256[] topics,
        address[] issuers,
        uint256 staked,
        string uri,
        uint256 createdAt
    );

    event UpdateAchievement(bytes32 indexed achievementId, uint256 reward, uint256 charge);
    event FundAchievement(bytes32 indexed achievementId, uint256 charge);
    event DeleteAchievement(bytes32 indexed achievementId, uint256 refund);
    event RequestAchievement(bytes32 indexed achievementId, address indexed receiver, uint256 reward, address rewarded);

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

    constructor() public {
        THIS_NAME = "AchievementManager";
    }

    function isAAttestationAgency(address _addr) public view returns (bool found) {
        IAttestationAgencyRegistry ar = IAttestationAgencyRegistry(REG.getContractAddress("AttestationAgencyRegistry"));
        require(ar.isRegistered(_addr) != 0, "address is not AA");

        return true;
    }

    modifier onlyAttestationAgency() {
        require(isAAttestationAgency(msg.sender), "msg.sender is not AA");
        _;
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
    function createAchievement(
        uint256[] _topics,
        address[] _issuers,
        bytes32 _title,
        bytes32 _achievementExplanation,
        uint256 _reward,
        string _uri
    )
        public
        onlyAttestationAgency
        payable
        returns (bool success)
    {
        // Check staking amount used for reward
        require(msg.value >= minimumDeposit, "deposit is not enough");

        // Check if topics are registered
        TopicRegistry topicRegistry = TopicRegistry(REG.getContractAddress("TopicRegistry"));
        for (uint256 i = 0; i < _topics.length; i++) {
            require(topicRegistry.isRegistered(_topics[i]), "Not registered topic");
            for (uint256 j = 0; j < _topics.length; j++) {
                if (i == j) continue;
                else if (_topics[i] == _topics[j] && _issuers[i] == _issuers[j]) {
                    revert("Duplicated topic/issuer pair");
                }
            }
        }

        // Check if achievement is registered
        bytes32 achievementId = getAchievementId(msg.sender, _topics, _issuers);
        require(achievements[achievementId].id == 0, "achievement already exists");

        Achievement memory newAc;
        newAc.id = achievementId;
        newAc.creator = msg.sender;
        newAc.issuers = _issuers;
        newAc.claimTopics = _topics;
        newAc.title = _title;
        newAc.explanation = _achievementExplanation;
        newAc.uri = _uri;
        newAc.reward = _reward;
        newAc.createdAt = block.timestamp;

        achievements[newAc.id] = newAc;
        allAchievements.push(achievementId);
        balance[achievementId] = msg.value;

        emit CreateAchievement(achievementId, _topics, _issuers, msg.value, _uri, block.timestamp);

        return true;
    }

    /**
     * @dev Update Achievement. Fund can be charged through this, and reward can be set newly.
     * @param _achievementId achievementId
     * @param _reward new reward
     * @return A boolean that indicates if the operation was successful.
     */
    function updateAchievement(bytes32 _achievementId, uint256 _reward) public payable returns (bool success) {
        //Only creator can charge fund in update
        require(achievements[_achievementId].creator == msg.sender, "sender is not creator");

        achievements[_achievementId].reward = _reward;
        balance[_achievementId] = balance[_achievementId].add(msg.value);

        emit UpdateAchievement(_achievementId, _reward, msg.value);

        return true;
    }

    /**
     * @dev fund Achievement. Anyone can fund the achievement.
     * @param _achievementId achievementId
     * @return A boolean that indicates if the operation was successful.
     */
    function fundAchievement(bytes32 _achievementId) public payable returns (bool success) {
        require(msg.value != 0, "fund amount should be greater than zero");
        require(achievements[_achievementId].creator != address(0), "achievementid is not valid");
        balance[_achievementId] = balance[_achievementId].add(msg.value);
        emit FundAchievement(_achievementId, msg.value);
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
        require(achievements[_achievementId].creator == msg.sender, "sender is not creator");

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

        ERC735 identity = ERC735(msg.sender);
        // // check if sender has enough claims
        for (uint256 i = 0; i < achievements[_achievementId].claimTopics.length; i++) {
            address issuer;
            // check this claim issuer is for self claim
            if (achievements[_achievementId].issuers[i] == 0xFFfFfFffFFfffFFfFFfFFFFFffFFFffffFfFFFfF) {
                require(hasSelfClaim(msg.sender, achievements[_achievementId].claimTopics[i]), "Self-Claim prove Fail");
            } else {
                // claimId is made by topic and issuer.
                bytes32 claimId = keccak256(abi.encodePacked(
                    achievements[_achievementId].issuers[i],
                    achievements[_achievementId].claimTopics[i]));
                (, , issuer, , , ) = identity.getClaim(claimId);
                require(issuer != address(0), "Claim not exist");
            }
        }
        
        // give reward to msg.sender(identity contract)'s 0th managementKey
        require(balance[_achievementId] >= achievements[_achievementId].reward, "reward is not enough");
        balance[_achievementId] = balance[_achievementId].sub(achievements[_achievementId].reward);

        bytes32[] memory managementKeys = ERC725(msg.sender).getKeysByPurpose(1); // 1 : MANAGEMENT KEY
        address(managementKeys[0]).transfer(achievements[_achievementId].reward);

        // mint achievement erc721 to msg.sender;
        IAchievement achievement = IAchievement(REG.getContractAddress("Achievement"));
        require(
            achievement.mint(
                msg.sender,
                uint256(keccak256(abi.encodePacked(msg.sender, _achievementId))),
                string(abi.encodePacked(block.timestamp, achievements[_achievementId].uri))
            ),
            "achievement cannot be minted"
        );

        emit RequestAchievement(
            _achievementId,
            msg.sender,
            achievements[_achievementId].reward,
            address(managementKeys[0])
        );

        return true;
    }

    function hasSelfClaim(address _identity, uint256 _topic) public view returns (bool) {
        bytes32[] memory claims = ERC735(_identity).getClaimIdsByType(_topic);
        address c;
        for (uint256 i = 0; i < claims.length; i++) {
            (, , c, , ,) = ERC735(_identity).getClaim(claims[i]);
            //3: CLAIM signer keys, used to sign claims on other identities which need to be revokable.
            //bytes32(address) : addrToKey(addr)
            if (ERC725(_identity).keyHasPurpose(bytes32(c), 3) || c == msg.sender) {
                //true if isuuer is identity's claim key or smart contract identity itself
                return true;
            }   
        }
        return false;
    }

    function getAllAchievementList() public view returns (bytes32[] list) {
        return allAchievements;
    }

    //TODO : achievement with proper balance
    function getActiveAchievementList() public view returns (bytes32[] list) {
        return allAchievements;
    }

    function getLengthOfAchievements() public view returns (uint256 length) {
        return allAchievements.length;
    }

    function getAchievementById(bytes32 _achievementId)
        public
        view
        returns (
            bytes32 id,
            address creator,
            address[] issuers,
            uint256[] claimTopics,
            bytes32 title,
            bytes32 explanation,
            uint256 reward,
            string uri,
            uint256 createdAt
        )
    {
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

    function getAchievementByIndex(uint256 _index)
        public
        view
        returns (
            bytes32 id,
            address creator,
            address[] issuers,
            uint256[] claimTopics,
            bytes32 title,
            bytes32 explanation,
            uint256 reward,
            string uri,
            uint256 createdAt
        )
    {
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
    function getAchievementId(address creator, uint256[] topics, address[] issuers) public pure returns (bytes32 id) {
        require(topics.length == issuers.length, "topic, issuer length mismatch");
        
        bytes memory idBytes;
        idBytes = abi.encodePacked(idBytes, creator);
        for (uint i = 0; i < topics.length; i++) {
            idBytes = abi.encodePacked(idBytes, topics[i], issuers[i]);
        }
        return keccak256(idBytes);
    }
}
