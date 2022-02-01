// SPDX-License-Identifier: Unlicensed
pragma solidity 0.8.4;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

import "../interfaces/IOVRLand.sol";

contract LightMint is AccessControl, Pausable {
    address public ovrLand;
    bytes32 public merkleRoot;
    uint256 private mappingVersion;

    constructor(address ovrLandAddress) {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        ovrLand = ovrLandAddress;
    }

    mapping(bytes32 => bool) private claimedMap;
    // This is a packed array of booleans.

    mapping(uint256 => uint256) private claimedBitMap;

    function addAdminRole(address _admin) public onlyRole(DEFAULT_ADMIN_ROLE) {
        grantRole(DEFAULT_ADMIN_ROLE, _admin);
    }

    function setOVRLand(address _ovrLand)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        ovrLand = _ovrLand;
    }

    function setMerkleRoot(bytes32 _merkleRoot)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        merkleRoot = _merkleRoot;
        mappingVersion++;
    }

    function isClaimed(uint256 _index) public view returns (bool) {
        bytes32 key = keccak256(abi.encodePacked(mappingVersion, _index));
        return claimedMap[key];
    }

    function _setClaimed(uint256 _index) private {
        bytes32 key = keccak256(abi.encodePacked(mappingVersion, _index));
        claimedMap[key] = true;
    }

    function claim(
        uint256 _index,
        address _account,
        uint256 _tokenId,
        string memory _uri,
        bytes32[] memory _merkleProof
    ) external whenNotPaused {
        require(!isClaimed(_index), "MerkleDistributor: Drop already claimed.");
        // Verify the merkle proof.
        bytes32 node = keccak256(
            abi.encodePacked(_index, _account, _tokenId, _uri)
        );
        require(
            MerkleProof.verify(_merkleProof, merkleRoot, node),
            "MerkleDistributor: Invalid proof."
        );
        // Mark it claimed and send the token.
        _setClaimed(_index);
        require(
            IOVRLand(ovrLand).safeMint(_account, _tokenId, _uri),
            "MerkleDistributor: Mint failed."
        );
    }

    function pause() public onlyRole(DEFAULT_ADMIN_ROLE) {
        _pause();
    }

    function unpause() public onlyRole(DEFAULT_ADMIN_ROLE) {
        _unpause();
    }
}
