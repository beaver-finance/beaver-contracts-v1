// SPDX-License-Identifier: MIT

pragma solidity =0.6.12;

pragma experimental ABIEncoderV2;

import "@boringcrypto/boring-solidity/contracts/libraries/BoringERC20.sol";
import "@boringcrypto/boring-solidity/contracts/libraries/BoringMath.sol";
import "@boringcrypto/boring-solidity/contracts/libraries/BoringRebase.sol";

import "@openzeppelin/contracts/utils/Pausable.sol";

import "./interfaces/IWETH.sol";
import "./strategy/IFarmPool.sol";
import "./libraries/IterableMapping.sol";
import "./BeaverPool.sol";
import "./strategy/Ownable.sol";

contract BeaverBox  is Ownable, Pausable{
    using BoringMath for uint256;
    using BoringMath128 for uint128;
    using BoringERC20 for IERC20;
    using RebaseLibrary for Rebase;

    // ************** //
    // *** EVENTS *** //
    // ************** //

    enum PoolType {
        LP,
        HEDGING
    }

    // event

    event LogDeposit(
        IERC20 indexed stakedToken,
        address indexed user,
        address beaverToken,
        uint256 pid,
        uint256 amount,
        uint256 mintShare,
        uint256 totalShare,
        uint256 reserve
    );

    event LogWithdraw(
        IERC20 indexed stakedToken,
        address indexed user,
        address beaverToken,
        uint256 pid,
        uint256 amount,
        uint256 burnShare,
        uint256 totalShare,
        uint256 reserve
    );

    event LogHarvest(
        IERC20 indexed stakedToken,
        IERC20 indexed rewardToken,
        address indexed user,
        address beaverToken,
        uint256 pid,
        uint256 amount
    );

    event LogPoolAdded(
        IERC20 indexed token0,
        IERC20 indexed token1,
        address indexed admin,
        PoolType poolType,
        uint256 pid
    );

    event LogPoolRemoved(
        IERC20 indexed token0,
        IERC20 indexed token1,
        address indexed admin,
        PoolType poolType,
        uint256 pid
    );

    event LogRegisterStrategy(address indexed strategy, uint256 pid);

    event LogFarmPoolAdded(
        IERC20 indexed stakedToken,
        address indexed farmPool,
        uint256 pid,
        uint256 tokenIndex,
        uint256 farmId
    );

    event LogFarmPoolRemoved(
        IERC20 indexed stakedToken,
        address indexed farmPool,
        uint256 pid,
        uint256 tokenIndex,
        uint256 farmId
    );

    event LogInvest(IERC20 indexed stakedToken, address indexed farmPool, uint256 pid, uint256 amount, uint256 reserve);

    event LogPayback(
        IERC20 indexed stakedToken,
        address indexed farmPool,
        uint256 pid,
        uint256 amount,
        uint256 reserve
    );

    // *************** //
    // *** STRUCTS *** //
    // *************** //

    struct BeaverBalance {
        uint256[] balance;
    }

    struct BeaverTokenStatus {
        uint256 total;
        uint256 share;
        uint256 remain;
    }

    struct BeaverPoolStatus {
        BeaverTokenStatus[] tokens;
    }

    // ******************************** //
    // *** CONSTANTS AND IMMUTABLES *** //
    // ******************************** //

    // ***************** //
    // *** VARIABLES *** //
    // ***************** //
    // pools def
    IterableMapping.Keys internal poolKeys;
    mapping(uint256 => BeaverPool) public pools;

    address private manager;

    bool public hasWhiteList;
    bool public hasHedgingWhiteList;
    mapping(address => bool) public allowedUsers;
    mapping(address => bool) public hedgingUsers;
    
    // ******************* //
    // *** CONSTRUCTOR *** //
    // ******************* //

    constructor() public {
        manager = owner;
    }

    // ***************** //
    // *** MODIFIERS *** //
    // ***************** //

    modifier poolExists(uint256 poolId) {
        require(address(pools[poolId]) != address(0), "pool not exists");
        _;
    }

    // ************************** //
    // *** PUBLIC FUNCTIONS ***   //
    // ************************** //
    function addHedgingWhiteList(address[] memory _user) public onlyKeeper{
        for(uint i=0;i<_user.length;i++){
            hedgingUsers[_user[i]] = true;
        }
        hasHedgingWhiteList = true;
    }

    function removeHedgingWhiteList(address _user) public onlyKeeper{
        hedgingUsers[_user] = false;
    }

    function disableHedgingWhiteList() public onlyKeeper{
        hasHedgingWhiteList = false;
    }

    function addUserWhiteList(address[] memory _user) public onlyKeeper{
        for(uint i=0;i<_user.length;i++){
            allowedUsers[_user[i]] = true;
        }
        hasWhiteList = true;
    }

    function removeUserWhiteList(address _user) public onlyKeeper{
        allowedUsers[_user] = false;
    }

    function disableWhiteList() public onlyKeeper{
        hasWhiteList = false;
    }

    function setClosed(bool t) public onlyOwner{
        if(t){
            _pause();
        }else{
            _unpause();
        }
    }

    // todo add revert for param check

    // lp pool operations
    function addLPPool(
        string memory _name,
        address token0,
        address token1
    ) public 
        onlyKeeper 
        whenNotPaused 
        returns (uint256 _pid, address _pool) 
    {
        (uint256 pid, BeaverPool pool) = newPool(_name, 2, token0, token1);
        _pid = pid;
        _pool = address(pool);
        emit LogPoolAdded(IERC20(token0), IERC20(token1), pool.owner(), PoolType.LP, _pid);
    }

    function removeLPPool(uint256 _pid) public 
        onlyKeeper 
        whenNotPaused 
        poolExists(_pid) 
    {
        BeaverPool pool = pools[_pid];
        emit LogPoolRemoved(pool.tokenFromIndex(0), pool.tokenFromIndex(1), pool.owner(), PoolType.LP, _pid);
        //delete pools[_pid];
        //IterableMapping.remove(poolKeys, _pid);
    }

    // hedging pool operations
    function addHedgingPool(string memory _name, address token0)
        public
        onlyKeeper
        whenNotPaused
        returns (uint256 _pid, address _pool)
    {
        (uint256 pid, BeaverPool pool) = newPool(_name, 1, token0, address(0));
        _pid = pid;
        _pool = address(pool);
        emit LogPoolAdded(IERC20(token0), IERC20(0), pool.owner(), PoolType.HEDGING, _pid);
    }

    function newPool(
        string memory _name,
        uint256 num,
        address token0,
        address token1
    ) internal returns (uint256 _pid, BeaverPool _pool) {
        _pid = IterableMapping.insert(poolKeys);
        _pool = new BeaverPool(_name, num, token0, token1, _pid);
        pools[_pid] = _pool;
    }

    function removeHedgingPool(uint256 _pid) public 
        onlyKeeper 
        whenNotPaused
        poolExists(_pid) 
    {
        BeaverPool pool = pools[_pid];
        emit LogPoolRemoved(pool.tokenFromIndex(0), IERC20(0), pool.owner(), PoolType.HEDGING, _pid);
        //delete pools[_pid];
        //IterableMapping.remove(poolKeys, _pid);
    }

    // pool operations
    function status(uint256 _pid, uint256 _tokenIndex)
        public
        view
        poolExists(_pid)
        returns (BeaverTokenStatus memory _status)
    {
        _status = _makeTokenStatus(pools[_pid], _tokenIndex);
    }

    function getPoolByPid(uint256 _pid) public view poolExists(_pid) returns (address pool) {
        pool = address(pools[_pid]);
    }

    function balanceOf(uint256 _pid, uint256 _tokenIndex)
        public
        view
        poolExists(_pid)
        returns (uint256 _amount)
    {
        _amount = pools[_pid].balanceOf(_tokenIndex, msg.sender);
    }

    function shareOf(uint256 _pid, uint256 _tokenIndex)
        public
        view
        poolExists(_pid)
        returns (uint256 _amount)
    {
        _amount = pools[_pid].shareOf(_tokenIndex, msg.sender);
    }

    function shareOfToBalance(uint256 _pid, uint256 _tokenIndex)
        public
        view
        poolExists(_pid)
        returns (uint256 _amount)
    {
        _amount = pools[_pid].shareOfToBalance(_tokenIndex, msg.sender);
    }

    function setTargetFundUtilizationRate(
        uint256 _pid,
        uint256 _tokenIndex,
        uint256 _rate
    ) 
        public 
        onlyKeeper 
        whenNotPaused 
        poolExists(_pid) 
    {
        pools[_pid].setTargetFundUtilizationRate(_tokenIndex, _rate);
    }

    function configLimit(
        uint256 _pid,
        uint256 _tokenIndex,
        uint256 t, uint256 u
    )
        public 
        onlyKeeper 
        whenNotPaused 
        poolExists(_pid) 
    {
        pools[_pid].configLimit(_tokenIndex,t,u);
    }

    function configDepositLimits(
        uint256 _pid,
        uint256 _tokenIndex,
        address[] calldata addr, uint256[] calldata u
    ) 
        public 
        onlyKeeper 
        whenNotPaused 
        poolExists(_pid) 
    {
        pools[_pid].configDepositLimits(_tokenIndex,addr,u);
    }


    function inWhiteList() internal view returns(bool){
        return (!hasWhiteList || allowedUsers[msg.sender]);
    }

    function inHedgingWhiteList() internal view returns(bool){
        return (!hasHedgingWhiteList || hedgingUsers[msg.sender]);
    }

    function deposit(
        uint256 _pid,
        uint256 _tokenIndex,
        uint256 _amount
    ) public
        whenNotPaused 
        poolExists(_pid) 
    {
        BeaverPool pool = pools[_pid];

        if(pool.totalTokensNum()<=1){
            require(inHedgingWhiteList(),"not in hedging list");
        }
        if(pool.totalTokensNum()>=2){
            require(inWhiteList(),"not in allow list");
        }

        pool.tokenFromIndex(_tokenIndex).safeTransferFrom(msg.sender, pool.walletFromIndex(_tokenIndex), _amount);
        (uint256 mint, uint256 total, uint256 reserve) = pool.deposit(_tokenIndex, msg.sender, _amount);

        emit LogDeposit(pool.tokenFromIndex(_tokenIndex), msg.sender, pools[_pid].walletFromIndex(_tokenIndex), _pid, _amount, mint, total, reserve);
    }

    function withdraw(
        uint256 _pid,
        uint256 _tokenIndex,
        uint256 _amount
    ) public 
        whenNotPaused 
        poolExists(_pid) 
    {
        (uint256 burn, uint256 total, uint256 reserve) = pools[_pid].withdraw(_tokenIndex, msg.sender, _amount);
        emit LogWithdraw(pools[_pid].tokenFromIndex(_tokenIndex),msg.sender, pools[_pid].walletFromIndex(_tokenIndex), _pid, _amount, burn, total, reserve);
    }

    function withdrawEmergency(
        uint256 _pid,
        uint256 _tokenIndex,
        uint256 _amount
    ) public 
        poolExists(_pid) 
    {
        (uint256 burn, uint256 total, uint256 reserve) = pools[_pid].withdrawEmergency(_tokenIndex, msg.sender, _amount);
        emit LogWithdraw(pools[_pid].tokenFromIndex(_tokenIndex),msg.sender, pools[_pid].walletFromIndex(_tokenIndex), _pid, _amount, burn, total, reserve);
    }

    function pendingReward(uint256 _pid, uint256 _tokenIndex)
        public
        view
        poolExists(_pid)
        returns (address _rewardToken, uint256 _amount)
    {
        (IERC20 rewardToken, uint256 amount) = pools[_pid].pendingReward(_tokenIndex, msg.sender);
        _rewardToken = address(rewardToken);
        _amount = amount;
    }

    function harvest(uint256 _pid, uint256 _tokenIndex) 
        public 
        poolExists(_pid) 
    {
        (IERC20 rewardToken, uint256 amount) = pools[_pid].harvest(_tokenIndex, msg.sender);
        emit LogHarvest(pools[_pid].tokenFromIndex(_tokenIndex),rewardToken, msg.sender, pools[_pid].walletFromIndex(_tokenIndex), _pid, amount);
    }

    function invest(
        uint256 _pid,
        uint256 _tokenIndex,
        uint256 farmId
    ) public 
        onlyKeeper 
        poolExists(_pid) 
    {
        (address _farmPool, uint256 _amount, uint256 _reserve) = pools[_pid].invest(_tokenIndex, farmId);
        emit LogInvest(pools[_pid].tokenFromIndex(_tokenIndex), _farmPool, _pid, _amount, _reserve);
    }

    // called by strategy, still here for testing
    function payback(
        uint256 _pid,
        uint256 _tokenIndex,
        uint256 _farmId,
        uint256 borrowed,
        uint256 amount
    ) public 
        onlyOwner 
        whenNotPaused 
        poolExists(_pid) 
    {
        //(address _farmPool, uint256 _amount, uint256 _reserve) = pools[_pid].payback(
        //    _tokenIndex,
        //    _farmId,
        //    borrowed,
        //    amount
        //);
        //emit LogPayback(pools[_pid].tokenFromIndex(_tokenIndex), _farmPool, _pid, _amount, _reserve);
    }

    function registerStrategyManager(uint256 _pid, address addr) public 
        onlyKeeper 
        whenNotPaused 
        poolExists(_pid) 
    {
        pools[_pid].registStrategyManager(addr);
        emit LogRegisterStrategy(addr, _pid);
    }

    function addFarmPool(
        uint256 _pid,
        uint256 _tokenIndex,
        address _farmPool,
        address router01
    ) public 
        onlyKeeper 
        whenNotPaused 
        poolExists(_pid) 
        returns (uint256 _farmId) 
    {
        _farmId = pools[_pid].addFarmPool(_tokenIndex, _farmPool, router01);
        emit LogFarmPoolAdded(pools[_pid].tokenFromIndex(_tokenIndex), _farmPool, _pid, _tokenIndex, _farmId);
    }

    function removeFarmPool(
        uint256 _pid,
        uint256 _tokenIndex,
        uint256 _farmId
    ) public 
        onlyKeeper 
        whenNotPaused 
        poolExists(_pid) 
        returns (address _farmPool) 
    {
        _farmPool = pools[_pid].removeFarmPool(_tokenIndex, _farmId);
        emit LogFarmPoolRemoved(
            pools[_pid].tokenFromIndex(_tokenIndex), 
            _farmPool, _pid, _tokenIndex, _farmId
        );
    }

    // ************************** //
    // *** INTERNAL FUNCTIONS *** //
    // ************************** //

    function _makeTokenStatus(BeaverPool pool, uint256 index) internal view returns (BeaverTokenStatus memory _status) {
        (uint256 totalElastic, uint256 totalBase, uint256 remain) = pool.tokenStatus(index);
        _status = BeaverTokenStatus(totalElastic, totalBase, remain);
    }
}
