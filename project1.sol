// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract ScholarshipStaking {
    struct Staker {
        uint256 stakedAmount;
        uint256 rewardDebt;
        uint256 lastStakedTime;
    }

    address public owner;
    uint256 public totalStaked;
    uint256 public rewardPool;
    uint256 public rewardRatePerSecond; // Rewards per second
    mapping(address => Staker) public stakers;

    event Stake(address indexed user, uint256 amount);
    event Unstake(address indexed user, uint256 amount);
    event ClaimReward(address indexed user, uint256 reward);
    event FundScholarship(address indexed recipient, uint256 amount);

    modifier onlyOwner() {
        require(msg.sender == owner, "Not authorized");
        _;
    }

    constructor(uint256 _rewardRatePerSecond) {
        owner = msg.sender;
        rewardRatePerSecond = _rewardRatePerSecond;
    }

    function stake() external payable {
        require(msg.value > 0, "Amount must be greater than 0");

        Staker storage staker = stakers[msg.sender];

        if (staker.stakedAmount > 0) {
            uint256 pendingReward = calculateReward(msg.sender);
            staker.rewardDebt += pendingReward;
        }

        staker.stakedAmount += msg.value;
        staker.lastStakedTime = block.timestamp;
        totalStaked += msg.value;

        emit Stake(msg.sender, msg.value);
    }

    function unstake(uint256 amount) external {
        Staker storage staker = stakers[msg.sender];
        require(staker.stakedAmount >= amount, "Insufficient staked amount");

        uint256 pendingReward = calculateReward(msg.sender);
        staker.rewardDebt += pendingReward;
        staker.stakedAmount -= amount;
        totalStaked -= amount;

        payable(msg.sender).transfer(amount);

        emit Unstake(msg.sender, amount);
    }

    function claimReward() external {
        Staker storage staker = stakers[msg.sender];

        uint256 reward = calculateReward(msg.sender) + staker.rewardDebt;
        require(reward > 0, "No rewards to claim");

        staker.rewardDebt = 0;
        staker.lastStakedTime = block.timestamp;
        rewardPool -= reward;

        payable(msg.sender).transfer(reward);

        emit ClaimReward(msg.sender, reward);
    }

    function calculateReward(address user) public view returns (uint256) {
        Staker storage staker = stakers[user];
        uint256 stakedTime = block.timestamp - staker.lastStakedTime;
        return stakedTime * rewardRatePerSecond * staker.stakedAmount / 1 ether;
    }

    function fundRewardPool() external payable onlyOwner {
        rewardPool += msg.value;
    }

    function fundScholarship(address recipient, uint256 amount) external onlyOwner {
        require(amount <= rewardPool, "Insufficient reward pool");
        rewardPool -= amount;

        payable(recipient).transfer(amount);

        emit FundScholarship(recipient, amount);
    }

    function updateRewardRate(uint256 newRate) external onlyOwner {
        rewardRatePerSecond = newRate;
    }
}