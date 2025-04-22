// SPDX-License-Identifier: MIT
pragma solidity ^0.8;

import {Script, console2} from "forge-std/Script.sol";
import {Vm} from "forge-std/Vm.sol";
import {SwarmCoordinator} from "../src/SwarmCoordinator.sol";

contract DeployLocalMockData is Script {
    SwarmCoordinator coordinator;

    Vm.Wallet owner;

    Vm.Wallet user1;
    Vm.Wallet user2;
    Vm.Wallet user3;

    function setUp() public {
        owner = vm.createWallet(0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80, "owner");

        user1 = vm.createWallet(0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d, "user1");
        user2 = vm.createWallet(0x5de4111afa1a4b94908f83103eb1f1706367c2e68ca870fc3fb9a804cdab365a, "user2");
        user3 = vm.createWallet(0x7c852118294e51e653712a81e05800f419141751be58f605c371e15141b007a6, "user3");
    }

    function run() public {
        vm.startBroadcast(owner.privateKey);

        // Deploy coordinator
        coordinator = new SwarmCoordinator();

        // Set stage count
        coordinator.setStageCount(1);

        // Add bootnodes
        string[] memory bootnodes = new string[](3);
        bootnodes[0] = "/ip4/127.0.0.1/tcp/4001/p2p/QmBootnode1";
        bootnodes[1] = "/ip4/127.0.0.1/tcp/4002/p2p/QmBootnode2";
        bootnodes[2] = "/ip4/127.0.0.1/tcp/4003/p2p/QmBootnode3";
        coordinator.addBootnodes(bootnodes);

        vm.stopBroadcast();

        // Register peers
        vm.broadcast(user1.privateKey);
        coordinator.registerPeer("QmPeer1");
        vm.broadcast(user2.privateKey);
        coordinator.registerPeer("QmPeer2");
        vm.broadcast(user3.privateKey);
        coordinator.registerPeer("QmPeer3");

        // Submit winners for round 0
        // User 1 winners
        vm.broadcast(user1.privateKey);
        string[] memory user1Round0Winners = new string[](2);
        user1Round0Winners[0] = "QmPeer3";
        user1Round0Winners[1] = "QmPeer2";
        coordinator.submitWinners(0, user1Round0Winners);
        // User 2 winners
        vm.broadcast(user2.privateKey);
        string[] memory user2Round0Winners = new string[](2);
        user2Round0Winners[0] = "QmPeer1";
        user2Round0Winners[1] = "QmPeer3";
        coordinator.submitWinners(0, user2Round0Winners);
        // User 3 winners
        vm.broadcast(user3.privateKey);
        string[] memory user3Round0Winners = new string[](2);
        user3Round0Winners[0] = "QmPeer1";
        user3Round0Winners[1] = "QmPeer2";
        coordinator.submitWinners(0, user3Round0Winners);

        // Advance round
        vm.broadcast(owner.privateKey);
        coordinator.updateStageAndRound();

        // Submit winners for round 1
        // User 1 winners
        vm.broadcast(user1.privateKey);
        string[] memory user1Round1Winners = new string[](3);
        user1Round1Winners[0] = "QmPeer1";
        user1Round1Winners[1] = "QmPeer2";
        user1Round1Winners[2] = "QmPeer3";
        coordinator.submitWinners(1, user1Round1Winners);
        // User 2 winners
        vm.broadcast(user2.privateKey);
        string[] memory user2Round1Winners = new string[](3);
        user2Round1Winners[0] = "QmPeer1";
        user2Round1Winners[1] = "QmPeer2";
        user2Round1Winners[2] = "QmPeer3";
        coordinator.submitWinners(1, user2Round1Winners);
        // User 3 winners
        vm.broadcast(user3.privateKey);
        string[] memory user3Round1Winners = new string[](3);
        user3Round1Winners[0] = "QmPeer1";
        user3Round1Winners[1] = "QmPeer2";
        user3Round1Winners[2] = "QmPeer3";
        coordinator.submitWinners(1, user3Round1Winners);

        // Advance round
        vm.broadcast(owner.privateKey);
        coordinator.updateStageAndRound();

        // Submit winners for round 2
        // User 1 winners
        vm.broadcast(user1.privateKey);
        string[] memory user1Round2Winners = new string[](2);
        user1Round2Winners[0] = "QmPeer3";
        user1Round2Winners[1] = "QmPeer2";
        coordinator.submitWinners(2, user1Round2Winners);
        // User 2 winners
        vm.broadcast(user2.privateKey);
        string[] memory user2Round2Winners = new string[](2);
        user2Round2Winners[0] = "QmPeer1";
        user2Round2Winners[1] = "QmPeer3";
        coordinator.submitWinners(2, user2Round2Winners);
        // User 3 winners are not submitted for round 2

        // Display individual winner information
        string[] memory peerIds = new string[](3);
        peerIds[0] = "QmPeer1";
        peerIds[1] = "QmPeer2";
        peerIds[2] = "QmPeer3";

        console2.log("Win counts for each peer:");
        for (uint256 i = 0; i < peerIds.length; i++) {
            uint256 wins = coordinator.getTotalWins(peerIds[i]);
            console2.log(peerIds[i], wins);
        }

        // Display individual voter information
        address[] memory voters = new address[](3);
        voters[0] = user1.addr;
        voters[1] = user2.addr;
        voters[2] = user3.addr;

        console2.log("Vote counts for each voter:");
        for (uint256 i = 0; i < voters.length; i++) {
            uint256 voteCount = coordinator.getVoterVoteCount(voters[i]);
            console2.log(voters[i], voteCount);
        }

        // Display unique voter and voted peer counts
        console2.log("Total unique voters:", coordinator.uniqueVoters());
        console2.log("Total unique voted peers:", coordinator.uniqueVotedPeers());
    }
}
