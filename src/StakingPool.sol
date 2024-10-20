// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

import "../lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

error ZERO_AMOUNT();
error INSUFFICIENT_TOKEN();
error INSUFFICIENT_STAKED_TOKEN();
error NO_REWARD();
error INVALID_POOL();

contract StakingPool {

    struct Pool {
        IERC20 stakingToken;   
        uint rewardRate;       
        uint totalStaked;       
        uint poolDuration;      
        bool isActive;          
    }

    struct StakerData {
        uint totalStaked;
        uint lastStakedTimestamp;
        uint reward;
    }
    uint256 public MinimumStake=5;
    // Pool ID mapped to Pool information
    mapping(uint256 => Pool) public pools;
    // Staker data for each user in each pool
    mapping (address => mapping(uint256 => StakerData)) public stakers;
    mapping(uint => uint) public test;

    uint public poolCount;

    // Events
    event PoolCreated(uint poolId, address stakingToken, uint rewardRate, uint duration);
    event Staked(uint poolId, address user, uint amount);
    event Unstaked(uint poolId, address user, uint amount);
    event RewardClaimed(uint poolId, address user, uint reward);

    // Create a new staking pool
    function createPool(IERC20 _token, uint _rewardRate, uint _duration) external {
        pools[poolCount] = Pool({
            stakingToken: _token,
            rewardRate: _rewardRate,
            totalStaked: 0,
            poolDuration: _duration,
            isActive: true
        });

        emit PoolCreated(poolCount, address(_token), _rewardRate, _duration);
        poolCount++;
    }

    // Stake tokens in a specific pool
    function stake(uint poolId, uint amount) external {
        if (amount < 1) revert ZERO_AMOUNT();
        Pool storage pool = pools[poolId];
        if (!pool.isActive) revert INVALID_POOL();
        if (pool.stakingToken.balanceOf(msg.sender) < amount) revert INSUFFICIENT_TOKEN();

        pool.stakingToken.transferFrom(msg.sender, address(this), amount);

        // Update staker's data
        StakerData storage staker = stakers[msg.sender][poolId];
        staker.reward += calculateReward(poolId, msg.sender);
        staker.totalStaked += amount;
        staker.lastStakedTimestamp = block.timestamp;

        pool.totalStaked += amount;

        emit Staked(poolId, msg.sender, amount);
    }

    // Unstake tokens from a specific pool
    function unstake(uint poolId, uint amount) external {
        StakerData storage staker = stakers[msg.sender][poolId];
        if (amount > staker.totalStaked) revert INSUFFICIENT_STAKED_TOKEN();

        Pool storage pool = pools[poolId];
        staker.reward += calculateReward(poolId, msg.sender);
        staker.totalStaked -= amount;
        staker.lastStakedTimestamp = block.timestamp;

        pool.totalStaked -= amount;
        pool.stakingToken.transfer(msg.sender, amount);

        emit Unstaked(poolId, msg.sender, amount);
    }

    // Calculate rewards for a user in a specific pool
    function calculateReward(uint poolId, address user) public view returns (uint) {
        Pool storage pool = pools[poolId];
        StakerData storage staker = stakers[user][poolId];

        uint stakingDuration = block.timestamp - staker.lastStakedTimestamp;
        uint calculatedReward = (staker.totalStaked * pool.rewardRate) * stakingDuration / 1e18;

        return calculatedReward;
    }

    // Claim rewards from a specific pool
    function claimReward(uint poolId) external {
        StakerData storage staker = stakers[msg.sender][poolId];
        uint reward = staker.reward + calculateReward(poolId, msg.sender);

        if (reward < 1) revert NO_REWARD();

        staker.reward = 0;
        staker.lastStakedTimestamp = block.timestamp;

        Pool storage pool = pools[poolId];
        pool.stakingToken.transfer(msg.sender, reward);

        emit RewardClaimed(poolId, msg.sender, reward);
    }

    // Fetch user's staking info for a specific pool
    function getStakeInfo(uint poolId, address user) external view returns (StakerData memory) {
        return stakers[user][poolId];
    }

    // Pause a specific pool (Admin function)
    function pausePool(uint poolId) external {
        pools[poolId].isActive = false;
    }

    // Resume a specific pool (Admin function)
    function resumePool(uint poolId) external {
        pools[poolId].isActive = true;
    }
}
