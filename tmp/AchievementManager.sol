pragma solidity ^0.4.13;

contract ERC165 {
    /// @dev You must not set element 0xffffffff to true
    mapping(bytes4 => bool) internal supportedInterfaces;

    /// @dev Constructor that adds ERC165 as a supported interface
    constructor() internal {
        supportedInterfaces[ERC165ID()] = true;
    }

    /// @notice Query if a contract implements an interface
    /// @param interfaceID The interface identifier, as specified in ERC-165
    /// @dev Interface identification is specified in ERC-165. This function
    ///  uses less than 30,000 gas.
    /// @return `true` if the contract implements `interfaceID` and
    ///  `interfaceID` is not 0xffffffff, `false` otherwise
    function supportsInterface(bytes4 interfaceID) external view returns (bool) {
        return supportedInterfaces[interfaceID];
    }

    /// @dev ID for ERC165 pseudo-introspection
    /// @return ID for ERC165 interface
    // solhint-disable-next-line func-name-mixedcase
    function ERC165ID() public pure returns (bytes4) {
        return this.supportsInterface.selector;
    }
}

contract ERC725 is ERC165 {
    /// @dev Constructor that adds ERC725 as a supported interface
    constructor() internal {
        supportedInterfaces[ERC725ID()] = true;
    }

    /// @dev ID for ERC165 pseudo-introspection
    /// @return ID for ERC725 interface
    // solhint-disable-next-line func-name-mixedcase
    function ERC725ID() public pure returns (bytes4) {
        return (
            this.getKey.selector ^ this.keyHasPurpose.selector ^ this.getKeysByPurpose.selector ^
            this.addKey.selector ^ this.execute.selector ^ this.approve.selector ^ this.removeKey.selector
        );
    }

    // Purpose
    // 1: MANAGEMENT keys, which can manage the identity
    uint256 public constant MANAGEMENT_KEY = 1;
    // 2: ACTION keys, which perform actions in this identities name (signing, logins, transactions, etc.)
    uint256 public constant ACTION_KEY = 2;
    // 3: CLAIM signer keys, used to sign claims on other identities which need to be revokable.
    uint256 public constant CLAIM_SIGNER_KEY = 3;
    // 4: ENCRYPTION keys, used to encrypt data e.g. hold in claims.
    uint256 public constant ENCRYPTION_KEY = 4;
    // 5: ASSIST keys, used to authenticate.
    uint256 public constant ASSIST_KEY = 5;
    // 6: DELEGATE keys, used to encrypt data e.g. hold in claims.
    uint256 public constant DELEGATE_KEY = 6;
    // 7: RESTORE keys, used to encrypt data e.g. hold in claims.
    uint256 public constant RESTORE_KEY = 7;
    // 8: CUSTOM keys, used to encrypt data e.g. hold in claims.
    uint256 public constant CUSTOM_KEY = 8;
    
    // KeyType
    uint256 public constant ECDSA_TYPE = 1;
    // https://medium.com/@alexberegszaszi/lets-bring-the-70s-to-ethereum-48daa16a4b51
    uint256 public constant RSA_TYPE = 2;

    // Events
    event KeyAdded(bytes32 indexed key, uint256 indexed purpose, uint256 indexed keyType);
    event KeyRemoved(bytes32 indexed key, uint256 indexed purpose, uint256 indexed keyType);
    event ExecutionRequested(uint256 indexed executionId, address indexed to, uint256 indexed value, bytes data);
    event Executed(uint256 indexed executionId, address indexed to, uint256 indexed value, bytes data);
    event Approved(uint256 indexed executionId, bool approved);
    // TODO: Extra event, not part of the standard
    event ExecutionFailed(uint256 indexed executionId, address indexed to, uint256 indexed value, bytes data);

    // Functions
    function getKey(bytes32 _key) public view returns(uint256[] purposes, uint256 keyType, bytes32 key);
    function keyHasPurpose(bytes32 _key, uint256 purpose) public view returns(bool exists);
    function getKeysByPurpose(uint256 _purpose) public view returns(bytes32[] keys);
    function addKey(bytes32 _key, uint256 _purpose, uint256 _keyType) public returns (bool success);
    function execute(address _to, uint256 _value, bytes _data) public returns (uint256 executionId);
    function approve(uint256 _id, bool _approve) public returns (bool success);
    function removeKey(bytes32 _key, uint256 _purpose) public returns (bool success);
}

