// SPDX-License-Identifier: MIT
pragma solidity >=0.6.12;
pragma experimental ABIEncoderV2;

import "./BeaverPoolToken.sol";
import "@boringcrypto/boring-solidity/contracts/libraries/BoringRebase.sol";

contract BeaverPool is Ownable{
    using BoringMath for uint256;
    using BoringMath128 for uint128;
    using BoringERC20 for IERC20;
    using RebaseLibrary for Rebase;

    // *************** //
    // *** STRUCTS *** //
    // *************** //

    // ***************** //
    // *** VARIABLES *** //
    // ***************** //

    string public name;
    mapping(uint256 => BeaverPoolToken) public tokens;
    uint256 public totalTokensNum;

    address public strategyManager;
    uint256 public pid;

    // ******************* //
    // *** CONSTRUCTOR *** //
    // ******************* //

    constructor(
        string memory _name,
        uint256 num,
        address _token0,
        address _token1,
        uint256 _pid
    ) public {
        pid = _pid;
        name = _name;
        totalTokensNum = num;
        uint256 tokenType = _getPoolType();
        if (num > 0) {
            tokens[0] = BeaverPoolToken(_token0);
            tokens[0].init(tokenType, pid);
        }
        if (num > 1) {
            tokens[1] = BeaverPoolToken(_token1);
            tokens[1].init(tokenType, pid);
        }
    }

    // ***************** //
    // *** MODIFIERS *** //
    // ***************** //

    modifier validIndex(uint256 index) {
        require(totalTokensNum > index, "index too big");
        _;
    }

    // ************************** //
    // *** PUBLIC FUNCTIONS ***   //
    // ************************** //

    function tokenStatus(uint256 _tokenIndex)
        public
        view
        validIndex(_tokenIndex)
        returns (
            uint256 _elastic,
            uint256 _base,
            uint256 _remain
        )
    {
        return tokens[_tokenIndex].status();
    }

    function tokenFromIndex(uint256 _tokenIndex) public view validIndex(_tokenIndex) returns (IERC20) {
        return tokens[_tokenIndex].token();
    }

    function walletFromIndex(uint256 _tokenIndex) public view validIndex(_tokenIndex) returns (address) {
        return address(tokens[_tokenIndex]);
    }

    function balanceOf(uint256 _tokenIndex, address user) public view validIndex(_tokenIndex) returns (uint256) {
        // can not be balance directly
        // token saves share in it
        // need to rebase
        return tokens[_tokenIndex].shareOfToBalance(user);
    }

    function shareOf(uint256 _tokenIndex, address user) public view validIndex(_tokenIndex) returns (uint256) {
        return tokens[_tokenIndex].shareOf(user);
    }

    function shareOfToBalance(uint256 _tokenIndex, address user) public view validIndex(_tokenIndex) returns (uint256) {
        return tokens[_tokenIndex].shareOfToBalance(user);
    }

    function setTargetFundUtilizationRate(uint256 _tokenIndex, uint256 _rate) public onlyOwner validIndex(_tokenIndex) {
        tokens[_tokenIndex].setTargetFundUtilizationRate(_rate);
    }

    function configLimit(uint256 _tokenIndex, uint256 t, uint256 u) public onlyOwner validIndex(_tokenIndex) {
        tokens[_tokenIndex].configLimit(t,u);
    }

    function registStrategyManager(address addr) public onlyOwner {
        strategyManager = addr;
    }

    function deposit(
        uint256 _tokenIndex,
        address user,
        uint256 _amount
    )
        public
        onlyOwner
        validIndex(_tokenIndex)
        returns (
            uint256 _mint,
            uint256 _total,
            uint256 _reserve
        )
    {
        (uint256 mint, uint256 total, uint256 reserve) = tokens[_tokenIndex].deposit(user, _amount);
        _mint = mint;
        _total = total;
        _reserve = reserve;
    }

    function withdraw(
        uint256 _tokenIndex,
        address user,
        uint256 _amount
    )
        public
        onlyOwner
        validIndex(_tokenIndex)
        returns (
            uint256 _burn,
            uint256 _total,
            uint256 _reserve
        )
    {
        (uint256 burn, uint256 total, uint256 reserve) = tokens[_tokenIndex].withdraw(user, _amount);
        _burn = burn;
        _total = total;
        _reserve = reserve;
    }
    
    function withdrawEmergency(
        uint256 _tokenIndex,
        address user,
        uint256 _amount
    )
        public
        onlyOwner
        validIndex(_tokenIndex)
        returns (
            uint256 _burn,
            uint256 _total,
            uint256 _reserve
        )
    {
        (uint256 burn, uint256 total, uint256 reserve) = tokens[_tokenIndex].withdrawEmergency(user, _amount);
        _burn = burn;
        _total = total;
        _reserve = reserve;
    }

    function pendingReward(uint256 _tokenIndex, address user)
        public
        view
        onlyOwner
        validIndex(_tokenIndex)
        returns (IERC20 _rewardToken, uint256 _amount)
    {
        (IERC20 rewardToken, uint256 amount) = tokens[_tokenIndex].pendingReward(user);
        _rewardToken = rewardToken;
        _amount = amount;
    }

    function harvest(uint256 _tokenIndex, address user)
        public
        onlyOwner
        validIndex(_tokenIndex)
        returns (IERC20 _rewardToken, uint256 _amount)
    {
        (IERC20 rewardToken, uint256 amount) = tokens[_tokenIndex].harvest(user);
        _rewardToken = rewardToken;
        _amount = amount;
    }

    function invest(uint256 _tokenIndex, uint256 _farmId)
        public
        onlyOwner
        validIndex(_tokenIndex)
        returns (
            address _farmPool,
            uint256 _amount,
            uint256 _reserve
        )
    {
        (address farmPool, uint256 amount, uint256 reserve) = tokens[_tokenIndex].invest(_farmId);
        _farmPool = farmPool;
        _amount = amount;
        _reserve = reserve;
    }

    // called by strategy, still here for testing
    function payback(
        uint256 _tokenIndex,
        uint256 _farmId,
        uint256 borrowed,
        uint256 paybackAmount
    )
        public
        onlyOwner
        validIndex(_tokenIndex)
        returns (
            address _farmPool,
            uint256 _amount,
            uint256 _reserve
        )
    {
        (address farmPool, uint256 amount, uint256 reserve) = tokens[_tokenIndex].payback(
            _farmId,
            borrowed,
            paybackAmount
        );
        _farmPool = farmPool;
        _amount = amount;
        _reserve = reserve;
    }

    function addFarmPool(
        uint256 _tokenIndex,
        address _pool,
        address router01
    ) public onlyOwner validIndex(_tokenIndex) returns (uint256 _farmId) {
        _farmId = tokens[_tokenIndex].addFarmPool(_pool, router01);
    }

    function removeFarmPool(uint256 _tokenIndex, uint256 _farmId)
        public
        onlyOwner
        validIndex(_tokenIndex)
        returns (address _farmPool)
    {
        _farmPool = tokens[_tokenIndex].removeFarmPool(_farmId);
    }

    function _getPoolType() internal view returns (uint256 _type) {
        //hp is 2
        _type = 2;
        //lp is 1
        if (totalTokensNum == 2) {
            _type = 1;
        }
    }
}
