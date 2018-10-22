pragma solidity ^0.4.24;

import "../RegistryUser.sol";

/// @title AttestationAgencyRegistry
/// @author genie
/// @notice Attestation Agency Registry.
/// @dev  Attestation Agency can be registered when create achievement or the permissioned user can create.
contract AttestationAgencyRegistry is RegistryUser {
    
    struct AttestationAgency {
        address addr;
        bytes32 title;
        bytes32 description;
        // code for 
        // bool type isEnterprise;
         
    }

    mapping(uint256=>AttestationAgency) public attestationAgencies;
    
    mapping(address=>uint256) public isAARegisterd;

    uint256 attestationAgencyNum;

    function AttestationAgencyRegistry() public {
        THIS_NAME = "AttestationAgencyRegistry";
        attestationAgencyNum = 1;

        attestationAgencies[0].addr = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
        attestationAgencies[0].title = 'MetadiumDefault';
        attestationAgencies[0].description = 'MetadiumDefault';
    }

    function registerAttestationAgency(address _addr, bytes32 _title, bytes32 _description) permissioned public returns (bool) {
        require(isAARegisterd[_addr] == 0);
        
        attestationAgencies[attestationAgencyNum].addr = _addr;
        attestationAgencies[attestationAgencyNum].title = _title;
        attestationAgencies[attestationAgencyNum].description = _description;

        isAARegisterd[_addr] = attestationAgencyNum;

        attestationAgencyNum++;

        return true;
    }   

    function updateAttestationAgency(uint256 _num, bytes32 _addr, bytes32 _title, bytes32 _description) permissioned public returns (bool) {
        
        require(isAARegisterd[_addr] == _num);

        attestationAgencies[attestationAgencyNum].addr = _addr;
        attestationAgencies[attestationAgencyNum].title = _title;
        attestationAgencies[attestationAgencyNum].description = _description;

        return true;

    }
    function isRegisterd(address _addr) view public returns(uint256){
        return isAARegisterd[_addr];
    }

    function getAttestationAgencySingle(uint256 _num) view public returns(address, bytes32, bytes32) {
        return (
            attestationAgencies[_num].addr,
            attestationAgencies[_num].title,
            attestationAgencies[_num].description
        );
    }

    function getAttestationAgenciesFromTo(uint256 _from, uint256 _to) view public returns(address[], bytes32[], bytes32[]){
        
        require(_to<attestationAgencyNum);
        
        address[] storage saddrs;
        bytes32[] storage sdescs;
        bytes32[] storage stitles;

        for(uint256 i=_from;i<_to;i++){
            saddrs.push(attestationAgencies[attestationAgencyNum].addr);
            sdescs.push(attestationAgencies[attestationAgencyNum].description);
            stitles.push(attestationAgencies[attestationAgencyNum].title);
        }

        return (saddrs, stitles, sdescs);
    } 
    

}
