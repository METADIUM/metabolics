pragma solidity ^0.4.13;

library ECDSA {

  /**
   * @dev Recover signer address from a message by using their signature
   * @param hash bytes32 message, the hash is the signed message. What is recovered is the signer address.
   * @param signature bytes signature, the signature is generated using web3.eth.sign()
   */
  function recover(bytes32 hash, bytes signature)
    internal
    pure
    returns (address)
  {
    bytes32 r;
    bytes32 s;
    uint8 v;

    // Check the signature length
    if (signature.length != 65) {
      return (address(0));
    }

    // Divide the signature in r, s and v variables
    // ecrecover takes the signature parameters, and the only way to get them
    // currently is to use assembly.
    // solium-disable-next-line security/no-inline-assembly
    assembly {
      r := mload(add(signature, 0x20))
      s := mload(add(signature, 0x40))
      v := byte(0, mload(add(signature, 0x60)))
    }

    // Version of signature should be 27 or 28, but 0 and 1 are also possible versions
    if (v < 27) {
      v += 27;
    }

    // If the version is correct return the signer address
    if (v != 27 && v != 28) {
      return (address(0));
    } else {
      // solium-disable-next-line arg-overflow
      return ecrecover(hash, v, r, s);
    }
  }

  /**
   * toEthSignedMessageHash
   * @dev prefix a bytes32 value with "\x19Ethereum Signed Message:"
   * and hash the result
   */
  function toEthSignedMessageHash(bytes32 hash)
    internal
    pure
    returns (bytes32)
  {
    // 32 is the length in bytes of hash,
    // enforced by the type signature above
    return keccak256(
      abi.encodePacked("\x19Ethereum Signed Message:\n32", hash)
    );
  }
}

library Address {

  /**
   * Returns whether the target address is a contract
   * @dev This function will return false if invoked during the constructor of a contract,
   * as the code is not actually created until after the constructor finishes.
   * @param account address of the account to check
   * @return whether the target address is a contract
   */
  function isContract(address account) internal view returns (bool) {
    uint256 size;
    // XXX Currently there is no better way to check if there is a contract in an address
    // than to check the size of the code at that address.
    // See https://ethereum.stackexchange.com/a/14016/36603
    // for more details about how this works.
    // TODO Check this again before the Serenity release, because all addresses will be
    // contracts then.
    // solium-disable-next-line security/no-inline-assembly
    assembly { size := extcodesize(account) }
    return size > 0;
  }

}

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

