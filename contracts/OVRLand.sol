// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

contract OVRLand is
    ERC721,
    ERC721Enumerable,
    ERC721URIStorage,
    ERC721Burnable,
    AccessControl
{
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant LAND_URI_EDITOR_ROLE =
        keccak256("LAND_URI_EDITOR_ROLE");
    bytes32 public constant BURNER_ROLE = keccak256("BURNER_ROLE");

    constructor() ERC721("OVRLand", "OVR Land") {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, msg.sender);
        _grantRole(BURNER_ROLE, msg.sender);
    }

    function addURIEditor(address _editor) public onlyRole(DEFAULT_ADMIN_ROLE) {
        grantRole(LAND_URI_EDITOR_ROLE, _editor);
    }

    function removeURIEditor(address _editor)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        revokeRole(LAND_URI_EDITOR_ROLE, _editor);
    }

    function addMinter(address _minter) public onlyRole(DEFAULT_ADMIN_ROLE) {
        grantRole(MINTER_ROLE, _minter);
    }

    function removeMinter(address _minter) public onlyRole(DEFAULT_ADMIN_ROLE) {
        revokeRole(MINTER_ROLE, _minter);
    }

    function addBurner(address _burner) public onlyRole(DEFAULT_ADMIN_ROLE) {
        grantRole(BURNER_ROLE, _burner);
    }

    function removeBurner(address _burner) public onlyRole(DEFAULT_ADMIN_ROLE) {
        revokeRole(BURNER_ROLE, _burner);
    }

    function addAdminRole(address _admin) public onlyRole(DEFAULT_ADMIN_ROLE) {
        grantRole(DEFAULT_ADMIN_ROLE, _admin);
        grantRole(MINTER_ROLE, _admin);
        grantRole(LAND_URI_EDITOR_ROLE, _admin);
    }

    function removeAdminRole(address _admin)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        revokeRole(DEFAULT_ADMIN_ROLE, _admin);
        revokeRole(MINTER_ROLE, _admin);
        revokeRole(LAND_URI_EDITOR_ROLE, _admin);
    }

    /**
     * @notice Example function to handle minting tokens on matic chain
     * @dev Minting can be done as per requirement,
     * This implementation allows only minter to mint and set tokens uris but it can be changed as per requirement
     * @param to user for whom tokens are being minted
     * @param tokenId tokenId to mint
     * @param uri token uri
     */
    function safeMint(
        address to,
        uint256 tokenId,
        string memory uri
    ) public onlyRole(MINTER_ROLE) returns (bool) {
        _safeMint(to, tokenId);
        _setTokenURI(tokenId, uri);
        return true;
    }

    /**
     * @dev Function to set the OVRLand IPFS uri.
     * @param _tokenId uint256 ID of the OVRLand
     * @param _uri string of the OVRLand IPFS uri
     */
    function setOVRLandURI(uint256 _tokenId, string memory _uri)
        public
        onlyRole(LAND_URI_EDITOR_ROLE)
    {
        _setTokenURI(_tokenId, _uri);
    }

    /**
     * @notice Example function to handle burning tokens on matic chain
     * @dev Burning can be done as per requirement,
     * This implementation allows only burner to burn tokens but it can be changed as per requirement
     * @param _tokenId tokenId to mint
     */
    function burn(uint256 _tokenId) public override onlyRole(BURNER_ROLE) {
        _burn(_tokenId);
    }

    /**
     * @notice Example function to handle batch burning tokens on matic chain
     * @dev Burning can be done as per requirement,
     * This implementation allows only burner to batch burn tokens but it can be changed as per requirement
     * @param _tokenId tokenId to mint
     */
    function batchBurn(uint256[] memory _tokenId) public onlyRole(BURNER_ROLE) {
        for (uint256 i = 0; i < _tokenId.length; i++) {
            burn(_tokenId[i]);
        }
    }

    /**
     * @notice Example function to handle minting tokens on matic chain
     * @dev Minting can be done as per requirement,
     * This implementation allows only minter to mint tokens but it can be changed as per requirement
     * @param _user user for whom tokens are being minted
     * @param _tokenId tokenId to mint
     */
    function mint(address _user, uint256 _tokenId)
        public
        onlyRole(MINTER_ROLE)
        returns (bool)
    {
        _mint(_user, _tokenId);
        return true;
    }

    /**
     * @notice Function to batch minting tokens on matic chain
     * @param _to address array
     * @param _tokenId tokenId array
     */
    function batchMintLands(address[] memory _to, uint256[] memory _tokenId)
        public
        onlyRole(MINTER_ROLE)
    {
        require(_to.length == _tokenId.length, "Different array input size");
        for (uint256 i = 0; i < _to.length; i++) {
            _mint(_to[i], _tokenId[i]);
        }
    }

    /**
     * @notice Function to batch minting tokens with uri on matic chain
     * @param _to address array
     * @param _tokenId tokenId array
     * @param _uri uri array
     */
    function batchMintLandsWithUri(
        address[] memory _to,
        uint256[] memory _tokenId,
        string[] memory _uri
    ) public onlyRole(MINTER_ROLE) {
        require(
            _to.length == _tokenId.length,
            "Different array input size (to - tokenId) "
        );

        for (uint256 i = 0; i < _to.length; i++) {
            safeMint(_to[i], _tokenId[i], _uri[i]);
        }
    }

    /**
     * @dev Function to set the OVRLand URI in batch.
     * @param _tokenId tokenId array
     * @param _uri uri array
     */
    function batchSetOVRLandURI(uint256[] memory _tokenId, string[] memory _uri)
        public
        onlyRole(LAND_URI_EDITOR_ROLE)
    {
        require(_tokenId.length == _uri.length, "Different array input size");
        for (uint256 i = 0; i < _tokenId.length; i++) {
            _setTokenURI(_tokenId[i], _uri[i]);
        }
    }

    // The following functions are overrides required by Solidity.

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function _burn(uint256 tokenId)
        internal
        override(ERC721, ERC721URIStorage)
    {
        super._burn(tokenId);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable, AccessControl)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
