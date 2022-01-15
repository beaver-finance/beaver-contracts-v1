// SPDX-License-Identifier: MIT
pragma solidity =0.6.12;

import "../interfaces/AggregatorInterface.sol";
import "@boringcrypto/boring-solidity/contracts/libraries/BoringERC20.sol";
import "@boringcrypto/boring-solidity/contracts/libraries/BoringMath.sol";

import "hardhat/console.sol";

contract MockAggregator is AggregatorInterface {
    using BoringERC20 for IERC20;
    using BoringMath for uint256;
    using BoringMath128 for uint128;

    constructor() public {}

    function latestAnswer() external view override returns (int256) {
        return 1;
    }

    function latestTimestamp() external view override returns (uint256) {}

    function latestRound() external view override returns (uint256) {}

    function getAnswer(uint256 roundId) external view override returns (int256) {}

    function getTimestamp(uint256 roundId) external view override returns (uint256) {}

    event AnswerUpdated(int256 indexed current, uint256 indexed roundId, uint256 updatedAt);

    event NewRound(uint256 indexed roundId, address indexed startedBy, uint256 startedAt);
}