contract ERC735 is ERC165 {
    /// @dev Constructor that adds ERC735 as a supported interface
    constructor() internal {
        supportedInterfaces[ERC735ID()] = true;
    }

    /// @dev ID for ERC165 pseudo-introspection
    /// @return ID for ERC725 interface
    // solhint-disable-next-line func-name-mixedcase
    function ERC735ID() public pure returns (bytes4) {
        return (
            this.getClaim.selector ^ this.getClaimIdsByType.selector ^
            this.addClaim.selector ^ this.removeClaim.selector
        );
    }
    
    // Topic
    //uint256 public constant BIOMETRIC_TOPIC = 1; // you're a person and not a business
    uint256 public constant METAID_TOPIC = 1; // TODO: real name, business name, nick name, brand name, alias, etc.
    uint256 public constant RESIDENCE_TOPIC = 2; // you have a physical address or reference point
    uint256 public constant REGISTRY_TOPIC = 3;
    uint256 public constant PROFILE_TOPIC = 4; // TODO: social media profiles, blogs, etc.
    uint256 public constant LABEL_TOPIC = 5; // TODO: real name, business name, nick name, brand name, alias, etc.

    // Scheme
    uint256 public constant ECDSA_SCHEME = 1;
    // https://medium.com/@alexberegszaszi/lets-bring-the-70s-to-ethereum-48daa16a4b51
    uint256 public constant RSA_SCHEME = 2;
    // 3 is contract verification, where the data will be call data, and the issuer a contract address to call
    uint256 public constant CONTRACT_SCHEME = 3;

    // Events
    event ClaimRequested(uint256 indexed claimRequestId, uint256 indexed topic, uint256 scheme, address indexed issuer, bytes signature, bytes data, string uri);
    event ClaimAdded(bytes32 indexed claimId, uint256 indexed topic, uint256 scheme, address indexed issuer, bytes signature, bytes data, string uri);
    event ClaimRemoved(bytes32 indexed claimId, uint256 indexed topic, uint256 scheme, address indexed issuer, bytes signature, bytes data, string uri);
    event ClaimChanged(bytes32 indexed claimId, uint256 indexed topic, uint256 scheme, address indexed issuer, bytes signature, bytes data, string uri);

    // Functions
    function getClaim(bytes32 _claimId) public view returns(uint256 topic, uint256 scheme, address issuer, bytes signature, bytes data, string uri);
    function getClaimIdsByType(uint256 _topic) public view returns(bytes32[] claimIds);
    function addClaim(uint256 _topic, uint256 _scheme, address issuer, bytes _signature, bytes _data, string _uri) public returns (uint256 claimRequestId);
    function removeClaim(bytes32 _claimId) public returns (bool success);
}

contract IAchievement {
    function mint(address _to, uint256 _tokenId, string _uri) public returns (bool);
    function burn(uint256 _tokenId) public returns (bool);
    
}

contract IAttestationAgencyRegistry {
    function isRegistered(address _addr) view public returns(uint256);

}

contract IIdentityManager {
    function isMetaId(address _addr) public view returns(bool);
}

library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
    if (a == 0) {
      return 0;
    }
    c = a * b;
    assert(c / a == b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    // uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
    return a / b;
  }

  /**
  * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
    c = a + b;
    assert(c >= a);
    return c;
  }
}

contract Ownable {
  address public owner;


  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  function Ownable() public {
    owner = msg.sender;
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}

contract Registry is Ownable{
    
    mapping(bytes32=>address) public contracts;
    mapping(bytes32=>mapping(address=>bool)) public permissions;

    event SetContractDomain(address setter, bytes32 indexed name, address indexed addr);
    event SetPermission(bytes32 indexed _contract, address indexed granted, bool status);


    /**
    * @dev Function to set contract(can be general address) domain
    * Only owner can use this function
    * @param _name name
    * @param _addr address
    * @return A boolean that indicates if the operation was successful.
    */
    function setContractDomain(bytes32 _name, address _addr) onlyOwner public returns (bool success){
        require(_addr != address(0x0));
        contracts[_name] = _addr;

        emit SetContractDomain(msg.sender, _name, _addr);

        return true;
        //TODO should decide whether to set 0x00 to destoryed contract or not
        

    }
    /**
    * @dev Function to get contract(can be general address) address
    * Anyone can use this function
    * @param _name _name
    * @return An address of the _name
    */
    function getContractAddress(bytes32 _name) public view returns(address addr) {
        require(contracts[_name] != address(0x0));
        return contracts[_name];
    }
    /**
    * @dev Function to set permission on contract
    * contract using modifier 'permissioned' references mapping variable 'permissions'
    * Only owner can use this function
    * @param _contract contract name
    * @param _granted granted address
    * @param _status true = can use, false = cannot use. default is false
    * @return A boolean that indicates if the operation was successful.
    */
    function setPermission(bytes32 _contract, address _granted, bool _status) onlyOwner public returns(bool success) {
        require(_granted != address(0x0));
        permissions[_contract][_granted] = _status;

        emit SetPermission(_contract, _granted, _status);
        
        return true;
    }

    /**
    * @dev Function to get permission on contract
    * contract using modifier 'permissioned' references mapping variable 'permissions'
    * @param _contract contract name
    * @param _granted granted address
    * @return permission result
    */
    function getPermission(bytes32 _contract, address _granted) public view returns(bool found) {
        return permissions[_contract][_granted];
    }
    
}

