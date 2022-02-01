// SPDX-License-Identifier: Unlicensed
pragma solidity 0.8.4;

interface IOVRLand {
    function mint(address _user, uint256 _tokenId) external returns (bool);

    function safeMint(
        address _user,
        uint256 _tokenId,
        string memory _uri
    ) external returns (bool);
}
