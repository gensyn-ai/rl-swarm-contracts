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
        coordinator.initialize(owner.addr);
        console2.log("Coordinator deployed at", address(coordinator));

        // Add bootnodes
        string[] memory bootnodes = new string[](3);
        bootnodes[0] = "/ip4/127.0.0.1/tcp/4001/p2p/QmBootnode1";
        bootnodes[1] = "/ip4/127.0.0.1/tcp/4002/p2p/QmBootnode2";
        bootnodes[2] = "/ip4/127.0.0.1/tcp/4003/p2p/QmBootnode3";
        coordinator.addBootnodes(bootnodes);

        vm.stopBroadcast();

        // Register peers
        string memory peerId1 = "QmPeer1";
        string memory peerId2 = "QmPeer2";
        string memory peerId3 = "QmPeer3";
        vm.broadcast(user1.privateKey);
        coordinator.registerPeer(peerId1);
        vm.broadcast(user2.privateKey);
        coordinator.registerPeer(peerId2);
        vm.broadcast(user3.privateKey);
        coordinator.registerPeer(peerId3);

        // Submit winners for round 0
        // User 1 winners
        vm.broadcast(user1.privateKey);
        string[] memory user1Round0Winners = new string[](2);
        user1Round0Winners[0] = peerId3;
        user1Round0Winners[1] = peerId2;
        coordinator.submitWinners(0, user1Round0Winners, peerId1);
        // User 2 winners
        vm.broadcast(user2.privateKey);
        string[] memory user2Round0Winners = new string[](2);
        user2Round0Winners[0] = peerId1;
        user2Round0Winners[1] = peerId3;
        coordinator.submitWinners(0, user2Round0Winners, peerId2);
        // User 3 winners
        vm.broadcast(user3.privateKey);
        string[] memory user3Round0Winners = new string[](2);
        user3Round0Winners[0] = peerId1;
        user3Round0Winners[1] = peerId2;
        coordinator.submitWinners(0, user3Round0Winners, peerId3);

        // Advance round (3 stages required to pass to increment round)
        vm.broadcast(owner.privateKey);
        coordinator.advanceRound();

        // Submit winners for round 1
        // User 1 winners
        vm.broadcast(user1.privateKey);
        string[] memory user1Round1Winners = new string[](3);
        user1Round1Winners[0] = peerId1;
        user1Round1Winners[1] = peerId2;
        user1Round1Winners[2] = peerId3;
        coordinator.submitWinners(1, user1Round1Winners, peerId1);
        // User 2 winners
        vm.broadcast(user2.privateKey);
        string[] memory user2Round1Winners = new string[](3);
        user2Round1Winners[0] = peerId1;
        user2Round1Winners[1] = peerId2;
        user2Round1Winners[2] = peerId3;
        coordinator.submitWinners(1, user2Round1Winners, peerId2);
        // User 3 winners
        vm.broadcast(user3.privateKey);
        string[] memory user3Round1Winners = new string[](3);
        user3Round1Winners[0] = peerId1;
        user3Round1Winners[1] = peerId2;
        user3Round1Winners[2] = peerId3;
        coordinator.submitWinners(1, user3Round1Winners, peerId3);

        // Advance round
        vm.broadcast(owner.privateKey);
        coordinator.advanceRound();

        // Submit winners for round 2
        // User 1 winners
        vm.broadcast(user1.privateKey);
        string[] memory user1Round2Winners = new string[](2);
        user1Round2Winners[0] = peerId3;
        user1Round2Winners[1] = peerId2;
        coordinator.submitWinners(2, user1Round2Winners, peerId1);
        // User 2 winners
        vm.broadcast(user2.privateKey);
        string[] memory user2Round2Winners = new string[](2);
        user2Round2Winners[0] = peerId1;
        user2Round2Winners[1] = peerId3;
        coordinator.submitWinners(2, user2Round2Winners, peerId2);

        // Submit rewards for each round and stage
        // vm.broadcast(user1.privateKey);
        // coordinator.submitReward(0, 0, 100, peerId1);
        // vm.broadcast(user2.privateKey);
        // coordinator.submitReward(0, 0, 200, peerId2);
        // vm.broadcast(user3.privateKey);
        // coordinator.submitReward(0, 0, 300, peerId3);

        // vm.broadcast(user1.privateKey);
        // coordinator.submitReward(1, 0, 150, peerId1);
        // vm.broadcast(user2.privateKey);
        // coordinator.submitReward(1, 0, 250, peerId2);
        // vm.broadcast(user3.privateKey);
        // coordinator.submitReward(1, 0, 350, peerId3);

        // vm.broadcast(user1.privateKey);
        // coordinator.submitReward(2, 0, 175, peerId1);
        // vm.broadcast(user2.privateKey);
        // coordinator.submitReward(2, 0, 275, peerId2);
    }
}
