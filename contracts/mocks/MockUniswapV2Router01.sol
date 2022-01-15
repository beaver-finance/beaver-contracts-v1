// SPDX-License-Identifier: MIT

pragma solidity =0.6.12;

import "../interfaces/IUniswapV2Router01.sol";
import "@boringcrypto/boring-solidity/contracts/libraries/BoringERC20.sol";
import "@boringcrypto/boring-solidity/contracts/libraries/BoringMath.sol";

import "hardhat/console.sol";

contract MockUniswapV2Router01 is IUniswapV2Router01 {
    using BoringERC20 for IERC20;
    using BoringMath for uint256;
    using BoringMath128 for uint128;

    constructor() public {}

    function factory() external pure override returns (address) {
        return address(1);
    }

    function WETH() external pure override returns (address) {
        return address(0);
    }

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    )
        external
        override
        returns (
            uint256 amountA,
            uint256 amountB,
            uint256 liquidity
        )
    {
        tokenA = address(0);
        tokenB = address(0);
        //amountADesired = 0;
        //amountBDesired = 0;
        amountAMin = 0;
        amountBMin = 0;
        to = address(0);
        deadline = 0;

        amountA = amountADesired - 1;
        amountB = amountBDesired - 1;
        liquidity = 1000;
    }

    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    )
        external
        payable
        override
        returns (
            uint256 amountToken,
            uint256 amountETH,
            uint256 liquidity
        )
    {
        token = address(0);
        amountTokenDesired = 0;
        amountTokenMin = 0;
        amountETHMin = 0;
        to = address(0);
        deadline = 0;

        amountToken = 0;
        amountETH = 0;
        liquidity = 0;
    }

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external override returns (uint256 amountA, uint256 amountB) {
        tokenA = address(0);
        tokenB = address(0);
        liquidity = 0;
        amountAMin = 0;
        amountBMin = 0;
        to = address(0);
        deadline = 0;

        amountA = 0;
        amountB = 0;
    }

    function removeLiquidityETH(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external override returns (uint256 amountToken, uint256 amountETH) {
        token = address(0);
        liquidity = 0;
        amountTokenMin = 0;
        amountETHMin = 0;
        to = address(0);
        deadline = 0;

        amountToken = 0;
        amountETH = 0;
    }

    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external override returns (uint256 amountA, uint256 amountB) {
        tokenA = address(0);
        tokenB = address(0);
        liquidity = 0;
        amountAMin = 0;
        amountBMin = 0;
        to = address(0);
        deadline = 0;
        approveMax = false;
        v = 0;
        r = 0;
        s = 0;

        amountA = 0;
        amountB = 0;
    }

    function removeLiquidityETHWithPermit(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external override returns (uint256 amountToken, uint256 amountETH) {
        token = address(0);
        liquidity = 0;
        amountTokenMin = 0;
        amountETHMin = 0;
        to = address(0);
        deadline = 0;
        approveMax = false;
        v = 0;
        r = 0;
        s = 0;

        amountToken = 0;
        amountETH = 0;
    }

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external override returns (uint256[] memory amounts) {
        if (path[0] == address(0)) {}
        //amountIn = 0;
        amountOutMin = 0;
        to = address(0);
        deadline = 0;
        amounts = new uint256[](2);
        amounts[0] = amountIn;
        amounts[0] = amountIn.add(10);
    }

    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external override returns (uint256[] memory amounts) {
        if (path[0] == address(0)) {}
        amountOut = 0;
        amountInMax = 0;
        to = address(0);
        deadline = 0;

        amounts[0] = amountOut;
        amounts[1] = amounts[0].add(10);
    }

    function swapExactETHForTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable override returns (uint256[] memory amounts) {
        if (path[0] == address(0)) {}
        amountOutMin = 0;
        to = address(0);
        deadline = 0;

        amounts[0] = amountOutMin;
        amounts[1] = amounts[0].add(10);
    }

    function swapTokensForExactETH(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external override returns (uint256[] memory amounts) {
        if (path[0] == address(0)) {}
        amountInMax = 0;
        amountOut = 0;
        to = address(0);
        deadline = 0;

        amounts[0] = amountOut;
        amounts[1] = amounts[0].add(10);
    }

    function swapExactTokensForETH(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external override returns (uint256[] memory amounts) {
        if (path[0] == address(0)) {}
        amountOutMin = 0;
        amountIn = 0;
        to = address(0);
        deadline = 0;

        amounts[0] = amountIn;
        amounts[1] = amounts[0].add(10);
    }

    function swapETHForExactTokens(
        uint256 amountOut,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable override returns (uint256[] memory amounts) {
        if (path[0] == address(0)) {}
        amountOut = 0;
        to = address(0);
        deadline = 0;

        amounts[0] = amountOut;
        amounts[1] = amounts[0].add(10);
    }

    function quote(
        uint256 amountA,
        uint256 reserveA,
        uint256 reserveB
    ) external pure override returns (uint256 amountB) {
        amountA = 0;
        reserveA = 0;
        reserveB = 0;

        return 0;
    }

    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure override returns (uint256 amountOut) {
        amountIn = 0;
        reserveIn = 0;
        reserveOut = 0;

        return 0;
    }

    function getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure override returns (uint256 amountIn) {
        reserveOut = 0;
        reserveIn = 0;
        amountOut = 0;

        return 0;
    }

    function getAmountsOut(uint256 amountIn, address[] calldata path)
        external
        view
        override
        returns (uint256[] memory amounts)
    {
        if (path[0] == address(0)) {}
        amountIn = 0;

        amounts[0] = amountIn;
        amounts[1] = amounts[0].add(10);
    }

    function getAmountsIn(uint256 amountOut, address[] calldata path)
        external
        view
        override
        returns (uint256[] memory amounts)
    {
        if (path[0] == address(0)) {}
        amountOut = 0;

        amounts[0] = amountOut;
        amounts[1] = amounts[0].add(10);
    }
}
