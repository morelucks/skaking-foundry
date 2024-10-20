// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

import "forge-std/Test.sol";
import "../lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import "../src/StakingPool.sol"; // Adjust the import path as needed
import {console} from "forge-std/Test.sol";
contract MockToken is ERC20 {
    constructor() ERC20("MockToken", "MTK") {
        _mint(msg.sender, 1000 * 10 ** decimals()); // Mint 1000 tokens to the deployer
    }

    function mint(address user, uint amount) external {
        _mint(user, amount);
    }
}


contract StakingPoolTest is Test {
    StakingPool stakingPool;
    MockToken public mockToken;
    uint256 number=1;
    address user = address(0x123);
    uint256 poolId;


    address owner = address(this);
    address addr1 = address(0x1);
    address addr2 = address(0x2);

    function setUp() public {
        // Deploy the mock token and staking pool
        mockToken = new MockToken();
        stakingPool = new StakingPool();
        number=2;
        // Create a pool for testing
        poolId = 0;
        stakingPool.createPool(mockToken, 1e18, 100); // Reward rate 1 token per second, 100 seconds duration
    }

 function testUnstake() public {
        vm.prank(addr1);
        stakingPool.unstake(0, 50); // Unstake 50 tokens

        StakingPool.StakerData memory stakerData = stakingPool.getStakeInfo(0, addr1);
        assertEq(stakerData.totalStaked, 50); // 100 - 50
        assertEq(mockToken.balanceOf(addr1), 950); // 1000 - 50
    }
    function testMinimum() external{
        assertEq(stakingPool.MinimumStake(), 5);
    }
    function testPoolCount()external{
        uint expectedpoolCount=1;
        assertEq(stakingPool.poolCount(), expectedpoolCount);
    }
    function testDemo()external{
        console.log("this passes");

        assertEq(number, 2);
    }
     function testCreatePool() public {
            uint256 duration = 30 * 24 * 60 * 60; // Define the duration in seconds

        stakingPool.createPool(mockToken, 1e18, 30 days);
        (IERC20 token, uint rewardRate, uint totalStaked, uint poolDuration, bool isActive) = (
            stakingPool.pools(0)
        );

        assertEq(address(token), address(mockToken), "Staking token should match");
        assertEq(rewardRate, 1e18, "Reward rate should match");
        assertEq(totalStaked, 0, "Total staked should be zero");
        // assertEq(poolDuration, duration, "Pool duration should match");
        assertTrue(isActive, "Pool should be active");
    }

    function testStake() public {
        vm.startPrank(user); // Start impersonating the user

        mockToken.mint(user, 200);

        // Approve tokens for staking
        mockToken.approve(address(stakingPool), 100); // Approve 100 tokens for staking
        stakingPool.stake(poolId, 100); // Stake 100 tokens

        stakingPool.test(poolId);

        // Retrieve staker data correctly
        // stakingPool.StakerData storage staker = stakingPool.stakers[user][poolId];
        // StakingPool.StakerData memory staker = StakingPool.stakers(user, poolId);

        // assertEq(staker.totalStaked, 100); // Check that total staked is 100
        // assertEq(staker.reward, 0); // Check that the reward is 0 initially

        // Check that the pool's total staked is 100
        // assertEq(stakingPool.pools(poolId).totalStaked, 100); 

        vm.stopPrank(); // Stop impersonating the user
    }
}
