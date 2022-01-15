// SPDX-License-Identifier: MIT

pragma solidity =0.6.12;

pragma experimental ABIEncoderV2;

import "@boringcrypto/boring-solidity/contracts/libraries/BoringERC20.sol";

interface IRewarder {
    using BoringERC20 for IERC20;

    function onNETTReward(address user, uint256 newLpAmount) external;

    function pendingTokens(address user) external view returns (uint256 pending);

    function rewardToken() external view returns (address);
}

interface INettswapMasterChef {
    struct UserInfo {
        uint256 amount;
        uint256 rewardDebt;
    }

    struct PoolInfo {
        IERC20 lpToken;
        uint256 allocPoint;
        uint256 lastRewardTimestamp;
        uint256 accNETTPerShare;
        uint256 lpSupply;
        IRewarder rewarder;
    }

    function withdraw(uint256 _pid, uint256 _amount) external;

    function deposit(uint256 _pid, uint256 _amount) external;

    function userInfo(uint256 _pid, address _owner) external view returns (UserInfo memory);

    function poolInfo(uint256 _pid) external view returns (PoolInfo memory);

    function pendingTokens(uint256 _pid, address _user)
        external
        view
        returns (
            uint256 pendingNETT,
            address bonusTokenAddress,
            string memory bonusTokenSymbol,
            uint256 pendingBonusToken
        );

    function nett() external view returns (address);
}