library ERC165Query {
    bytes4 constant internal INVALID_ID = 0xffffffff;
    bytes4 constant internal ERC165_ID = 0x01ffc9a7;

    /// @dev Checks if a given contract address implement a given interface using
    ///  pseudo-introspection (ERC165)
    /// @param _contract Smart contract to check
    /// @param _interfaceId Interface to check
    /// @return `true` if the contract implements both ERC165 and `_interfaceId`
    function doesContractImplementInterface(address _contract, bytes4 _interfaceId)
        internal
        view
        returns (bool)
    {
        uint256 success;
        uint256 result;

        (success, result) = noThrowCall(_contract, ERC165_ID);
        if ((success == 0) || (result == 0)) {
            return false;
        }

        (success, result) = noThrowCall(_contract, INVALID_ID);
        if ((success == 0) || (result != 0)) {
            return false;
        }

        (success, result) = noThrowCall(_contract, _interfaceId);
        if ((success == 1) && (result == 1)) {
            return true;
        }
        return false;
    }

    /// @dev `Calls supportsInterface(_interfaceId)` on a contract without throwing an error
    /// @param _contract Smart contract to call
    /// @param _interfaceId Interface to call
    /// @return `success` is `true` if the call was successful; `result` is the result of the call
    function noThrowCall(address _contract, bytes4 _interfaceId)
        internal
        view
        returns (uint256 success, uint256 result)
    {
        bytes4 erc165ID = ERC165_ID;

        // solhint-disable-next-line no-inline-assembly
        assembly {
                let x := mload(0x40)               // Find empty storage location using "free memory pointer"
                mstore(x, erc165ID)                // Place signature at begining of empty storage
                mstore(add(x, 0x04), _interfaceId) // Place first argument directly next to signature

                success := staticcall(
                                    30000,         // 30k gas
                                    _contract,     // To addr
                                    x,             // Inputs are stored at location x
                                    0x20,          // Inputs are 32 bytes long
                                    x,             // Store output over input (saves space)
                                    0x20)          // Outputs are 32 bytes long

                result := mload(x)                 // Load the result
        }
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
    event ClaimRequested(
        uint256 indexed claimRequestId,
        uint256 indexed topic,
        uint256 scheme,
        address indexed issuer,
        bytes signature,
        bytes data,
        string uri
    );

    event ClaimAdded(
        bytes32 indexed claimId,
        uint256 indexed topic,
        uint256 scheme,
        address indexed issuer,
        bytes signature,
        bytes data,
        string uri
    );

    event ClaimRemoved(
        bytes32 indexed claimId,
        uint256 indexed topic,
        uint256 scheme,
        address indexed issuer,
        bytes signature,
        bytes data,
        string uri
    );

    event ClaimChanged(
        bytes32 indexed claimId,
        uint256 indexed topic,
        uint256 scheme,
        address indexed issuer,
        bytes signature,
        bytes data,
        string uri
    );

    // Functions
    function getClaim(bytes32 _claimId) public view returns (
        uint256 topic,
        uint256 scheme,
        address issuer,
        bytes signature,
        bytes data,
        string uri
        );

    function getClaimIdsByType(uint256 _topic) public view returns(bytes32[] claimIds);

    function addClaim(
        uint256 _topic,
        uint256 _scheme,
        address issuer,
        bytes _signature,
        bytes _data,
        string _uri
        ) public returns (uint256 claimRequestId);

    function removeClaim(bytes32 _claimId) public returns (bool success);
}

contract KeyBase {
    uint256 public constant MANAGEMENT_KEY = 1;

    // For multi-sig
    uint256 public managementThreshold = 1;
    uint256 public actionThreshold = 1;

    // Key storage
    using KeyStore for KeyStore.Keys;
    KeyStore.Keys internal allKeys;

    /// @dev Number of keys managed by the contract
    /// @return Unsigned integer number of keys
    function numKeys()
        external
        view
        returns (uint)
    {
        return allKeys.numKeys;
    }

    /// @dev Convert an Ethereum address (20 bytes) to an ERC725 key (32 bytes)
    /// @dev It's just a simple typecast, but it's especially useful in tests
    function addrToKey(address addr)
        public
        pure
        returns (bytes32)
    {
        return bytes32(addr);
    }

    /// @dev Checks if sender is either the identity contract or a MANAGEMENT_KEY
    /// @dev If the multi-sig threshold for MANAGEMENT_KEY if >1, it will throw an error
    /// @return `true` if sender is either identity contract or a MANAGEMENT_KEY
    function _managementOrSelf()
        internal
        view
        returns (bool found)
    {
        if (msg.sender == address(this)) {
            // Identity contract itself
            return true;
        }
        // Only works with 1 key threshold, otherwise need multi-sig
        require(managementThreshold == 1);
        return allKeys.find(addrToKey(msg.sender), MANAGEMENT_KEY);
    }

    /// @dev Modifier that only allows keys of purpose 1, or the identity itself
    modifier onlyManagementOrSelf {
        require(_managementOrSelf());
        _;
    }
}

contract Destructible is KeyBase {
    /// @dev Transfers the current balance and terminates the contract
    /// @param _recipient All funds in contract will be sent to this recipient
    function destroyAndSend(address _recipient)
        public
        onlyManagementOrSelf
    {
        require(_recipient != address(0));
        selfdestruct(_recipient);
    }
}

contract KeyGetters is KeyBase {
    /// @dev Find the key data, if held by the identity
    /// @param _key Key bytes to find
    /// @return `(purposes, keyType, key)` tuple if the key exists
    function getKey(
        bytes32 _key
    )
        public
        view
        returns(uint256[] purposes, uint256 keyType, bytes32 key)
    {
        KeyStore.Key memory k = allKeys.keyData[_key];
        purposes = k.purposes;
        keyType = k.keyType;
        key = k.key;
    }

    /// @dev Find if a key has is present and has the given purpose
    /// @param _key Key bytes to find
    /// @param purpose Purpose to find
    /// @return Boolean indicating whether the key exists or not
    function keyHasPurpose(
        bytes32 _key,
        uint256 purpose
    )
        public
        view
        returns(bool exists)
    {
        return allKeys.find(_key, purpose);
    }

    /// @dev Find all the keys held by this identity for a given purpose
    /// @param _purpose Purpose to find
    /// @return Array with key bytes for that purpose (empty if none)
    function getKeysByPurpose(uint256 _purpose)
        public
        view
        returns(bytes32[] keys)
    {
        return allKeys.keysByPurpose[_purpose];
    }
    
    function keyCanExecute(bytes32 _key, address _to, bytes4 _func)
        public
        view
        returns(bool executable)
    {
        //KeyStore.Key storage k = allKeys.keyData[_key];
        //return k.func[_to][_func];
        return allKeys.keyData[_key].func[_to][_func];
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

    function numKeysByPurpose(Keys storage self, uint256 purpose) internal view returns (uint) {
        return self.keysByPurpose[purpose].length;
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

contract Pausable is KeyBase {
    event LogPause();
    event LogUnpause();

    bool public paused = false;

    /// @dev Modifier to make a function callable only when the contract is not paused
    modifier whenNotPaused() {
        require(!paused);
        _;
    }

    /// @dev Modifier to make a function callable only when the contract is paused
    modifier whenPaused() {
        require(paused);
        _;
    }

    /// @dev called by a MANAGEMENT_KEY or the identity itself to pause, triggers stopped state
    function pause()
        public
        onlyManagementOrSelf
        whenNotPaused
    {
        paused = true;
        emit LogPause();
    }

      /// @dev called by a MANAGEMENT_KEY or the identity itself to unpause, returns to normal state
    function unpause()
        public
        onlyManagementOrSelf
        whenPaused
    {
        paused = false;
        emit LogUnpause();
    }
}

contract ClaimManager is Pausable, ERC725, ERC735 {
    using ECDSA for bytes32;
    using ERC165Query for address;

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

    function getNumClaims() public view returns (uint256 num) {
        return numClaims;
    }
    
    /// @dev Requests the ADDITION or the CHANGE of a claim from an issuer.
    ///  Claims can requested to be added by anybody, including the claim holder itself (self issued).
    /// @param _topic Type of claim
    /// @param _scheme Scheme used for the signatures
    /// @param issuer Address of issuer
    /// @param _signature The actual signature
    /// @param _data The data that was signed
    /// @param _uri The location of the claim
    /// @return claimRequestId COULD be send to the approve function, to approve or reject this claim
    function addClaim(
        uint256 _topic,
        uint256 _scheme,
        address issuer,
        bytes _signature,
        bytes _data,
        string _uri
    )
        public
        whenNotPaused
        returns (uint256 claimRequestId)
    {
        // Check signature
        require(_validSignature(_topic, _scheme, issuer, _signature, _data));
        // Check we can perform action
        bool noApproval = _managementOrSelf();

        if (!noApproval) {
            // SHOULD be approved or rejected by n of m approve calls from keys of purpose 1
            claimRequestId = this.execute(address(this), 0, msg.data);
            emit ClaimRequested(claimRequestId, _topic, _scheme, issuer, _signature, _data, _uri);
            return;
        }

        bytes32 claimId = getClaimId(issuer, _topic);
        if (claims[claimId].issuer == address(0)) {
            _addClaim(claimId, _topic, _scheme, issuer, _signature, _data, _uri);
        } else {
            // Existing claim
            Claim storage c = claims[claimId];
            c.scheme = _scheme;
            c.signature = _signature;
            c.data = _data;
            c.uri = _uri;
            // You can't change issuer or topic without affecting the claimId, so we
            // don't need to update those two fields
            emit ClaimChanged(claimId, _topic, _scheme, issuer, _signature, _data, _uri);
        }
    }

    function addClaimByProxy(
        uint256 _topic,
        uint256 _scheme,
        address issuer,
        bytes _signature,
        bytes _data,
        string _uri,
        bytes _idSignature
    )
        public
        whenNotPaused
        returns (bool success)
    {
        // Check signature
        require(_validSignature(_topic, _scheme, issuer, _signature, _data));
        
        // Check idSignature
        // Check if management key signed this transaction data
        address signedBy = getSignatureAddress(
            keccak256(abi.encodePacked(_topic, _scheme, issuer, _signature, _data, _uri)),
            _idSignature);
        
        require(allKeys.find(addrToKey(signedBy), MANAGEMENT_KEY));

        bytes32 claimId = getClaimId(issuer, _topic);
        if (claims[claimId].issuer == address(0)) {
            _addClaim(claimId, _topic, _scheme, issuer, _signature, _data, _uri);
        } else {
            // Existing claim
            Claim storage c = claims[claimId];
            c.scheme = _scheme;
            c.signature = _signature;
            c.data = _data;
            c.uri = _uri;
            // You can't change issuer or topic without affecting the claimId, so we
            // don't need to update those two fields
            emit ClaimChanged(claimId, _topic, _scheme, issuer, _signature, _data, _uri);
        }

        return true;
    }

    /// @dev Removes a claim. Can only be removed by the claim issuer, or the claim holder itself.
    /// @param _claimId Claim ID to remove
    /// @return `true` if the claim is found and removed
    function removeClaim(bytes32 _claimId)
        public
        whenNotPaused
        onlyManagementOrSelfOrIssuer(_claimId)
        returns (bool success)
    {
        Claim memory c = claims[_claimId];
        // Must exist
        require(c.issuer != address(0));
        // Remove from mapping
        delete claims[_claimId];
        // Remove from type array
        bytes32[] storage topics = claimsByTopic[c.topic];
        for (uint i = 0; i < topics.length; i++) {
            if (topics[i] == _claimId) {
                topics[i] = topics[topics.length - 1];
                delete topics[topics.length - 1];
                topics.length--;
                break;
            }
        }
        // Decrement
        numClaims--;
        // Event
        emit ClaimRemoved(_claimId, c.topic, c.scheme, c.issuer, c.signature, c.data, c.uri);
        return true;
    }

    /// @dev Returns whether the claim exists
    /// @return true if claim exist
    function isClaimExist(bytes32 _claimId) public view returns (bool) {
        return (claims[_claimId].issuer != address(0));   
    }

    /// @dev Returns a claim by ID
    /// @return (topic, scheme, issuer, signature, data, uri) tuple with claim data
    function getClaim(bytes32 _claimId)
        public
        view
        returns (
        uint256 topic,
        uint256 scheme,
        address issuer,
        bytes signature,
        bytes data,
        string uri
        )
    {
        Claim memory c = claims[_claimId];
        require(c.issuer != address(0));
        topic = c.topic;
        scheme = c.scheme;
        issuer = c.issuer;
        signature = c.signature;
        data = c.data;
        uri = c.uri;
    }

    /// @dev Returns claims by type
    /// @param _topic Type of claims to return
    /// @return array of claim IDs
    function getClaimIdsByType(uint256 _topic)
        public
        view
        returns(bytes32[] claimIds)
    {
        claimIds = claimsByTopic[_topic];
    }

    /// @dev Refresh a given claim. If no longer valid, it will remove it
    /// @param _claimId Claim ID to refresh
    /// @return `true` if claim is still valid, `false` if it was invalid and removed
    function refreshClaim(bytes32 _claimId)
        public
        whenNotPaused
        onlyManagementOrSelfOrIssuer(_claimId)
        returns (bool)
    {
        // Must exist
        Claim memory c = claims[_claimId];
        require(c.issuer != address(0));
        // Check claim is still valid
        if (!_validSignature(c.topic, c.scheme, c.issuer, c.signature, c.data)) {
            // Remove claim
            removeClaim(_claimId);
            return false;
        }

        // Return true if claim is still valid
        return true;
    }

    /// @dev Generate claim ID. Especially useful in tests
    /// @param issuer Address of issuer
    /// @param topic Claim topic
    /// @return Claim ID hash
    function getClaimId(address issuer, uint256 topic)
        public
        pure
        returns (bytes32)
    {
        // TODO: Doesn't allow multiple claims from the same issuer with the same type
        // This is particularly inconvenient for self-claims (e.g. self-claim multiple labels)
        return keccak256(abi.encodePacked(issuer, topic));
    }

    /// @dev Generate claim to sign. Especially useful in tests
    /// @param subject Address about which we're making a claim
    /// @param topic Claim topic
    /// @param data Data for the claim
    /// @return Hash to be signed by claim issuer
    function claimToSign(address subject, uint256 topic, bytes data)
        public
        pure
        returns (bytes32)
    {
        return keccak256(abi.encodePacked(subject, topic, data));
    }

    /// @dev Recover address used to sign a claim
    /// @param toSign Hash to be signed, potentially generated with `claimToSign`
    /// @param signature Signature data i.e. signed hash
    /// @return address recovered from `signature` which signed the `toSign` hash
    function getSignatureAddress(bytes32 toSign, bytes signature)
        public
        pure
        returns (address)
    {
        return keccak256(abi.encodePacked(ETH_PREFIX, toSign)).recover(signature);
    }

    /// @dev Checks if a given claim is valid
    /// @param _topic Type of claim
    /// @param _scheme Scheme used for the signatures
    /// @param issuer Address of issuer
    /// @param _signature The actual signature
    /// @param _data The data that was signed
    /// @return `false` if the signature is invalid or if the scheme is not implemented
    function _validSignature(
        uint256 _topic,
        uint256 _scheme,
        address issuer,
        bytes _signature,
        bytes _data
    )
        internal
        view
        returns (bool)
    {
        if (_scheme == ECDSA_SCHEME) {
            address signedBy;

            signedBy = getSignatureAddress(claimToSign(address(this), _topic, _data), _signature);
            if (issuer == signedBy) {
                // Issuer signed the signature
                return true;
            } else if (issuer == address(this)) {
                return allKeys.find(addrToKey(signedBy), CLAIM_SIGNER_KEY);
            } else if (issuer.doesContractImplementInterface(ERC725ID())) {
                // Issuer is an Identity contract
                // It should hold the key with which the above message was signed.
                // If the key is not present anymore, the claim SHOULD be treated as invalid.
                return ERC725(issuer).keyHasPurpose(addrToKey(signedBy), CLAIM_SIGNER_KEY);
            }
            // Invalid
            return false;
        } else {
            // Not implemented
            return false;
        }
    }

    /// @dev Modifier that only allows keys of purpose 1, the identity itself, or the issuer or the claim
    modifier onlyManagementOrSelfOrIssuer(bytes32 _claimId) {
        address issuer = claims[_claimId].issuer;
        // Must exist
        require(issuer != 0);

        // Can perform action on claim
        // solhint-disable-next-line no-empty-blocks
        if (_managementOrSelf()) {
            // Valid
        } else if (msg.sender == issuer) {
            // MUST only be done by the issuer of the claim
        } else if (issuer.doesContractImplementInterface(ERC725ID())) {
            // Issuer is another Identity contract, is this an action key?
            require(ERC725(issuer).keyHasPurpose(addrToKey(msg.sender), ACTION_KEY));
        } else {
            // Invalid! Sender is NOT Management or Self or Issuer
            revert();
        }
        _;
    }

    /// @dev Add key data to the identity without checking if it already exists
    /// @param _claimId Claim ID
    /// @param _topic Type of claim
    /// @param _scheme Scheme used for the signatures
    /// @param issuer Address of issuer
    /// @param _signature The actual signature
    /// @param _data The data that was signed
    /// @param _uri The location of the claim
    function _addClaim(
        bytes32 _claimId,
        uint256 _topic,
        uint256 _scheme,
        address issuer,
        bytes _signature,
        bytes _data,
        string _uri
    )
        internal
    {
        // New claim
        claims[_claimId] = Claim(_topic, _scheme, issuer, _signature, _data, _uri);
        claimsByTopic[_topic].push(_claimId);
        //numClaims++;
        numClaims = numClaims + 1;
        emit ClaimAdded(_claimId, _topic, _scheme, issuer, _signature, _data, _uri);
    }

    /// @dev Update the URI of an existing claim without any checks
    /// @param _topic Type of claim
    /// @param issuer Address of issuer
    /// @param _uri The location of the claim
    function _updateClaimUri(
        uint256 _topic,
        address issuer,
        string _uri
    )
    internal
    {
        claims[getClaimId(issuer, _topic)].uri = _uri;
    }
}

contract KeyManager is Pausable, ERC725 {
    using Address for address;

    /// @dev Add key data to the identity if key + purpose tuple doesn't already exist
    /// @param _key Key bytes to add
    /// @param _purpose Purpose to add
    /// @param _keyType Key type to add
    /// @return `true` if key was added, `false` if it already exists
    function addKey(
        bytes32 _key,
        uint256 _purpose,
        uint256 _keyType
    )
        public
        onlyManagementOrSelf
        whenNotPaused
        returns (bool success)
    {
        if (allKeys.find(_key, _purpose)) {
            return false;
        }
        _addKey(_key, _purpose, _keyType);
        return true;
    }

    /// @dev Remove key data from the identity
    /// @param _key Key bytes to remove
    /// @param _purpose Purpose to remove
    /// @return `true` if key was found and removed, `false` if it wasn't found
    function removeKey(
        bytes32 _key,
        uint256 _purpose
    )
        public
        onlyManagementOrSelf
        whenNotPaused
        returns (bool success)
    {
        if (_purpose == MANAGEMENT_KEY) {
            require(managementThreshold < allKeys.numKeysByPurpose(MANAGEMENT_KEY));
        }
        if (!allKeys.find(_key, _purpose)) {
            return false;
        }
        uint256 keyType = allKeys.remove(_key, _purpose);
        emit KeyRemoved(_key, _purpose, keyType);
        return true;
    }

    /// @dev Add key data to the identity if key + purpose tuple doesn't already exist
    /// @param _key Key to use
    /// @param _to smart contract address at which this key can be used
    /// @param _func function to use
    /// @param _executable is executable
    /// @return `true` if key func was set, `false`, if cannot be set
    function setFunc(
        bytes32 _key,
        address _to,
        bytes4 _func,
        bool _executable
    )
        public
        onlyManagementOrSelf
        whenNotPaused
        returns (bool success)
    {
        require(allKeys.isExist(_key));
        require(_to.isContract());
        allKeys.setFunc(_key, _to, _func, _executable);
        return true;
    }

    /// @dev Add key data to the identity without checking if it already exists
    /// @param _key Key bytes to add
    /// @param _purpose Purpose to add
    /// @param _keyType Key type to add
    function _addKey(
        bytes32 _key,
        uint256 _purpose,
        uint256 _keyType
    )
        internal
    {
        allKeys.add(_key, _purpose, _keyType);
        emit KeyAdded(_key, _purpose, _keyType);
    }
}

contract SignatureVerifier {
    using ECDSA for bytes32;

    /// @dev Recover address used to sign a claim
    /// @param toSign Hash to be signed, potentially generated with `claimToSign`
    /// @param signature Signature data i.e. signed hash
    /// @return address recovered from `signature` which signed the `toSign` hash
    function getSignatureAddress(bytes32 toSign, bytes signature)
        public
        pure
        returns (address addr)
    {
        return toSign.toEthSignedMessageHash().recover(signature);
    }
}

contract MultiSig is Pausable, ERC725, SignatureVerifier {
    using ECDSA for bytes32;

    uint256 public nonce = 1;

    struct Execution {
        address to;
        uint256 value;
        bytes data;
        uint256 needsApprove;
    }

    mapping (uint256 => Execution) public execution;
    mapping (uint256 => address[]) public approved;
    
    /// @dev Generate a unique ID for an execution request
    /// @param _to address being called (msg.sender)
    /// @param _value ether being sent (msg.value)
    /// @param _data ABI encoded call data (msg.data)
    function execute(
        address _to,
        uint256 _value,
        bytes _data
    )
        public
        whenNotPaused
        returns (uint256 executionId)
    {
        return preExecute(msg.sender, _to, _value, _data);
    }

    function delegatedExecute(address _to, uint256 _value, bytes _data, uint256 _nonce, bytes _sig)
        public
        whenNotPaused
        returns (uint256 executionId)
    {
        // check nonce
        require(_nonce == nonce, "nonce mismatch");

        // sinature verify
        //TODO : 'this' should be addded
        address signedBy = getSignatureAddress(keccak256(abi.encodePacked(_to, _value, _data, _nonce)), _sig);
        return preExecute(signedBy, _to, _value, _data);
    
    }

    function approve(uint256 _id, bool _approve) public whenNotPaused returns (bool success) {
        return preApprove(msg.sender, _id, _approve);
    }

    function delegatedApprove(uint256 _id, bool _approve, uint256 _nonce, bytes _sig)
        public
        whenNotPaused
        returns (bool success)
    {
        // check nonce
        require(_nonce == nonce, "nonce mismatch");

        // sinature verify
        //TODO : 'this' should be addded
        address signedBy = getSignatureAddress(keccak256(abi.encodePacked(_id, _approve, _nonce)), _sig);
        //return true;
        return preApprove(signedBy, _id, _approve);
    }

    /// @dev Change multi-sig threshold for MANAGEMENT_KEY
    /// @param threshold New threshold to change it to (will throw if 0 or larger than available keys)
    function changeManagementThreshold(uint threshold)
        public
        whenNotPaused
        onlyManagementOrSelf
    {
        require(threshold > 0);
        // Don't lock yourself out
        uint numManagementKeys = getKeysByPurpose(MANAGEMENT_KEY).length;
        require(threshold <= numManagementKeys);
        managementThreshold = threshold;
    }

    /// @dev Change multi-sig threshold for ACTION_KEY
    /// @param threshold New threshold to change it to (will throw if 0 or larger than available keys)
    function changeActionThreshold(uint threshold)
        public
        whenNotPaused
        onlyManagementOrSelf
    {
        require(threshold > 0);
        // Don't lock yourself out
        uint numActionKeys = getKeysByPurpose(ACTION_KEY).length;
        require(threshold <= numActionKeys);
        actionThreshold = threshold;
    }

    /// @dev Generate a unique ID for an execution request
    /// @param self address of identity contract
    /// @param _to address being called (msg.sender)
    /// @param _value ether being sent (msg.value)
    /// @param _data ABI encoded call data (msg.data)
    /// @param _nonce nonce to prevent replay attacks
    /// @return Integer ID of execution request
    function getExecutionId(
        address self,
        address _to,
        uint256 _value,
        bytes _data,
        uint _nonce
    )
        public
        pure
        returns (uint256)
    {
        return uint(keccak256(abi.encodePacked(self, _to, _value, _data, _nonce)));
    }
    
    function getFunctionSignature(bytes b) public pure returns (bytes4) {
        bytes4 out;

        for (uint i = 0; i < 4; i++) {
            out |= bytes4(b[i] & 0xFF) >> (i * 8);
        }
        return out;
    }

    function getNonce() public view returns (uint256) {
        return nonce;
    }

    function getTransactionCount() public view returns (uint256) {
        return nonce;
    }

    function hasPermission(address _sender, address _to, bytes _data) internal view returns (uint256 threshold) { 
        if (_to == address(this)) {
            if (_sender == address(this)) {
                // Contract calling itself to act on itself
                threshold = managementThreshold;
            } else {
                // Only management keys can operate on this contract
                // addKey function Signautre == 0x1d381240
                if (
                    allKeys.find(addrToKey(_sender), MANAGEMENT_KEY) ||
                    allKeys.find(addrToKey(_sender), RESTORE_KEY) &&
                    getFunctionSignature(_data) == bytes4(0x1d381240)
                ) {
                    threshold = managementThreshold - 1;
                } else {
                    revert();
                }
            }
        } else {
            require(_to != address(0));
            if (_sender == address(this)) {
                // Contract calling itself to act on other address
                threshold = actionThreshold;
            } else {
                // Action keys can operate on other addresses
                if (
                    allKeys.find(addrToKey(_sender), ACTION_KEY) ||
                    allKeys.find(addrToKey(_sender), DELEGATE_KEY) ||
                    allKeys.find(addrToKey(_sender), CUSTOM_KEY) &&
                    allKeys.keyData[addrToKey(_sender)].func[_to][getFunctionSignature(_data)]
                ) {
                    threshold = actionThreshold - 1;
                } else {
                    revert();
                }
            }
        }
    }

    function preExecute(address _sender, address _to, uint256 _value, bytes _data)
        internal
        returns (uint256 executionId)
    {
        // TODO: Using threshold at time of execution
        uint256 threshold = hasPermission(_sender, _to, _data);
        
        // Generate id and increment nonce
        executionId = getExecutionId(address(this), _to, _value, _data, nonce);
        emit ExecutionRequested(executionId, _to, _value, _data);
        nonce++;

        Execution memory e = Execution(_to, _value, _data, threshold);
        if (threshold == 0) {
            // One approval is enough, execute directly
            _execute(executionId, e, false);
        } else {
            execution[executionId] = e;
            approved[executionId].push(_sender);
        }

        return executionId;
    }
    
    function preApprove(address _sender, uint256 _id, bool _approve) internal returns (bool success) {
        require(_id != 0);
        Execution storage e = execution[_id];
        // Must exist
        require(e.to != 0);
        
        // Must be approved with the right key
        hasPermission(_sender, e.to, e.data);

        emit Approved(_id, _approve);

        address[] storage approvals = approved[_id];
        
        if (!_approve) {
            // Find in approvals
            for (uint i = 0; i < approvals.length; i++) {
                if (approvals[i] == _sender) {
                    // Undo approval
                    approvals[i] = approvals[approvals.length - 1];
                    delete approvals[approvals.length - 1];
                    approvals.length--;
                    e.needsApprove += 1;
                    return true;
                }
            }
            return false;
        } else {
            // Only approve once
            for (i = 0; i < approvals.length; i++) {
                require(approvals[i] != _sender);
            }

            // Approve
            approvals.push(_sender);
            e.needsApprove -= 1;

            // Do we need more approvals?
            if (e.needsApprove == 0) {
                return _execute(_id, e, true);
            }
            return true;
        }    
    }

    /// @dev Executes an action on other contracts, or itself, or a transfer of ether
    /// @param _id Execution ID
    /// @param e Execution data
    /// @param clean `true` if the internal state should be cleaned up after the execution
    /// @return `true` if the execution succeeded, `false` otherwise
    function _execute(
        uint256 _id,
        Execution e,
        bool clean
    )
        private
        returns (bool)
    {
        // Must exist
        require(e.to != 0);
        // Call
        // TODO: Should we also support DelegateCall and Create (new contract)?
        // solhint-disable-next-line avoid-call-value
        bool success = e.to.call.value(e.value)(e.data);
        if (!success) {
            emit ExecutionFailed(_id, e.to, e.value, e.data);
            return false;
        }
        emit Executed(_id, e.to, e.value, e.data);
        // Clean up
        if (!clean) {
            return true;
        }
        delete execution[_id];
        delete approved[_id];
        return true;
    }
}

contract MetaIdentityLib is KeyManager, MultiSig, ClaimManager, Destructible, KeyGetters {
    using Slice for bytes;
    using Slice for string;

    // Fallback function accepts Ether transactions
    // solhint-disable-next-line no-empty-blocks
    function () external payable {
    
    }

    function init(address _managementKey) public {
        bytes32 senderKey = addrToKey(_managementKey);
        
        require(getKeysByPurpose(MANAGEMENT_KEY).length == 0, "Already initiated");

        // Add key that deployed the contract for MANAGEMENT, ACTION, CLAIM
        _addKey(senderKey, MANAGEMENT_KEY, ECDSA_TYPE);
        _addKey(senderKey, ACTION_KEY, ECDSA_TYPE);
        _addKey(senderKey, CLAIM_SIGNER_KEY, ECDSA_TYPE);
        
        managementThreshold = 1;
        actionThreshold = 1;

        // Supports both ERC 725 & 735
        supportedInterfaces[ERC725ID() ^ ERC735ID()] = true;
    }
}

library Slice {
    /// @dev Slice a bytes array
    /// @param offset Index to start slice at
    /// @param length Length of slice
    /// @return Sliced bytes array
    function slice(
        bytes self,
        uint256 offset,
        uint8 length
    )
        internal
        pure
        returns (bytes)
    {
        bytes memory s = new bytes(length);
        uint256 i = 0;
        for (uint256 j = offset; j < offset + length; j++) {
            s[i++] = self[j];
        }
        return s;
    }

    /// @dev Slice a string
    /// @param offset Index to start slice at
    /// @param length Length of slice
    /// @return Sliced string
    function slice(
        string self,
        uint256 offset,
        uint8 length
    )
        internal
        pure
        returns (string)
    {
        return string(slice(bytes(self), offset, length));
    }
}

