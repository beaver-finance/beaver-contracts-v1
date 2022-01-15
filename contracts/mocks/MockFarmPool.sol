// SPDX-License-Identifier: MIT

pragma solidity =0.6.12;

import "../strategy/IFarmPool.sol";
import "@boringcrypto/boring-solidity/contracts/libraries/BoringERC20.sol";
import "hardhat/console.sol";

contract MockFarmPool is IFarmPool {
    using BoringERC20 for IERC20;

    IERC20 public token;
    address public box;

    constructor(address _token, address _box) public {
        token = IERC20(_token);
        box = _box;
    }

    function tokenAddr() external view override returns (address) {
        return address(token);
    }

    function skim(uint256 amount) external override {}

    function pendingReward() external view override returns (address, uint256) {
        return (address(token), 1000);
    }

    function harvest() external override returns (address rewardToken, uint256 rewardAmount) {
        rewardToken = address(token);
        rewardAmount = 1000;
        token.safeTransfer(box, rewardAmount);
    }

    function exit(bool compound) external override {

    }

    function getOwner() external view override returns(address){
        return address(this);
    }
}
