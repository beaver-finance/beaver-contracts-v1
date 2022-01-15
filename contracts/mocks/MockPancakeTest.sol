// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "../strategy/pancakeswap/PancakePool.sol";

contract MockPancakeTest {
    IERC20 public rewardToken;

    constructor(address addr) public {
        rewardToken = IERC20(addr);
    }

    function exit(address addr) public {
        PancakePool pool = PancakePool(addr);
        pool.setNeedPayback(true);
        pool.exit(false);
    }

    function payback(
        uint256 _farmId,
        uint256 borrowed,
        uint256 amount
    )
        public
        returns (
            address _farmPool,
            uint256 _amount,
            uint256 _reserve
        )
    {
        return (address(this), 0, 0);
    }
}
