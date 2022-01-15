// SPDX-License-Identifier: MIT

pragma solidity =0.6.12;

pragma experimental ABIEncoderV2;

import "@boringcrypto/boring-solidity/contracts/libraries/BoringERC20.sol";
import "@boringcrypto/boring-solidity/contracts/libraries/BoringRebase.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

import "./interfaces/IUniswapV2Router01.sol";
import "./interfaces/IEmergency.sol";
import "./BeaverERC20.sol";
import "./strategy/Ownable.sol";
import "./strategy/IFarmPool.sol";
import "./libraries/IterableMapping.sol";
import "hardhat/console.sol";

contract BeaverPoolToken is Ownable, BeaverERC20, IEmergency, ReentrancyGuard{
    using BoringMath for uint256;
    using BoringMath128 for uint128;
    using BoringERC20 for IERC20;
    using RebaseLibrary for Rebase;

    // *************** //
    // *** STRUCTS *** //
    // *************** //

    event LogPayback(
        IERC20 indexed stakedToken,
        address indexed farmPool,
        uint256 pid,
        uint256 borrowed,
        uint256 amount,
        uint256 remain,
        uint256 total
    );

    struct UserInfo {
        uint256 amount;
        uint256 rewardDebt;

        uint256 balance;
    }

    // ***************** //
    // *** VARIABLES *** //
    // ***************** //
    uint256 public tokenType;

    IERC20 public token;
    uint256 public remain;
    uint256 public targetFundUtilizationRate; //50 means 50%

    Rebase public total;
    mapping(address => UserInfo) public shares;
    uint256 public accRewardPerShare;

    IterableMapping.Keys private farmKeys;
    mapping(uint256 => address) public farmPools;
    mapping(uint256 => bool) public investing;
    mapping(uint256 => IUniswapV2Router01) public routers;

    uint256 public pid;

    uint256 public totalLimit;
    uint256 public userLimit;
    bool public emergency;

    mapping(address => uint256) public depositLimits;



    // ******************* //
    // *** CONSTRUCTOR *** //
    // ******************* //

    constructor(string memory _name, address _token) public BeaverERC20(_name){
        name = _name;
        token = IERC20(_token);
        targetFundUtilizationRate = 100;
    }

    // ***************** //
    // *** MODIFIERS *** //
    // ***************** //

    modifier inited() {
        require(tokenType > 0, "not init");
        _;
    }


    modifier notEmergency() {
        require(!emergency, "is emergency");
        _;
    }

    modifier onlyEmergency() {
        require(emergency, "not emergency");
        _;
    }

    // ************************** //
    // *** PUBLIC FUNCTIONS ***   //
    // ************************** //

    function status()
        public
        view
        returns (
            uint256 _elastic,
            uint256 _base,
            uint256 _remain
        )
    {
        _elastic = total.elastic;
        _base = total.base;
        _remain = remain;
    }

    function shareOf(address user) public view inited returns (uint256) {
        return shares[user].amount;
    }

    function shareOfToBalance(address user) public view inited returns (uint256) {
        return total.toElastic(shares[user].amount, true);
    }

    //may recall when deploy exception for retry, but it only can be init once
    function init(uint256 _type, uint256 _pid) public {
        if (tokenType == 0) {
            tokenType = _type;
            pid = _pid;
            _addCaller(msg.sender);
        }
    }

    function configDepositLimits(address[] calldata addr, uint256[] calldata u) public inited onlyCaller {
        for(uint i=0;i<addr.length;i++){
            depositLimits[addr[i]] = u[i];
        }
    }

    function configLimit(uint256 t, uint256 u) public inited onlyCaller {
        totalLimit = t;
        userLimit = u;
    }

    function setTargetFundUtilizationRate(uint256 _rate) public inited onlyCaller {
        require(_rate <= 100, "must percent value");
        targetFundUtilizationRate = _rate;
    }

    function deposit(address user, uint256 _amount)
        public
        inited
        onlyCaller
        nonReentrant
        notEmergency
        returns (
            uint256 _minted,
            uint256 _total,
            uint256 _reserve
        )
    {
        // update reward first
        harvest(user);

        uint256 share = total.toBase(_amount, false);
        
        UserInfo memory info = shares[user];
        info.balance = info.balance.add(_amount);

        if(depositLimits[user]>0){
            require(info.balance<=depositLimits[user],"exceed user limit");
        }
        if(userLimit>0){
            require(info.balance<=userLimit,"exceed user default limit");
        }

        total.elastic = total.elastic.add(_amount.to128());
        if(totalLimit>0){
            require(total.elastic<=totalLimit,"exceed total limit");
        }

        // update total share and amount
        total.base = total.base.add(share.to128());

        // update tokens status
        remain = remain.add(_amount);

        // update user share and reward debt
        info.amount = info.amount.add(share);
        info.rewardDebt = info.amount.mul(accRewardPerShare) / 1e12;
        shares[user] = info;
        _mint(user, share);

        _minted = share;
        _total = info.amount;
        _reserve = info.amount;
    }

    function withdraw(address user, uint256 _amount)
        public
        inited
        onlyCaller
        nonReentrant
        notEmergency
        returns (
            uint256 _burned,
            uint256 _total,
            uint256 _reserve
        )
    {
        // remain is the total amount in pool for withdraw
        require(remain >= _amount, "no enougth token");

        // update reward first
        harvest(user);

        uint256 share = total.toBase(_amount, false);

        UserInfo memory info = shares[user];

        info.balance = info.balance.sub(_amount);
        if (info.amount <= share) {
            share = info.amount;
            _amount = total.toElastic(share, true);
            info.balance = 0;
        }

        _burn(user, share);


        // update total share and amount
        total.base = total.base.sub(share.to128());
        total.elastic = total.elastic.sub(_amount.to128());
        // transfer and update token status

        token.safeTransfer(user, _amount);
        remain = remain.sub(_amount);
        //update use share and reward debt
        info.amount = info.amount.sub(share);
        info.rewardDebt = info.amount.mul(accRewardPerShare) / 1e12;
        shares[user] = info;

        _burned = share;
        _total = info.amount;
        _reserve = info.amount;

        // clean user share when it is 0
        if (info.amount <= 0) {
            delete shares[user];
        }
    }

    function paybackEmergency() public override
        inited
        onlyCaller
    {
        emergency = true;
        total.elastic = token.balanceOf(address(this)).to128();
    }

    function withdrawEmergency(address user, uint256 _amount)
        public
        inited
        onlyCaller
        onlyEmergency
        nonReentrant
        returns (
            uint256 _burned,
            uint256 _total,
            uint256 _reserve
        )
    {

        uint256 share = total.toBase(_amount, false);

        UserInfo memory info = shares[user];
        if (info.amount < share) {
            share = info.amount;
            _amount = total.toElastic(share, true);
        }
        // update total share and amount
        total.base = total.base.sub(share.to128());
        total.elastic = total.elastic.sub(_amount.to128());
        // transfer and update token status
        token.safeTransfer(user, _amount);
        info.amount = info.amount.sub(share);
        shares[user] = info;

        _burned = share;
        _total = info.amount;
        _reserve = info.amount;
    }

    function pendingReward(address user) public view 
        inited 
        onlyCaller
        notEmergency
        returns (IERC20 _rewardToken, uint256 _amount) 
    {
        _rewardToken = token;
        _amount = 0;
        if (total.base > 0) {
            uint256 farmId = 1;
            address farmAddr = farmPools[farmId];
            uint256 pendingRewardPerShare = accRewardPerShare;
            if (farmAddr != address(0) && investing[farmId]) {
                (address rewardToken, uint256 rewardAmount) = IFarmPool(farmAddr).pendingReward();
                _rewardToken = IERC20(rewardToken);

                pendingRewardPerShare = pendingRewardPerShare.add(rewardAmount.mul(1e12) / total.base);

                if (user != address(0)) {
                    UserInfo memory info = shares[user];
                    uint256 pending = (info.amount.mul(pendingRewardPerShare) / 1e12).sub(info.rewardDebt);
                    _amount = _amount.add(pending);
                }
            }
        }
    }

    function _harvest(
        IUniswapV2Router01 router01,
        address rewardToken,
        uint256 rewardAmount
    ) internal returns(IERC20 _rewardToken){
        // lp uses the default reward token
        if (tokenType == 1) {
            accRewardPerShare = accRewardPerShare.add(rewardAmount.mul(1e12) / total.base);
            _rewardToken = IERC20(rewardToken);
        }
        // hp need swap the reward token to the invest token
        if (tokenType == 2) {
            address[] memory path = new address[](2);
            path[0] = rewardToken;
            path[1] = address(token);
            if (address(router01) != address(0)) {
                // use swap when set the router
                uint256[] memory amounts = router01.swapExactTokensForTokens(
                    rewardAmount,
                    0,
                    path,
                    address(this),
                    block.timestamp
                );
                accRewardPerShare = accRewardPerShare.add(amounts[1].mul(1e12) / total.base);
                _rewardToken = token;
            } else {
                // else use the default reward token
                accRewardPerShare = accRewardPerShare.add(rewardAmount.mul(1e12) / total.base);
                _rewardToken = IERC20(rewardToken);
            }
        }
    }

    function harvest(address user) public 
        inited 
        onlyCaller 
        notEmergency
        returns (IERC20 _rewardToken, uint256 _amount) 
    {
        _rewardToken = token;
        _amount = 0;

        if (total.base > 0) {
            uint256 farmId = 1; //IterableMapping.get(farmKeys, i);
            address farmAddr = farmPools[farmId];
            if (farmAddr != address(0) && investing[farmId]) {
                (address rewardToken, uint256 rewardAmount) = IFarmPool(farmAddr).harvest();

                _rewardToken = _harvest(routers[farmId], rewardToken, rewardAmount);

                //transfer to user when user call harvest
                //do nothing when payback or other owner called function
                if (user != address(0)) {
                    UserInfo memory info = shares[user];
                    uint256 pending = (info.amount.mul(accRewardPerShare) / 1e12).sub(info.rewardDebt);
                    if (pending > 0) {
                        _rewardToken.safeTransfer(user, pending);
                        info.rewardDebt = info.amount.mul(accRewardPerShare) / 1e12;
                        shares[user] = info;
                        _amount = _amount.add(pending);
                    }
                }
            }
        }
    }

    function invest(uint256 _farmId)
        public
        inited
        onlyCaller
        nonReentrant
        notEmergency
        returns (
            address _farmPool,
            uint256 _amount,
            uint256 _reserve
        )
    {
        require(_farmId == 1, "only one farm");

        uint256 amount = targetFundUtilizationRate.mul(remain) / 100; //need safemath later

        require(remain >= amount, "no enougth token");
        _farmPool = farmPools[_farmId];
        _amount = amount;
        _reserve = amount;

        require(_farmPool != address(0), "farm pool not exists");

        remain = remain.sub(_amount);

        token.safeTransfer(_farmPool, _amount);
        IFarmPool(_farmPool).skim(_amount);
        investing[_farmId] = true;
    }

    function payback(
        uint256 _farmId,
        uint256 borrowed,
        uint256 amount
    )
        public
        inited
        onlyCaller
        nonReentrant
        notEmergency
        returns (
            address _farmPool,
            uint256 _amount,
            uint256 _reserve
        )
    {
        require(_farmId == 1, "only one farm");

        _farmPool = farmPools[_farmId];
        _amount = amount;
        _reserve = 0;

        require(_farmPool != address(0), "farm pool not exists");
        require(total.elastic >= borrowed.to128(), "borrowed too many");

        //todo
        //_harvest(routers[_farmId],rewardToken,rewardAmount);
        investing[_farmId] = false;

        remain = remain.add(_amount);
        total.elastic = total.elastic.add(_amount.to128());
        total.elastic = total.elastic.sub(borrowed.to128());

        emit LogPayback(token, _farmPool, pid, borrowed, amount, remain, total.elastic);
    }

    function addFarmPool(address _pool, address router01) public inited onlyCaller returns (uint256 _farmId) {
        require(IFarmPool(_pool).tokenAddr() == address(token), "must same token");

        _farmId = 1; //IterableMapping.insert(farmKeys);

        require(farmPools[_farmId] == address(0), "only one farm");

        _addCaller(_pool);
        _addCaller(IFarmPool(_pool).getOwner());

        farmPools[_farmId] = _pool;
        investing[_farmId] = false;
        routers[_farmId] = IUniswapV2Router01(router01);
    }

    function removeFarmPool(uint256 _farmId) public inited onlyCaller returns (address _farmPool) {
        _farmPool = farmPools[_farmId];
        require(_farmPool != address(0), "farm pool not exists");
        require(investing[_farmId] == false, "farm pool need payback first");

        //_setKeeper(_farmPool, false);

        //delete farmPools[_farmId];
        //delete investing[_farmId];
        //delete routers[_farmId];
        //IterableMapping.remove(farmKeys, _farmId);
    }
}
