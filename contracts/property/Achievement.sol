pragma solidity ^0.4.24;

import "openzeppelin-solidity/contracts/token/ERC721/ERC721Full.sol";
import "openzeppelin-solidity/contracts/ownership/Ownable.sol";
import "../RegistryUser.sol";


/**
 * @title MetaID
 * This provides a public mint and burn functions for testing purposes,
 * and a public setter for metadata URI
 */
contract Achievement is ERC721Full, RegistryUser {
    event Mint(address indexed owner, uint256 indexed metaID);
    event Burn(address indexed owner, uint256 indexed metaID);
    
    bool public transferEnabled = false;

    // Optional mapping for token URIs
    mapping(uint256 => string) private _tokenURIs;

    modifier isTradable() {
        require(transferEnabled || REG.getPermission(THIS_NAME, msg.sender), "Transfer not enabled");
        _;
    }

    constructor(string name, string symbol) public ERC721Full(name, symbol) {
        THIS_NAME = "Achievement";
    }

    /**
     * @dev Function to mint ERC721 Token.
     * @param _to The address that will receive the minted tokens.
     * @param _tokenId the token index of newly minted token.
     * @param _uri the metaID that the newly minted token would get.
     * @return A boolean that indicates if the operation was successful.
     */
    function mint(address _to, uint256 _tokenId, string _uri) public permissioned returns (bool success) {
        super._mint(_to, _tokenId);
        super._setTokenURI(_tokenId, _uri);
        emit Mint(_to, _tokenId);
        return true;
    }

    /**
     * @dev Function to burn ERC721 Token.
     * @param _tokenId the token index of burning token.
     * @return A boolean that indicates if the operation was successful.
     */
    function burn(uint256 _tokenId) public permissioned returns (bool success) {
        address _from = ownerOf(_tokenId);
        super._burn(_from, _tokenId);
        emit Burn(_from, _tokenId);
        return true;
    }

    function enableTransfer() public permissioned returns (bool success) {
        transferEnabled = true;
        return true;
    }

    function disableTransfer() public permissioned returns (bool success) {
        transferEnabled = false;
        return true;
    }

    /**
     * @dev Returns an URI as bytes for a given token ID
     * @dev Throws if the token ID does not exist. May return an empty string.
     * @param _tokenId uint256 ID of the token to query
     */
    function tokenURIAsBytes(uint256 _tokenId) public view returns (bytes uri) {
        require(_exists(_tokenId), "Token ID cannot be found");
        return bytes(_tokenURIs[_tokenId]);
    }

    function transferFrom(address _from, address _to, uint256 _tokenId) public isTradable {
        super.transferFrom(_from, _to, _tokenId);
    }

    function safeTransferFrom(address _from, address _to, uint256 _tokenId) public isTradable {
        super.safeTransferFrom(_from, _to, _tokenId);
    }

    function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes _data) public isTradable {
        super.safeTransferFrom(_from, _to, _tokenId, _data);
    }
    

    function approve(address _to, uint256 _tokenId) public isTradable {
        super.approve(_to, _tokenId);
    }

    function setApprovalForAll(address _operator, bool _approved) public isTradable {
        super.setApprovalForAll(_operator, _approved);
    }
}
