// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/// @title AgentStreak
/// @notice Daily check-in for Binance Agent ID holders (SPACE ID Agent ID, ERC-721).
/// @dev A holder checks in at most once per UTC day. Consecutive days build a
/// streak; missing a day resets it to 1 on the next check-in. Streaks and
/// check-in counts are on-chain reputation only: they have no cash value, no
/// token is issued, and no reward of any kind is promised.
/// The contract holds no funds and has no owner functions: there is nothing
/// to mint, pause, withdraw, or change after deployment.
interface IAgentID {
    function balanceOf(address owner) external view returns (uint256);
}

contract AgentStreak {
    error NotAgentIDHolder();
    error AlreadyCheckedInToday();

    /// @notice SPACE ID Agent ID contract on BNB Chain.
    IAgentID public immutable agentId;

    /// @notice Number of distinct addresses that have ever checked in.
    uint256 public totalUsers;
    /// @notice Total check-ins across all users.
    uint256 public totalCheckIns;

    /// @notice Last UTC day number (block.timestamp / 1 days) a user checked in.
    mapping(address => uint256) public lastCheckInDay;
    /// @notice Current consecutive-day streak of a user.
    mapping(address => uint256) public streak;
    /// @notice Lifetime check-in count of a user.
    mapping(address => uint256) public checkIns;

    event CheckedIn(address indexed user, uint256 indexed day, uint256 streak, uint256 totalCheckIns);

    constructor(address _agentId) {
        agentId = IAgentID(_agentId);
    }

    /// @notice Check in for the current UTC day. Requires holding an Agent ID.
    function checkIn() external {
        if (agentId.balanceOf(msg.sender) == 0) revert NotAgentIDHolder();
        uint256 day = block.timestamp / 1 days;
        uint256 last = lastCheckInDay[msg.sender];
        // checkIns > 0 distinguishes "never checked in" (last == 0) from a
        // real check-in on day 0.
        if (checkIns[msg.sender] > 0 && last == day) revert AlreadyCheckedInToday();

        if (checkIns[msg.sender] > 0 && day > 0 && last == day - 1) {
            streak[msg.sender] += 1;
        } else {
            streak[msg.sender] = 1;
        }
        if (checkIns[msg.sender] == 0) totalUsers += 1;
        checkIns[msg.sender] += 1;
        lastCheckInDay[msg.sender] = day;
        totalCheckIns += 1;

        emit CheckedIn(msg.sender, day, streak[msg.sender], checkIns[msg.sender]);
    }

    /// @notice Current UTC day number.
    function currentDay() external view returns (uint256) {
        return block.timestamp / 1 days;
    }

    /// @notice Whether `user` already checked in today.
    function checkedInToday(address user) external view returns (bool) {
        return lastCheckInDay[user] == block.timestamp / 1 days;
    }
}
