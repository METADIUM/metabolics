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
        bytes32 explanation;
        uint256 createdAt;    
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
    function registerAttestationAgency(address _addr, bytes32 _title, bytes32 _explanation)
        public
        permissioned
        returns (bool success)
    {
        require(_addr != address(0), "Address should be non-zero");
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
    function updateAttestationAgency(address _addr, bytes32 _title, bytes32 _explanation)
        public
        permissioned
        returns (bool success)
    {
        uint256 _num = isAAregistered[_addr];
        require(_num != 0, "number should non-zero");
        
        attestationAgencies[_num].title = _title;
        attestationAgencies[_num].explanation = _explanation;
        attestationAgencies[_num].createdAt = block.timestamp;

        emit UpdateAttestationAgency(_addr, _title, _explanation);

        return true;

    }

    function isRegistered(address _addr) public view returns (uint256 found) {
        return isAAregistered[_addr];
    }

    function getAttestationAgencySingle(uint256 _num)
        public
        view
        returns (address addr, bytes32 title, bytes32 explanation, uint256 createdAt)
    {
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
        returns (address[] addrs, bytes32[] titles, bytes32[] descs, uint256[] createds)
    {
        require(_to < attestationAgencyNum && _from <= _to, "from to mismatch");
        
        address[] memory saddrs = new address[](_to - _from + 1);
        bytes32[] memory sdescs = new bytes32[](_to - _from + 1);
        bytes32[] memory stitles = new bytes32[](_to - _from + 1);
        uint256[] memory screateds = new uint256[](_to - _from + 1);

        for (uint256 i = _from; i <= _to; i++) {
            saddrs[i-_from] = attestationAgencies[i].addr;
            sdescs[i-_from] = attestationAgencies[i].explanation;
            stitles[i-_from] = attestationAgencies[i].title;
            screateds[i-_from] = attestationAgencies[i].createdAt;
        }

        return (saddrs, stitles, sdescs, screateds);
    }
}
