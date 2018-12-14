pragma solidity ^0.4.24;

import "./Destructible.sol";
import "./ERC735.sol";
import "./KeyGetters.sol";
import "./KeyManager.sol";
import "./MultiSig.sol";
import "./ClaimManager.sol";
import "./Slice.sol";

/// @title MetaIdentity
/// @author Metadium, genie
/// @notice Identity contract implementing ERC 725, ERC 735 and Metadium features.

contract MetaIdentityLibNoInit is KeyManager, MultiSig, ClaimManager, Destructible, KeyGetters {
    using Slice for bytes;
    using Slice for string;
    
    // Fallback function accepts Ether transactions
    // solhint-disable-next-line no-empty-blocks
    function () external payable {
    
    }


}