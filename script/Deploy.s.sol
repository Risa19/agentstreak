// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Script.sol";
import "../src/AgentStreak.sol";

contract Deploy is Script {
    // SPACE ID Agent ID contract on BNB Chain.
    address constant AGENT_ID = 0x60B9262456dE011F7d15a54CdD8c48bAaa8B022F;

    function run() external {
        vm.startBroadcast();
        AgentStreak streak = new AgentStreak(AGENT_ID);
        vm.stopBroadcast();
        console.log("AgentStreak deployed at:", address(streak));
    }
}
