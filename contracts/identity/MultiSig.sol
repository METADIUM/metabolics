pragma solidity ^0.4.24;

import "./Pausable.sol";
import "./ERC725.sol";
import "../openzeppelin-solidity/contracts/ECRecovery.sol";
import "./SignatureVerifier.sol";

/// @title MultiSig
/// @author genie
/// @notice Implement execute and multi-sig functions from ERC725 spec
/// @dev Key data is stored using KeyStore library. Inheriting ERC725 for the getters

contract MultiSig is Pausable, ERC725, SignatureVerifier {
    using ECRecovery for bytes32;

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

    function hasPermission(address _sender, address _to, bytes _data) view internal returns(uint256 threshold) { 
        if (_to == address(this)) {
            if (_sender == address(this)) {
                // Contract calling itself to act on itself
                threshold = managementThreshold;
            } else {
                // Only management keys can operate on this contract
                // addKey function Signautre == 0x1d381240
                if (
                    allKeys.find(addrToKey(_sender), MANAGEMENT_KEY) ||
                    allKeys.find(addrToKey(_sender), RESTORE_KEY) && getFunctionSignature(_data) == bytes4(0x1d381240)
                ){
                    threshold = managementThreshold - 1;
                }else {
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
                    allKeys.find(addrToKey(_sender), CUSTOM_KEY) && allKeys.keyData[addrToKey(_sender)].func[_to][getFunctionSignature(_data)]
                ){
                    threshold = actionThreshold - 1;
                } else {
                    revert();
                }
            }
        }

    }

    function preExecute(address _sender, address _to, uint256 _value, bytes _data) internal returns (uint256 executionId) {
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

    function delegatedExecute(address _to, uint256 _value, bytes _data, uint256 _nonce, bytes _sig) public  whenNotPaused returns (uint256 executionId) {
        // check nonce
        require(_nonce == nonce,"nonce mismatch");

        // sinature verify
        address signedBy = getSignatureAddress(keccak256(abi.encodePacked(_to, _value, _data, _nonce)), _sig);
        return preExecute(signedBy, _to, _value, _data);
    
    }

    function approve(uint256 _id, bool _approve) public whenNotPaused returns (bool success) {
        return preApprove(msg.sender, _id, _approve);
    }

    function delegatedApprove(uint256 _id, bool _approve, uint256 _nonce, bytes _sig) public whenNotPaused returns (bool success) {
        
        // check nonce
        require(_nonce == nonce, "nonce mismatch");

        // sinature verify
        address signedBy = getSignatureAddress(keccak256(abi.encodePacked(_id, _approve, _nonce)), _sig);
        //return true;
        return preApprove(signedBy, _id, _approve);
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

    

    /// @dev Approves an execution. If the execution is being approved multiple times,
    ///  it will throw an error. Disapproving multiple times will work i.e. not do anything.
    ///  The approval could potentially trigger an execution (if the threshold is met).
    /// @param _id Execution ID
    /// @param _approve `true` if it's an approval, `false` if it's a disapproval
    /// @return `false` if it's a disapproval and there's no previous approval from the sender OR
    ///  if it's an approval that triggered a failed execution. `true` if it's a disapproval that
    ///  undos a previous approval from the sender OR if it's an approval that succeded OR
    ///  if it's an approval that triggered a succesful execution
    // function approve(uint256 _id, bool _approve)
    //     public
    //     whenNotPaused
    //     returns (bool success)
    // {
    //     require(_id != 0);
    //     Execution storage e = execution[_id];
    //     // Must exist
    //     require(e.to != 0);

    //     // Must be approved with the right key
    //     hasPermission(msg.sender, e.to, e.data);

    //     emit Approved(_id, _approve);

    //     address[] storage approvals = approved[_id];
    //     if (!_approve) {
    //         // Find in approvals
    //         for (uint i = 0; i < approvals.length; i++) {
    //             if (approvals[i] == msg.sender) {
    //                 // Undo approval
    //                 approvals[i] = approvals[approvals.length - 1];
    //                 delete approvals[approvals.length - 1];
    //                 approvals.length--;
    //                 e.needsApprove += 1;
    //                 return true;
    //             }
    //         }
    //         return false;
    //     } else {
    //         // Only approve once
    //         for (i = 0; i < approvals.length; i++) {
    //             require(approvals[i] != msg.sender);
    //         }

    //         // Approve
    //         approvals.push(msg.sender);
    //         e.needsApprove -= 1;

    //         // Do we need more approvals?
    //         if (e.needsApprove == 0) {
    //             return _execute(_id, e, true);
    //         }
    //         return true;
    //     }
    // }

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
    function getTransactionCount() public view returns(uint256) {
        return nonce;
    }
    function getFunctionSignature(bytes b) public pure returns(bytes4) {
        bytes4 out;

        for (uint i = 0; i < 4; i++) {
            out |= bytes4(b[i] & 0xFF) >> (i * 8);
        }
        return out;
    }
}