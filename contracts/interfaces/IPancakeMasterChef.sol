// SPDX-License-Identifier: MIT

pragma solidity =0.6.12;

pragma experimental ABIEncoderV2;

interface IPancakeMasterChef {
    struct UserInfo {
        uint256 amount;
        uint256 rewardDebt;
    }

    struct PoolInfo {
        address lpToken;
        uint256 allocPoint;
        uint256 lastRewardBlock;
        uint256 accCakePerShare;
    }

    function cakePerBlock() external view returns (uint256);

    function enterStaking(uint256 _amount) external;

    function leaveStaking(uint256 _amount) external;

    function withdraw(uint256 _pid, uint256 _amount) external;

    function deposit(uint256 _pid, uint256 _amount) external;

    function userInfo(uint256 _pid, address _owner) external view returns (UserInfo memory);

    function poolInfo(uint256 _pid) external view returns (PoolInfo memory);

    function pendingCake(uint256 _pid, address _user) external view returns (uint256);

    function cake() external view returns (address);
}
