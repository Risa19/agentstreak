// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import "../src/AgentStreak.sol";

contract MockAgentID {
    mapping(address => uint256) public balances;

    function setBalance(address user, uint256 amount) external {
        balances[user] = amount;
    }

    function balanceOf(address owner) external view returns (uint256) {
        return balances[owner];
    }
}

contract AgentStreakTest is Test {
    AgentStreak public streak;
    MockAgentID public agentId;

    address public alice = address(0xA11CE);
    address public bob = address(0xB0B);

    function setUp() public {
        // Realistic mainnet-ish timestamp (Nov 2026); day 0 collides with the
        // uninitialized mapping value, so tests must not run at timestamp 1.
        vm.warp(1795000000);
        agentId = new MockAgentID();
        streak = new AgentStreak(address(agentId));
        agentId.setBalance(alice, 1);
        agentId.setBalance(bob, 1);
    }

    function testRevertsWithoutAgentID() public {
        address stranger = address(0x5);
        vm.prank(stranger);
        vm.expectRevert(AgentStreak.NotAgentIDHolder.selector);
        streak.checkIn();
    }

    function testFirstCheckIn() public {
        vm.prank(alice);
        streak.checkIn();
        assertEq(streak.streak(alice), 1);
        assertEq(streak.checkIns(alice), 1);
        assertEq(streak.totalUsers(), 1);
        assertEq(streak.totalCheckIns(), 1);
        assertTrue(streak.checkedInToday(alice));
    }

    function testConsecutiveDaysGrowStreak() public {
        vm.prank(alice);
        streak.checkIn();
        vm.warp(vm.getBlockTimestamp() + 1 days);
        vm.prank(alice);
        streak.checkIn();
        assertEq(streak.streak(alice), 2);
        assertEq(streak.checkIns(alice), 2);
        assertEq(streak.totalUsers(), 1);
        assertEq(streak.totalCheckIns(), 2);
    }

    function testSameDayTwiceReverts() public {
        vm.prank(alice);
        streak.checkIn();
        vm.prank(alice);
        vm.expectRevert(AgentStreak.AlreadyCheckedInToday.selector);
        streak.checkIn();
    }

    function testMissedDayResetsStreak() public {
        vm.prank(alice);
        streak.checkIn();
        vm.warp(vm.getBlockTimestamp() + 1 days);
        vm.prank(alice);
        streak.checkIn();
        assertEq(streak.streak(alice), 2);
        vm.warp(vm.getBlockTimestamp() + 2 days); // skip one day
        vm.prank(alice);
        streak.checkIn();
        assertEq(streak.streak(alice), 1);
        assertEq(streak.checkIns(alice), 3);
    }

    function testTwoUsers() public {
        vm.prank(alice);
        streak.checkIn();
        vm.prank(bob);
        streak.checkIn();
        assertEq(streak.totalUsers(), 2);
        assertEq(streak.totalCheckIns(), 2);
        assertEq(streak.streak(bob), 1);
    }

    function testCheckInAfterLosingAgentIDReverts() public {
        vm.prank(alice);
        streak.checkIn();
        agentId.setBalance(alice, 0);
        vm.warp(vm.getBlockTimestamp() + 1 days);
        vm.prank(alice);
        vm.expectRevert(AgentStreak.NotAgentIDHolder.selector);
        streak.checkIn();
    }
}
