// SPDX-License-Identifier: MIT

pragma solidity =0.6.12;

pragma experimental ABIEncoderV2;

import "@boringcrypto/boring-solidity/contracts/libraries/BoringMath.sol";
import "@boringcrypto/boring-solidity/contracts/libraries/BoringERC20.sol";

import "../interfaces/IPancakeRouter01.sol";
import "../interfaces/IUniswapV2Pair.sol";
import "../interfaces/IPancakeMasterChef.sol";
import "hardhat/console.sol";

contract MockPancakeOperator {
    IPancakeRouter01 public router01;
    IPancakeMasterChef public chef;

    constructor(address _router, address _chef) public {
        router01 = IPancakeRouter01(_router);
        chef = IPancakeMasterChef(_chef);
    }

    function invest(
        uint256 pid,
        address token0,
        address token1,
        uint256 amountA,
        uint256 amountB,
        address user
    ) public {
        (uint256 actualA, uint256 acutalB, uint256 liquidity) = router01.addLiquidity(
            token0,
            token1,
            amountA,
            amountB,
            0,
            0,
            user,
            block.timestamp
        );

        chef.deposit(pid, liquidity);
    }
}