contract RegistryUser is Ownable {
    
    Registry public REG;
    bytes32 public THIS_NAME;

    /**
     * @dev Function to set registry address. Contract that wants to use registry should setRegistry first.
     * @param _addr address of registry
     * @return A boolean that indicates if the operation was successful.
     */
    function setRegistry(address _addr) public onlyOwner {
        REG = Registry(_addr);
    }
    
    modifier permissioned() {
        require(isPermitted(msg.sender));
        _;
    }

    /**
     * @dev Function to check the permission
     * @param _addr address of sender to check the permission
     * @return A boolean that indicates if the operation was successful.
     */
    function isPermitted(address _addr) public view returns(bool found) {
        return REG.getPermission(THIS_NAME, _addr);
    }
    
}

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
     * @param _topics registered topics
     * @param _issuers issuers for each topic
     * @param _title title
     * @param _achievementExplanation achievement explanation
     * @param _reward reward in meta when user request acievement
     * @param _uri basically used for ipfs id or something
     * @return A boolean that indicates if the operation was successful.
     */
    function createAchievement(uint256[] _topics, address[] _issuers, bytes32 _title, bytes32 _achievementExplanation, uint256 _reward, string _uri) onlyAttestationAgency public payable returns (bool success) {

        //check if achievement is already registered
        bytes32 achievementId = getAchievementId(msg.sender, _topics, _issuers);
        require(achievements[achievementId].id == 0);

        //check staking amount used for reward
        require(msg.value >= minimumDeposit);

        //topics should be registered already
        TopicRegistry topicRegistry = TopicRegistry(REG.getContractAddress("TopicRegistry"));
        for(uint256 i=0;i<_topics.length;i++){
            require(topicRegistry.isRegistered(_topics[i]), "topic not registered");
        }
        
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
    function registerTopicBySystem(uint256 _id, bytes32 _title, bytes32 _explanation) permissioned public returns (uint256 topicId) {

        // check topic doesn't exist
        require(topics[_id].id == 0 && _id < RESERVED_TOPICS);

        Topic memory t;
        t.id = _id;
        t.title = _title;
        t.issuer = msg.sender;
        t.explanation = _explanation;
        t.createdAt = now;
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
        require(ar.isRegistered(msg.sender) != 0 || isPermitted(msg.sender)); //Only Attestation Agency or permissioned can register topic

        Topic memory t;
        t.id = total;
        t.issuer = msg.sender;
        t.title = _title;
        t.explanation = _explanation;
        t.createdAt = now;
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
        
        require(topics[_id].issuer == msg.sender);

        topics[_id].explanation = _explanation;

        emit UpdateTopic(_id, msg.sender , _explanation);

        return true;

    }


    function isRegistered(uint256 _id) view public returns (bool found) {
        return isTopicRegistered[_id];
    }


    function getTotal() view public returns (uint256 length) {
        return total;
    }
    
    function getTopic(uint256 _id) view public returns(address issuer, bytes32 title, bytes32 explanation, uint256 createdAt){
        return (topics[_id].issuer, topics[_id].title, topics[_id].explanation, topics[_id].createdAt);
    }

    /**
     * @dev Batch Read functino for topic
     * @param _from from
     * @param _to to
     * @return topic data
     */
    function getTopicFromTo(uint256 _from, uint256 _to) view public returns(address[] addrs, bytes32[] titles, bytes32[] explans, uint256[] createds){
        require(_to>_from);
        address[] memory saddrs = new address[](_to-_from+1);
        bytes32[] memory sexplans = new bytes32[](_to-_from+1);
        uint256[] memory screateds = new uint256[](_to-_from+1);
        bytes32[] memory stitles = new bytes32[](_to-_from+1);

        for(uint256 i=_from;i<=_to;i++){
            saddrs[i-_from] = topics[i].issuer;
            sexplans[i-_from] = topics[i].explanation;
            screateds[i-_from] = topics[i].createdAt;
            stitles[i-_from] = topics[i].title;
        }

        return (saddrs, stitles, sexplans, screateds);
    }

}

