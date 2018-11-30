pragma solidity ^0.4.13;

contract IAttestationAgencyRegistry {
    function isRegistered(address _addr) view public returns(uint256);

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

contract Registry is Ownable {
    
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
    function setContractDomain(bytes32 _name, address _addr) public onlyOwner returns (bool success) {
        require(_addr != address(0x0), "address should be non-zero");
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
        require(contracts[_name] != address(0x0), "address should be non-zero");
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
    function setPermission(bytes32 _contract, address _granted, bool _status) public onlyOwner returns(bool success) {
        require(_granted != address(0x0), "address should be non-zero");
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
        require(isPermitted(msg.sender), "No Permission");
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
        require(_to >= _from, "from to mismatch");
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

