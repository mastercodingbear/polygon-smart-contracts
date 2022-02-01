// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.2;

interface IRenting {
    function landIsOnRenting(uint256 _landId)
        external
        view
        returns (bool _onSelling);

    function containerIsOnRenting(uint256 _containerId)
        external
        view
        returns (bool _onSelling);
}
