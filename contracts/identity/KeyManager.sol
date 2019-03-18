pragma solidity ^0.4.24;

import "./Pausable.sol";
import "./ERC725.sol";


/// @title KeyManager
/// @author genie
/// @notice Implement add/remove functions from ERC725 spec
/// @dev Key data is stored using KeyStore library. Inheriting ERC725 for the events
contract KeyManager is Pausable, ERC725 {
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
        allKeys.setFunc(_key, _to, _func, _executable);   
        return true;
    }
}