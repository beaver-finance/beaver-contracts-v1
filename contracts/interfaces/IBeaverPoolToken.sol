// SPDX-License-Identifier: MIT
pragma solidity =0.6.12;

interface IBeaverPoolToken {
    function payback(
        uint256 _farmId,
        uint256 borrowed,
        uint256 amount
    )
        external
        returns (
            address _farmPool,
            uint256 _amount,
            uint256 _reserve
        );
}
