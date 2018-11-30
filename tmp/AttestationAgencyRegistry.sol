pragma solidity ^0.4.13;

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

contract AttestationAgencyRegistry is RegistryUser {
    
    struct AttestationAgency {
        address addr;
        bytes32 title;
        bytes32 explanation;
        uint256 createdAt;
        // code for 
        // bool type isEnterprise;
         
    }
    uint256 public attestationAgencyNum;

    mapping(uint256=>AttestationAgency) public attestationAgencies;
    mapping(address=>uint256) public isAAregistered;
    
    event RegisterAttestationAgency(address indexed aa, bytes32 indexed title, bytes32 explanation);
    event UpdateAttestationAgency(address indexed aa, bytes32 indexed title, bytes32 explanation);


    /**
     * @dev Metadium SelfSovereign address is used to self claim.
     */
    constructor() public {
        THIS_NAME = "AttestationAgencyRegistry";
        attestationAgencyNum = 1;

        attestationAgencies[0].addr = 0xFFfFfFffFFfffFFfFFfFFFFFffFFFffffFfFFFfF;
        attestationAgencies[0].title = "Metadium SelfSovereign";
        attestationAgencies[0].explanation = "Metadium SelfSovereign";
        attestationAgencies[0].createdAt = block.timestamp;
    }

    /**
     * @dev Register Attestation Agency
     * @param _addr address to register
     * @param _title title
     * @param _explanation explanation
     * @return A boolean that indicates if the operation was successful.
     */
    function registerAttestationAgency(address _addr, bytes32 _title, bytes32 _explanation) public permissioned returns (bool success) {
        require(isAAregistered[_addr] == 0, "zero address");
        
        attestationAgencies[attestationAgencyNum].addr = _addr;
        attestationAgencies[attestationAgencyNum].title = _title;
        attestationAgencies[attestationAgencyNum].explanation = _explanation;
        attestationAgencies[attestationAgencyNum].createdAt = block.timestamp;

        isAAregistered[_addr] = attestationAgencyNum;

        attestationAgencyNum++;

        emit RegisterAttestationAgency(_addr, _title, _explanation);

        return true;
    }   

    /**
     * @dev Update Attestation Agency
     * @param _addr address to register
     * @param _title title
     * @param _explanation explanation
     * @return A boolean that indicates if the operation was successful.
     */
    function updateAttestationAgency(address _addr, bytes32 _title, bytes32 _explanation) public permissioned returns (bool success) {
        uint256 _num = isAAregistered[_addr];
        require(_num != 0, "number should non-zero");
        
        attestationAgencies[_num].title = _title;
        attestationAgencies[_num].explanation = _explanation;
        attestationAgencies[_num].createdAt = block.timestamp;

        emit UpdateAttestationAgency(_addr, _title, _explanation);

        return true;

    }

    function isRegistered(address _addr) public view returns(uint256 found) {
        return isAAregistered[_addr];
    }

    function getAttestationAgencySingle(uint256 _num) public view returns(address addr, bytes32 title, bytes32 explanation, uint256 createdAt) {
        return (
            attestationAgencies[_num].addr,
            attestationAgencies[_num].title,
            attestationAgencies[_num].explanation,
            attestationAgencies[_num].createdAt
        );
    }

    function getAttestationAgenciesFromTo(uint256 _from, uint256 _to)
    public
    view
    returns(address[] addrs, bytes32[] titles, bytes32[] descs, uint256[] createds)
    {
        
        require(_to<attestationAgencyNum && _from <= _to, "from to mismatch");
        
        address[] memory saddrs = new address[](_to-_from+1);
        bytes32[] memory sdescs = new bytes32[](_to-_from+1);
        bytes32[] memory stitles = new bytes32[](_to-_from+1);
        uint256[] memory screateds = new uint256[](_to-_from+1);

        for (uint256 i = _from;i<=_to;i++) {
            saddrs[i-_from] = attestationAgencies[i].addr;
            sdescs[i-_from] = attestationAgencies[i].explanation;
            stitles[i-_from] = attestationAgencies[i].title;
            screateds[i-_from] = attestationAgencies[i].createdAt;
        }

        return (saddrs, stitles, sdescs, screateds);
    } 
    

}

