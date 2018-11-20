pragma solidity ^0.4.24;

/**
 * @title MetaIdentityUsingLib
 * @dev Interface for MetaIdentityUsingLib
 */
contract MetaIdentityUsingLib {
    // Line All the MetaIdentity variables up.
    // For delegate call, contract storage layout must be same.
    // Line up order is following the solidity inheritance logic(python like)
    
    //ERC165
    mapping(bytes4 => bool) internal supportedInterfaces;


    //KeyBase

    //uint256 public constant MANAGEMENT_KEY = 1;

    // For multi-sig
    uint256 public managementThreshold = 1;
    uint256 public actionThreshold = 1;

    // Key storage
    using KeyStore for KeyStore.Keys;
    KeyStore.Keys internal allKeys;
    
    // Pausable
    bool public paused = false;

    // ClaimManager

    bytes constant internal ETH_PREFIX = "\x19Ethereum Signed Message:\n32";

    struct Claim {
        uint256 topic;
        uint256 scheme;
        address issuer; // msg.sender
        bytes signature; // this.address + topic + data
        bytes data;
        string uri;
    }

    mapping(bytes32 => Claim) internal claims;
    mapping(uint256 => bytes32[]) internal claimsByTopic;
    uint256 public numClaims;

    // MultiSig

    uint256 public nonce = 1;

    struct Execution {
        address to;
        uint256 value;
        bytes data;
        uint256 needsApprove;
    }

    mapping (uint256 => Execution) public execution;
    mapping (uint256 => address[]) public approved;


    //Proxy Only
    address internal libImplementation;


    function setImplementation(address _newImple) public returns (bool) {
        libImplementation = _newImple;
        return true;
    }

    function implementation() public view returns (address) {
        return libImplementation;
    }

    function getNonceUsingLib() public view returns(uint256 _nonce) {
        return nonce;
    }
    function getNonceUsingLib2() public view returns(uint256) {
        return nonce;
    }
    function getNumClaimsUsingLib() public view returns(uint256 _num) {
        return numClaims;
    }
    function setNumClaimsUsingLib(uint256 num) public returns(bool) {
        numClaims = num;
    }
    /**
    * @dev Tells the type of proxy (EIP 897)
    * @return Type of proxy, 2 for upgradeable proxy
    */
    function proxyType() public pure returns (uint256 proxyTypeId) {
        return 2;
    }
    

    /**
     * @dev Fallback function for delegate call. This function will return whatever the implementaion call returns
     */
    function () payable public {
        address _impl = implementation();
        require(_impl != address(0));

        assembly {
            let ptr := mload(0x40)
            calldatacopy(ptr, 0, calldatasize)

            let result := delegatecall(gas, _impl, ptr, calldatasize, 0, 0)
            let size := returndatasize
            returndatacopy(ptr, 0, size)

            switch result
            case 0 { revert(ptr, size) }
            default { return(ptr, size) }

        }
    }
}

library KeyStore {
    struct Key {
        uint256[] purposes; //e.g., MANAGEMENT_KEY = 1, ACTION_KEY = 2, etc.
        uint256 keyType; // e.g. 1 = ECDSA, 2 = RSA, etc.
        bytes32 key; // for non-hex and long keys, its the Keccak256 hash of the key
        mapping(address=>mapping(bytes4=>bool)) func;
    }

    struct Keys {
        mapping (bytes32 => Key) keyData;
        mapping (uint256 => bytes32[]) keysByPurpose;
        uint numKeys;
    }

    /// @dev Find a key + purpose tuple
    /// @param key Key bytes to find
    /// @param purpose Purpose to find
    /// @return `true` if key + purpose tuple if found
    function find(Keys storage self, bytes32 key, uint256 purpose)
        internal
        view
        returns (bool found)
    {
        Key memory k = self.keyData[key];
        if (k.key == 0) {
            return false;
        }
        for (uint i = 0; i < k.purposes.length; i++) {
            if (k.purposes[i] == purpose) {
                found = true;
                return;
            }
        }
    }

    function isExist(Keys storage self, bytes32 key)
        internal
        view
        returns (bool found)
    {
        Key memory k = self.keyData[key];
        return (k.key != 0);
    }

    /// @dev Add a Key
    /// @param key Key bytes to add
    /// @param purpose Purpose to add
    /// @param keyType Key type to add
    function add(Keys storage self, bytes32 key, uint256 purpose, uint256 keyType)
        internal
    {
        Key storage k = self.keyData[key];
        k.purposes.push(purpose);
        if (k.key == 0) {
            k.key = key;
            k.keyType = keyType;
        }
        self.keysByPurpose[purpose].push(key);
        self.numKeys++;
    }

    /// @dev Remove Key
    /// @param key Key bytes to remove
    /// @param purpose Purpose to remove
    /// @return Key type of the key that was removed
    function remove(Keys storage self, bytes32 key, uint256 purpose)
        internal
        returns (uint256 keyType)
    {
        keyType = self.keyData[key].keyType;

        uint256[] storage p = self.keyData[key].purposes;
        // Delete purpose from keyData
        for (uint i = 0; i < p.length; i++) {
            if (p[i] == purpose) {
                p[i] = p[p.length - 1];
                delete p[p.length - 1];
                p.length--;
                self.numKeys--;
                break;
            }
        }
        // No more purposes
        if (p.length == 0) {
            delete self.keyData[key];
        }

        // Delete key from keysByPurpose
        bytes32[] storage k = self.keysByPurpose[purpose];
        for (i = 0; i < k.length; i++) {
            if (k[i] == key) {
                k[i] = k[k.length - 1];
                delete k[k.length - 1];
                k.length--;
            }
        }
    }

    /// @dev Set function that the specific key can excute
    /// @param key Key to use
    /// @param to smart contract address at which this key can be used
    /// @param func function to use
    /// @param executable is executable
    function setFunc(Keys storage self, bytes32 key, address to, bytes4 func, bool executable)
        internal returns (bool set)
    {
        Key storage k = self.keyData[key];
        k.func[to][func] = executable;
        
        return executable;
    }
}