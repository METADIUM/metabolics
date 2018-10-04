pragma solidity ^0.4.24;

import "../RegistryUser.sol";

/// @title AttestationAgencyRegistry
/// @author genie
/// @notice Attestation Agency Registry.
/// @dev  Attestation Agency can be registered when create achievement or the permissioned user can create.
contract AttestationAgencyRegistry is RegistryUser {
    
    struct AttestationAgency {
        address addr;
        bytes32 description;
    }

    mapping(uint256=>AttestationAgency) public attestationAgencies;
    mapping(address=>bool) public isAARegisterd;
    uint256 attestationAgencyNum;

    function AttestationAgencyRegistry() public {
        THIS_NAME = "AttestationAgencyRegistry";
    }

    function registerAttestationAgency(address _addr, bytes32 _description) permissioned public returns (bool) {
        require(!isAARegisterd[_addr]);
        
        attestationAgencies[attestationAgencyNum].addr = _addr;
        attestationAgencies[attestationAgencyNum].description = _description;

        attestationAgencyNum++;
        isAARegisterd[_addr] = true;
        return true;
    }   
    
    function getAttestationAgenciesFromTo(uint256 from, uint256 to) view public returns(address[], bytes32[]){
        
        require(to<attestationAgencyNum);
        
        address[] storage saddrs;
        bytes32[] storage sdescs;

        for(uint256 i=from;i<to;i++){
            saddrs.push(attestationAgencies[attestationAgencyNum].addr);
            sdescs.push(attestationAgencies[attestationAgencyNum].description);
        }

        return (saddrs, sdescs);
    } 
    

}
