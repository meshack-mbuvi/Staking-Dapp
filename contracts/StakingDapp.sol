// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract StakingDapp is Ownable, ReentrancyGuard {
  using SafeERC20 from IERC20;

  struct UserInfo {
    // Amount of tokens deposited
    uint256 amount;
    uint lastRewardAt;
    uint256 lockUntil;

  }

  struct PoolInfo {
    IER20 depositToken;
    IERC20 rewardToken;
    uint256 depositAmount;
    uint256 apy;
    uint256 lockDays;
  }

  struct Notification {
    uint256 poolID;
    uint256 amount;
    address user;
    string typeof;// claim, withdraw or deposit
    uint256 timestamp;
  }

  uint decimals = 10 ** 18;
  uint public poolCount = 10; // Total number of staking pools
  PoolInfo[] public poolInfo;

  // Balance of the user.
  mapping(address => uint256) public depositedTokens;
  mapping(uint256 => mapping(address=>UserInfo)) public userInfo;

  Notification[] public notifications;

  // CONTRACT FUNCTIONS
  function addPool(IERC20 _depositedToken, IERC20 _rewardToken, uint256 _apy, uint _lockDays ) public onlyOwner{
    // Get pool info
    poolInfo.push(PoolInfo(
      {
        depositedToken: _depositToken,
        rewardToken: _rewardToken,
        depositedAmount: 0,
        apy: _apy,
        lockDays: _lockDay
      }
    ));

    // Increment pool count
    poolCount ++;
  }

  // If user has some rewards, trasnfer them to the user and then 
  // add the user to the pool.
  function deposit(uint _pid, uint _amount) public nonReentrant{
    require(_amount > 0, "Amount should be greater than 0!");

    // Get specific pool and user info
    PoolInfo storage pool = poolInfo[_pid];
    UserInfo storage user = userInfo[_pid][msg.sender];

    if(user.amount > 0){
      uint pending = _calcPendingReward(user, _pid);
      pool.rewardToken.transfer(msg.sender, pending);
      _createNotification( _pid, pending, msg.sender, "Claim");
    }

    // Deposit tokens
    pool.depositToken.transferFrom(msg.sender, address(this), _amount);

    pool.depositedAmount += _amount;

    user.amount += _amount;
    user.lastRewardAt = block.timestamp;
    // user.lockUntil = block.timestamp + (pool.lockDays * 86400); // 1 day
    user.lockUntil = block.timestamp + (pool.lockDays * 60); // 1 minute

    // Increment deposited tokens
    depositedTokens[address(pool.depositToken)] += _amount;
      _createNotification( _pid, _amount, msg.sender, "Deposit");

  }

  function withdraw(uint _pid, uint _amount) public nonReentrant{
    PoolInfo storage pool = poolInfo[_pid];
    UserInfo storage user = userInfo[_pid][msg.sender];
    require(user.amount >= 0, "Withdraw amount exceeds the balance.");
    require(user.lockUntil <= block.timestamp, "Lock is active!");

    uint256 pending = _calcPendingReward(user, _pid);

    if(user.amount > 0){
      pool.rewardToken.transfer(msg.sender, pending);
      _createNotification( _pid, pending, msg.sender, "Claim");
    }

    // Withdraw logic
    if(_amount > 0){
      // reduce the amount of the user and pool
      user.amount -= _amount;
      pool.depositToken -= _amount;
      // Reduce depositedTokens by the amount withdrawn.
      depostedTokens[address(pool.depositToken)] = _amount;

      pool.depositToken.transfer(msg.sender, amount);
    }
    // Update latest reward.
    user.lastRewardAt = block.timestamp;
    _createNotification( _pid, _amount, msg.sender, "Withdraw");
  }

  function _calcPendingReward(UserInfo storage user, uint _pid) internal view 
  returns (uint256)
  {
    // Get the pool
    PoolInfo storage pool = poolInfo[_pid];
    // Calculate days past
    // uint daysPassed = (block.timestamp - user.lastRewardAt) / 86400;
    uint daysPassed = (block.timestamp - user.lastRewardAt) / 60;// 1 minute

    if(daysPassed > pool.lockDays){
      daysPassed = pool.lockDays;
    }

    // user amount deposited * % apy per year 
    return user.amount * daysPassed / 365 / 100 * pool.apy;

  }

  function pendingReward(uint _pid, address _user)public view returns(uint){
    UserInfo storage user = userInfo[_pid][_user];

    return _calcPendingReward(user, _pid);
  }

  // Address and quantity of the token
  function sweep(address token, uint256 _amount) external onlyOwner{
    uint256 token_balance = IERC20(token).balanceOf(address(this));

    require(amount <= token_balance, "Amount exceeds bakance");
    require(token_balance - amount >= depositedTokens[tokens], "Can't withdraw deposited tokens")
  }

  function modifyPool(){}

  function claimReward(){}
  function createNotification(){}
  function getNotification(){}

}