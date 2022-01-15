// SPDX-License-Identifier: MIT

pragma solidity =0.6.12;

interface IFarmPool {
    function tokenAddr() external view returns (address);

    function skim(uint256 amount) external;

    function pendingReward() external view returns (address, uint256);

    function harvest() external returns (address, uint256);

    function exit(bool compound) external;

    function getOwner() external view returns (address);
}
