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
    uint256 attestationAgencyNum;

    mapping(uint256=>AttestationAgency) public attestationAgencies;
    mapping(address=>uint256) public isAAregistered;
    
    event RegisterAttestationAgency(address indexed aa, bytes32 indexed title, bytes32 description);
    event UpdateAttestationAgency(address indexed aa, bytes32 indexed title, bytes32 description);

    function AttestationAgencyRegistry() public {
        THIS_NAME = "AttestationAgencyRegistry";
        attestationAgencyNum = 1;

        attestationAgencies[0].addr = 0xFFfFfFffFFfffFFfFFfFFFFFffFFFffffFfFFFfF;
        attestationAgencies[0].title = 'MetadiumDefault';
        attestationAgencies[0].description = 'MetadiumDefault';
    }

    /**
     * @dev Register Attestation Agency
     * @param _addr address to register
     * @param _title title
     * @param _description description
     * @return A boolean that indicates if the operation was successful.
     */
    function registerAttestationAgency(address _addr, bytes32 _title, bytes32 _description) permissioned public returns (bool) {
        require(isAAregistered[_addr] == 0);
        
        attestationAgencies[attestationAgencyNum].addr = _addr;
        attestationAgencies[attestationAgencyNum].title = _title;
        attestationAgencies[attestationAgencyNum].description = _description;

        isAAregistered[_addr] = attestationAgencyNum;

        attestationAgencyNum++;

        emit RegisterAttestationAgency(_addr, _title, _description);

        return true;
    }   

    /**
     * @dev Update Attestation Agency
     * @param _num index of the AA
     * @param _addr address to register
     * @param _title title
     * @param _description description
     * @return A boolean that indicates if the operation was successful.
     */
    function updateAttestationAgency(uint256 _num, address _addr, bytes32 _title, bytes32 _description) permissioned public returns (bool) {
        
        require(isAAregistered[_addr] == _num);

        attestationAgencies[attestationAgencyNum].addr = _addr;
        attestationAgencies[attestationAgencyNum].title = _title;
        attestationAgencies[attestationAgencyNum].description = _description;

        emit UpdateAttestationAgency(_addr, _title, _description);

        return true;

    }

    function isRegistered(address _addr) view public returns(uint256){
        return isAAregistered[_addr];
    }

    function getAttestationAgencySingle(uint256 _num) view public returns(address, bytes32, bytes32) {
        return (
            attestationAgencies[_num].addr,
            attestationAgencies[_num].title,
            attestationAgencies[_num].description
        );
    }

    function getAttestationAgenciesFromTo(uint256 _from, uint256 _to) view public returns(address[], bytes32[], bytes32[]){
        
        require(_to<attestationAgencyNum && _from < _to);
        
        address[] memory saddrs = new address[](_to-_from+1);
        bytes32[] memory sdescs = new bytes32[](_to-_from+1);
        bytes32[] memory stitles = new bytes32[](_to-_from+1);

        for(uint256 i=_from;i<=_to;i++){
            saddrs[i-_from] = attestationAgencies[i].addr;
            sdescs[i-_from] = attestationAgencies[i].description;
            stitles[i-_from] = attestationAgencies[i].title;
        }

        return (saddrs, stitles, sdescs);
    } 
    

}
