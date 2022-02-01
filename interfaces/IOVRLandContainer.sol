// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

interface IOVRLandContainer is IERC721 {
    function childsOfParent(uint256 _containerId)
        external
        view
        returns (uint256[] memory lands);
}
