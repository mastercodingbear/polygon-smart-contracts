// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.2;

interface IMarketplace {
    function landIsOnSelling(uint256 _landId)
        external
        view
        returns (bool _onSelling);

    function containerIsOnSelling(uint256 _containerId)
        external
        view
        returns (bool _onSelling);
}
