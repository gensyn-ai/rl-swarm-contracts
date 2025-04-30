// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8;

import {Test} from "forge-std/Test.sol";
import {SwarmCoordinator} from "../src/SwarmCoordinator.sol";

contract SwarmCoordinatorTest is Test {
    SwarmCoordinator public swarmCoordinator;

    address _owner = makeAddr("owner");
    address _bootnodeManager = makeAddr("bootnodeManager");
    address _stageManager = makeAddr("stageManager");

    // Test users with different roles
    address _user1 = makeAddr("user1");
    address _user2 = makeAddr("user2");
    address _user3 = makeAddr("user3");

    address _nonUser = makeAddr("nonUser");

    function setUp() public {
        vm.startPrank(_owner);
        swarmCoordinator = new SwarmCoordinator();
        swarmCoordinator.initialize(_owner);
        swarmCoordinator.grantRole(swarmCoordinator.BOOTNODE_MANAGER_ROLE(), _bootnodeManager);
        vm.stopPrank();
    }

    function _forwardToNextRound() private {
        vm.startPrank(_owner);
        uint256 currentRound = swarmCoordinator.currentRound();
        while (swarmCoordinator.currentRound() == currentRound) {
            swarmCoordinator.updateStageAndRound();
        }
        vm.stopPrank();
    }

    function test_Anyone_CanQuery_CurrentRound_Successfully() public view {
        uint256 currentRound = swarmCoordinator.currentRound();
        assertEq(currentRound, 0);
    }

    function test_Owner_CanAdvanceStage_Successfully() public {
        uint256 startingStage = uint256(swarmCoordinator.currentStage());

        vm.prank(_owner);
        (, uint256 newStage) = swarmCoordinator.updateStageAndRound();

        assertEq(newStage, startingStage + 1);
    }

    function test_NonOwner_CannotAdvanceStage_Fails() public {
        vm.prank(_nonUser);
        vm.expectRevert(SwarmCoordinator.OnlyStageManager.selector);
        swarmCoordinator.updateStageAndRound();
    }

    function test_StageManager_CanAdvanceRound_Successfully() public {
        uint256 stageCount_ = swarmCoordinator.stageCount();

        vm.startPrank(_owner);
        swarmCoordinator.grantRole(swarmCoordinator.STAGE_MANAGER_ROLE(), _stageManager);
        vm.stopPrank();

        uint256 startingRound = uint256(swarmCoordinator.currentRound());

        // Advance through all stages to trigger round advancement
        vm.startPrank(_stageManager);
        for (uint256 i = 0; i < stageCount_; i++) {
            swarmCoordinator.updateStageAndRound();
        }
        vm.stopPrank();

        uint256 newRound = uint256(swarmCoordinator.currentRound());
        uint256 newStage = uint256(swarmCoordinator.currentStage());
        assertEq(newRound, startingRound + 1);
        assertEq(newStage, 0);
    }

    function test_Anyone_CanAddPeer_Successfully() public {
        address user = makeAddr("user");
        string memory peerId = "QmPeer1";

        vm.startPrank(user);
        vm.expectEmit(true, true, false, true);
        emit SwarmCoordinator.PeerRegistered(user, peerId);
        swarmCoordinator.registerPeer(peerId);
        vm.stopPrank();

        // Verify the mapping was updated correctly using the getter function
        address[] memory addresses = new address[](1);
        addresses[0] = user;
        string[][] memory storedPeerIds = swarmCoordinator.getPeerId(addresses);
        string[] memory storedPeerIdsForUser = storedPeerIds[0];
        assertEq(storedPeerIdsForUser.length, 1, "User should have 1 peer ID");
        assertEq(storedPeerIdsForUser[0], peerId, "Peer ID not stored correctly");
    }

    function test_Anyone_CanRegister_DifferentPeerIds_Successfully() public {
        address user1 = makeAddr("user1");
        address user2 = makeAddr("user2");
        string memory peerId1 = "peerId1";
        string memory peerId2 = "peerId2";

        // First user registers peer
        vm.prank(user1);
        vm.expectEmit(true, true, false, true);
        emit SwarmCoordinator.PeerRegistered(user1, peerId1);
        swarmCoordinator.registerPeer(peerId1);

        // Second user registers peer
        vm.prank(user2);
        vm.expectEmit(true, true, false, true);
        emit SwarmCoordinator.PeerRegistered(user2, peerId2);
        swarmCoordinator.registerPeer(peerId2);

        // Verify the mappings were updated correctly
        address[] memory addresses = new address[](2);
        addresses[0] = user1;
        addresses[1] = user2;
        string[][] memory storedPeerIds = swarmCoordinator.getPeerId(addresses);
        string[] memory storedPeerIdsForUser1 = storedPeerIds[0];
        string[] memory storedPeerIdsForUser2 = storedPeerIds[1];
        assertEq(storedPeerIdsForUser1.length, 1, "User 1 should have 1 peer ID");
        assertEq(storedPeerIdsForUser2.length, 1, "User 2 should have 1 peer ID");
        assertEq(storedPeerIdsForUser1[0], peerId1, "Peer ID 1 not stored correctly");
        assertEq(storedPeerIdsForUser2[0], peerId2, "Peer ID 2 not stored correctly");
    }

    function test_Anyone_CanAddMultiplePeerIds_Successfully() public {
        address user = makeAddr("user");
        string memory peerId1 = "peerId1";
        string memory peerId2 = "peerId2";
        string memory peerId3 = "peerId3";

        // User registers first peer
        vm.prank(user);
        vm.expectEmit(true, true, false, true);
        emit SwarmCoordinator.PeerRegistered(user, peerId1);
        swarmCoordinator.registerPeer(peerId1);

        // User registers second peer
        vm.prank(user);
        vm.expectEmit(true, true, false, true);
        emit SwarmCoordinator.PeerRegistered(user, peerId2);
        swarmCoordinator.registerPeer(peerId2);

        // User registers third peer
        vm.prank(user);
        vm.expectEmit(true, true, false, true);
        emit SwarmCoordinator.PeerRegistered(user, peerId3);
        swarmCoordinator.registerPeer(peerId3);

        // Verify all peer IDs were stored correctly
        address[] memory addresses = new address[](1);
        addresses[0] = user;
        string[][] memory storedPeerIds = swarmCoordinator.getPeerId(addresses);
        string[] memory storedPeerIdsForUser = storedPeerIds[0];
        assertEq(storedPeerIdsForUser.length, 3, "Should have 3 peer IDs registered");
        assertEq(storedPeerIdsForUser[0], peerId1, "First peer ID not stored correctly");
        assertEq(storedPeerIdsForUser[1], peerId2, "Second peer ID not stored correctly");
        assertEq(storedPeerIdsForUser[2], peerId3, "Third peer ID not stored correctly");

        // Verify reverse lookups work correctly
        string[] memory peerIds = new string[](3);
        peerIds[0] = peerId1;
        peerIds[1] = peerId2;
        peerIds[2] = peerId3;
        address[] memory eoas = swarmCoordinator.getEoa(peerIds);
        assertEq(eoas[0], user, "First peer ID should map to user");
        assertEq(eoas[1], user, "Second peer ID should map to user");
        assertEq(eoas[2], user, "Third peer ID should map to user");
    }

    function test_Anyone_CanGetEoa_ForPeerId_Successfully() public {
        address user = makeAddr("user");
        string memory peerId = "QmPeer1";

        // Register peer
        vm.prank(user);
        swarmCoordinator.registerPeer(peerId);

        // Verify the EOA mapping was updated correctly
        string[] memory peerIds = new string[](1);
        peerIds[0] = peerId;
        address[] memory eoas = swarmCoordinator.getEoa(peerIds);
        assertEq(eoas[0], user, "EOA not stored correctly");
    }

    function test_Anyone_CanGetEoa_ForMultiplePeerIds_Successfully() public {
        address user1 = makeAddr("user1");
        address user2 = makeAddr("user2");
        string memory peerId1 = "peerId1";
        string memory peerId2 = "peerId2";

        // Register peers
        vm.prank(user1);
        swarmCoordinator.registerPeer(peerId1);
        vm.prank(user2);
        swarmCoordinator.registerPeer(peerId2);

        // Verify the EOA mappings were updated correctly
        string[] memory peerIds = new string[](2);
        peerIds[0] = peerId1;
        peerIds[1] = peerId2;
        address[] memory eoas = swarmCoordinator.getEoa(peerIds);
        assertEq(eoas[0], user1, "EOA 1 not stored correctly");
        assertEq(eoas[1], user2, "EOA 2 not stored correctly");
    }

    function test_GetEoa_ReturnsZeroAddress_ForUnregisteredPeerId_Successfully() public view {
        string memory unregisteredPeerId = "unregistered";
        string[] memory peerIds = new string[](1);
        peerIds[0] = unregisteredPeerId;
        address[] memory eoas = swarmCoordinator.getEoa(peerIds);
        assertEq(eoas[0], address(0), "Unregistered peer ID should return zero address");
    }

    function test_GetPeerId_ReturnsEmptyString_ForUnregisteredEoa_Successfully() public {
        address unregisteredEoa = makeAddr("unregistered");
        address[] memory eoas = new address[](1);
        eoas[0] = unregisteredEoa;
        string[][] memory peerIds = swarmCoordinator.getPeerId(eoas);
        assertEq(peerIds[0].length, 0, "Unregistered EOA should return empty array");
    }

    // Bootnode tests
    function test_BootnodeManager_CanAddBootnodes_Successfully() public {
        string[] memory newBootnodes = new string[](2);
        newBootnodes[0] = "/ip4/127.0.0.1/tcp/4001/p2p/QmBootnode1";
        newBootnodes[1] = "/ip4/127.0.0.1/tcp/4002/p2p/QmBootnode2";

        vm.prank(_owner);
        vm.expectEmit(true, false, false, true);
        emit SwarmCoordinator.BootnodesAdded(_owner, 2);
        swarmCoordinator.addBootnodes(newBootnodes);

        string[] memory storedBootnodes = swarmCoordinator.getBootnodes();
        assertEq(storedBootnodes.length, 2);
        assertEq(storedBootnodes[0], newBootnodes[0]);
        assertEq(storedBootnodes[1], newBootnodes[1]);
    }

    function test_NonBootnodeManager_CannotAddBootnodes_Fails() public {
        string[] memory newBootnodes = new string[](1);
        newBootnodes[0] = "/ip4/127.0.0.1/tcp/4001/p2p/QmBootnode1";

        vm.prank(_nonUser);
        vm.expectRevert(SwarmCoordinator.OnlyBootnodeManager.selector);
        swarmCoordinator.addBootnodes(newBootnodes);
    }

    function test_BootnodeManager_CanRemoveBootnode_Successfully() public {
        // First add some bootnodes
        string[] memory newBootnodes = new string[](3);
        newBootnodes[0] = "/ip4/127.0.0.1/tcp/4001/p2p/QmBootnode1";
        newBootnodes[1] = "/ip4/127.0.0.1/tcp/4002/p2p/QmBootnode2";
        newBootnodes[2] = "/ip4/127.0.0.1/tcp/4003/p2p/QmBootnode3";

        vm.startPrank(_owner);
        swarmCoordinator.addBootnodes(newBootnodes);

        // Now remove the middle one
        vm.expectEmit(true, false, false, true);
        emit SwarmCoordinator.BootnodeRemoved(_owner, 1);
        swarmCoordinator.removeBootnode(1);
        vm.stopPrank();

        // Verify the bootnode was removed and the array was reorganized
        string[] memory storedBootnodes = swarmCoordinator.getBootnodes();
        assertEq(storedBootnodes.length, 2);
        assertEq(storedBootnodes[0], newBootnodes[0]);
        // The last element should now be at index 1
        assertEq(storedBootnodes[1], newBootnodes[2]);
    }

    function test_BootnodeManager_CannotRemoveInvalidIndex_Fails() public {
        vm.prank(_owner);
        vm.expectRevert(SwarmCoordinator.InvalidBootnodeIndex.selector);
        swarmCoordinator.removeBootnode(0); // No bootnodes yet
    }

    function test_NonBootnodeManager_CannotRemoveBootnode_Fails() public {
        // First add a bootnode as the owner
        string[] memory newBootnodes = new string[](1);
        newBootnodes[0] = "bootnode1";

        vm.prank(_owner);
        swarmCoordinator.addBootnodes(newBootnodes);

        // Try to remove as non-manager
        vm.prank(_nonUser);
        vm.expectRevert(SwarmCoordinator.OnlyBootnodeManager.selector);
        swarmCoordinator.removeBootnode(0);
    }

    function test_BootnodeManager_CanClearAllBootnodes_Successfully() public {
        // First add some bootnodes
        string[] memory newBootnodes = new string[](2);
        newBootnodes[0] = "bootnode1";
        newBootnodes[1] = "bootnode2";

        vm.startPrank(_owner);
        swarmCoordinator.addBootnodes(newBootnodes);

        // Now clear them
        vm.expectEmit(true, false, false, false);
        emit SwarmCoordinator.AllBootnodesCleared(_owner);
        swarmCoordinator.clearBootnodes();
        vm.stopPrank();

        // Verify all bootnodes were cleared
        string[] memory storedBootnodes = swarmCoordinator.getBootnodes();
        assertEq(storedBootnodes.length, 0);
    }

    function test_NonBootnodeManager_CannotClearBootnodes_Fails() public {
        // First add a bootnode as the owner
        string[] memory newBootnodes = new string[](1);
        newBootnodes[0] = "bootnode1";

        vm.prank(_owner);
        swarmCoordinator.addBootnodes(newBootnodes);

        // Try to clear as non-manager
        vm.prank(_nonUser);
        vm.expectRevert(SwarmCoordinator.OnlyBootnodeManager.selector);
        swarmCoordinator.clearBootnodes();
    }

    function test_Anyone_CanGetBootnodes_Successfully() public {
        // First add some bootnodes as the owner
        string[] memory newBootnodes = new string[](2);
        newBootnodes[0] = "bootnode1";
        newBootnodes[1] = "bootnode2";

        vm.prank(_owner);
        swarmCoordinator.addBootnodes(newBootnodes);

        // Get bootnodes
        vm.prank(_nonUser);
        string[] memory storedBootnodes = swarmCoordinator.getBootnodes();

        // Verify the bootnodes are accessible
        assertEq(storedBootnodes.length, 2);
        assertEq(storedBootnodes[0], newBootnodes[0]);
        assertEq(storedBootnodes[1], newBootnodes[1]);
    }

    function test_Anyone_CanGetBootnodesCount_Successfully() public {
        // First add some bootnodes as the owner
        string[] memory newBootnodes = new string[](3);
        newBootnodes[0] = "bootnode1";
        newBootnodes[1] = "bootnode2";
        newBootnodes[2] = "bootnode3";

        vm.prank(_owner);
        swarmCoordinator.addBootnodes(newBootnodes);

        // Get bootnode count
        vm.prank(_nonUser);
        uint256 count = swarmCoordinator.getBootnodesCount();

        // Verify the count is correct
        assertEq(count, 3);
    }

    function test_Anyone_CanSubmitWinners_Successfully() public {
        string[] memory winners = new string[](2);
        winners[0] = "QmWinner1";
        winners[1] = "QmWinner2";

        string memory voterPeerId = "QmVoter1";

        // Register peer IDs first
        vm.prank(_user1);
        swarmCoordinator.registerPeer(voterPeerId);

        // Submit winners for round 0
        vm.prank(_user1);
        vm.expectEmit(true, true, true, true);
        emit SwarmCoordinator.WinnerSubmitted(_user1, voterPeerId, 0, winners);
        swarmCoordinator.submitWinners(0, winners, voterPeerId);

        // Verify vote counts
        assertEq(swarmCoordinator.getPeerVoteCount(0, winners[0]), 1);
        assertEq(swarmCoordinator.getPeerVoteCount(0, winners[1]), 1);
    }

    function test_Anyone_CanSubmit_UnregisteredPeerIds_Successfully() public {
        string[] memory winners = new string[](2);
        winners[0] = "QmWinner1";
        winners[1] = "QmWinner2";

        string memory voterPeerId = "QmVoter1";

        // Register voter peer ID
        vm.prank(_user1);
        swarmCoordinator.registerPeer(voterPeerId);

        // Submit winners for round 0
        vm.prank(_user1);
        vm.expectEmit(true, true, true, true);
        emit SwarmCoordinator.WinnerSubmitted(_user1, voterPeerId, 0, winners);
        swarmCoordinator.submitWinners(0, winners, voterPeerId);

        // Verify vote counts
        assertEq(swarmCoordinator.getPeerVoteCount(0, winners[0]), 1);
        assertEq(swarmCoordinator.getPeerVoteCount(0, winners[1]), 1);
    }

    function test_Nobody_CanSubmitSameWinner_MultipleTimesInARound_Fails() public {
        string[] memory winners = new string[](2);
        winners[0] = "QmWinner1";
        winners[1] = "QmWinner1";

        // Register peer ID first
        vm.prank(_user1);
        swarmCoordinator.registerPeer(winners[0]);

        // Submit winners for round 0
        vm.prank(_user1);
        vm.expectRevert(SwarmCoordinator.InvalidVote.selector);
        swarmCoordinator.submitWinners(0, winners, winners[0]);
    }

    function test_Nobody_CanSubmitWinners_ForFutureRound_Fails() public {
        string[] memory winners = new string[](1);
        winners[0] = "QmWinner1";

        string memory voterPeerId = "QmVoter1";

        // Register peer ID first
        vm.prank(_user1);
        swarmCoordinator.registerPeer(winners[0]);
        swarmCoordinator.registerPeer(voterPeerId);

        // Try to submit winners for future round
        vm.prank(_user1);
        vm.expectRevert(SwarmCoordinator.InvalidRoundNumber.selector);
        swarmCoordinator.submitWinners(1, winners, voterPeerId);
    }

    function test_Nobody_CanVoteTwice_InSameRound_Fails() public {
        string[] memory winners = new string[](1);
        winners[0] = "QmWinner1";

        // Register peer ID first
        vm.prank(_user1);
        swarmCoordinator.registerPeer(winners[0]);

        // First vote
        vm.prank(_user1);
        swarmCoordinator.submitWinners(0, winners, winners[0]);

        // Try to vote again
        vm.prank(_user1);
        vm.expectRevert(SwarmCoordinator.WinnerAlreadyVoted.selector);
        swarmCoordinator.submitWinners(0, winners, winners[0]);
    }

    function test_VoterVoteCount_IsTrackedCorrectly_Successfully() public {
        string[] memory winners = new string[](2);
        winners[0] = "QmWinner1";
        winners[1] = "QmWinner2";

        // Register peer IDs first
        vm.prank(_user1);
        swarmCoordinator.registerPeer(winners[0]);
        vm.prank(_user2);
        swarmCoordinator.registerPeer(winners[1]);

        // Submit winners for round 0
        vm.prank(_user1);
        swarmCoordinator.submitWinners(0, winners, winners[0]);

        // Forward to next round
        _forwardToNextRound();

        // Submit winners for round 1
        vm.prank(_user1);
        swarmCoordinator.submitWinners(1, winners, winners[0]);

        // Verify vote count
        assertEq(swarmCoordinator.getVoterVoteCount(winners[0]), 2);
        assertEq(swarmCoordinator.getVoterVoteCount(winners[1]), 0);
    }

    function test_VoterLeaderboard_ReturnsCorrectOrder_Successfully() public {
        string[] memory winners1 = new string[](2);
        winners1[0] = "QmWinner1";
        winners1[1] = "QmWinner2";

        string[] memory winners2 = new string[](1);
        winners2[0] = "QmWinner3";

        // Register peer IDs first
        vm.prank(_user1);
        swarmCoordinator.registerPeer(winners1[0]);
        vm.prank(_user2);
        swarmCoordinator.registerPeer(winners1[1]);
        vm.prank(_user3);
        swarmCoordinator.registerPeer(winners2[0]);

        // Set stage count
        vm.startPrank(_owner);
        swarmCoordinator.grantRole(swarmCoordinator.STAGE_MANAGER_ROLE(), _stageManager);
        vm.stopPrank();

        // Submit winners for round 0
        vm.prank(_user1);
        swarmCoordinator.submitWinners(0, winners1, winners1[0]);

        // Forward to next round
        _forwardToNextRound();

        // Submit winners for round 1
        vm.prank(_user2);
        swarmCoordinator.submitWinners(1, winners1, winners1[1]);

        // Forward to next round
        _forwardToNextRound();

        // Submit winners for round 2
        vm.prank(_user3);
        swarmCoordinator.submitWinners(2, winners2, winners2[0]);

        // Get top 3 voters
        (string[] memory peerIds, uint256[] memory voteCounts) = swarmCoordinator.voterLeaderboard(0, 3);

        // Verify order and vote counts
        assertEq(peerIds.length, 3);
        assertEq(voteCounts.length, 3);
        assertEq(peerIds[0], winners1[0]);
        assertEq(voteCounts[0], 1);
        assertEq(peerIds[1], winners1[1]);
        assertEq(voteCounts[1], 1);
        assertEq(peerIds[2], winners2[0]);
        assertEq(voteCounts[2], 1);
    }

    function test_VoterLeaderboard_ReturnsCorrectSlice_Successfully() public {
        string[] memory winners1 = new string[](2);
        winners1[0] = "QmWinner1";
        winners1[1] = "QmWinner2";

        string[] memory winners2 = new string[](1);
        winners2[0] = "QmWinner3";

        // Register peer IDs first
        vm.prank(_user1);
        swarmCoordinator.registerPeer(winners1[0]);
        vm.prank(_user2);
        swarmCoordinator.registerPeer(winners1[1]);
        vm.prank(_user3);
        swarmCoordinator.registerPeer(winners2[0]);

        // Submit winners for round 0
        vm.prank(_user1);
        swarmCoordinator.submitWinners(0, winners1, winners1[0]);

        // Forward to next round
        _forwardToNextRound();

        // Submit winners for round 1
        vm.prank(_user2);
        swarmCoordinator.submitWinners(1, winners1, winners1[1]);

        // Forward to next round
        _forwardToNextRound();

        // Submit winners for round 2
        vm.prank(_user3);
        swarmCoordinator.submitWinners(2, winners2, winners2[0]);

        // Get slice from index 2 to 3
        (string[] memory peerIds, uint256[] memory voteCounts) = swarmCoordinator.voterLeaderboard(2, 3);
        assertEq(peerIds.length, 1);
        assertEq(voteCounts.length, 1);
        assertEq(peerIds[0], winners2[0]);
        assertEq(voteCounts[0], 1);
    }

    function test_VoterLeaderboard_ReturnsEmptyArrays_WhenNoVoters_Successfully() public view {
        (string[] memory peerIds, uint256[] memory voteCounts) = swarmCoordinator.voterLeaderboard(0, 10);
        assertEq(peerIds.length, 0);
        assertEq(voteCounts.length, 0);
    }

    function test_WinnerLeaderboard_ReturnsCorrectOrder_Successfully() public {
        string[] memory winners1 = new string[](2);
        winners1[0] = "QmWinner1";
        winners1[1] = "QmWinner2";

        string[] memory winners2 = new string[](1);
        winners2[0] = "QmWinner3";

        string memory peerId1 = "QmPeer1";
        string memory peerId2 = "QmPeer2";
        string memory peerId3 = "QmPeer3";

        // Register peer IDs first
        vm.startPrank(_user1);
        swarmCoordinator.registerPeer(winners1[0]);
        swarmCoordinator.registerPeer(peerId1);
        vm.stopPrank();

        vm.startPrank(_user2);
        swarmCoordinator.registerPeer(winners1[1]);
        swarmCoordinator.registerPeer(peerId2);
        vm.stopPrank();

        vm.startPrank(_user3);
        swarmCoordinator.registerPeer(winners2[0]);
        swarmCoordinator.registerPeer(peerId3);
        vm.stopPrank();

        // Submit winners for round 0
        vm.prank(_user1);
        swarmCoordinator.submitWinners(0, winners1, peerId1);

        // Forward to next round
        _forwardToNextRound();

        // Submit winners for round 1
        vm.prank(_user2);
        swarmCoordinator.submitWinners(1, winners1, peerId2);

        // Forward to next round
        _forwardToNextRound();

        // Submit winners for round 2
        vm.prank(_user3);
        swarmCoordinator.submitWinners(2, winners2, peerId3);

        // Get top 3 winners
        (string[] memory peerIds, uint256[] memory wins) = swarmCoordinator.winnerLeaderboard(0, 3);

        // Verify order and win counts
        assertEq(peerIds.length, 3);
        assertEq(wins.length, 3);
        assertEq(peerIds[0], winners1[0]);
        assertEq(wins[0], 2);
        assertEq(peerIds[1], winners1[1]);
        assertEq(wins[1], 2);
        assertEq(peerIds[2], winners2[0]);
        assertEq(wins[2], 1);
    }

    function test_WinnerLeaderboard_ReturnsCorrectSlice_Successfully() public {
        string[] memory winners1 = new string[](2);
        winners1[0] = "QmWinner1";
        winners1[1] = "QmWinner2";

        string[] memory winners2 = new string[](1);
        winners2[0] = "QmWinner3";

        string memory peerId1 = "QmPeer1";
        string memory peerId2 = "QmPeer2";
        string memory peerId3 = "QmPeer3";

        // Register peer IDs first
        vm.startPrank(_user1);
        swarmCoordinator.registerPeer(winners1[0]);
        swarmCoordinator.registerPeer(peerId1);
        vm.stopPrank();

        vm.startPrank(_user2);
        swarmCoordinator.registerPeer(winners1[1]);
        swarmCoordinator.registerPeer(peerId2);
        vm.stopPrank();

        vm.startPrank(_user3);
        swarmCoordinator.registerPeer(winners2[0]);
        swarmCoordinator.registerPeer(peerId3);
        vm.stopPrank();

        // Submit winners for round 0
        vm.prank(_user1);
        swarmCoordinator.submitWinners(0, winners1, peerId1);

        // Forward to next round
        _forwardToNextRound();

        // Submit winners for round 1
        vm.prank(_user2);
        swarmCoordinator.submitWinners(1, winners1, peerId2);

        // Forward to next round
        _forwardToNextRound();

        // Submit winners for round 2
        vm.prank(_user3);
        swarmCoordinator.submitWinners(2, winners2, peerId3);

        // Get slice from index 2 to 3
        (string[] memory peerIds, uint256[] memory wins) = swarmCoordinator.winnerLeaderboard(2, 3);
        assertEq(peerIds.length, 1);
        assertEq(wins.length, 1);
        assertEq(peerIds[0], winners2[0]);
        assertEq(wins[0], 1);
    }

    function test_WinnerLeaderboard_HandlesInvalidIndexes_Successfully() public {
        string[] memory winners = new string[](1);
        winners[0] = "QmWinner1";

        string memory peerId1 = "QmPeer1";

        // Register peer ID first
        vm.startPrank(_user1);
        swarmCoordinator.registerPeer(winners[0]);
        swarmCoordinator.registerPeer(peerId1);
        vm.stopPrank();

        // Submit winners
        vm.prank(_user1);
        swarmCoordinator.submitWinners(0, winners, peerId1);

        // Test with start > end
        vm.expectRevert("Start index must be less than or equal to end index");
        swarmCoordinator.winnerLeaderboard(2, 1);

        // Test with start > length
        (string[] memory peerIds, uint256[] memory wins) = swarmCoordinator.winnerLeaderboard(5, 10);
        assertEq(peerIds.length, 0);
        assertEq(wins.length, 0);

        // Test with end > length
        (peerIds, wins) = swarmCoordinator.winnerLeaderboard(0, 10);
        assertEq(peerIds.length, 1);
        assertEq(wins.length, 1);
        assertEq(peerIds[0], winners[0]);
        assertEq(wins[0], 1);
    }

    function test_WinnerLeaderboard_ReturnsEmptyArrays_WhenNoWinners_Successfully() public view {
        (string[] memory peerIds, uint256[] memory wins) = swarmCoordinator.winnerLeaderboard(0, 10);
        assertEq(peerIds.length, 0);
        assertEq(wins.length, 0);
    }

    function test_WinnerLeaderboard_CorrectlyHandlesMoreThanMaxTopWinners_Successfully() public {
        string[] memory winners = new string[](100);
        address[] memory users = new address[](100);
        for (uint256 i = 0; i < 100; i++) {
            winners[i] = string(abi.encodePacked("QmWinner", i));
            users[i] = makeAddr(string(abi.encodePacked("user", i)));

            // Register user
            vm.prank(users[i]);
            swarmCoordinator.registerPeer(winners[i]);
        }

        // Register voter
        vm.prank(_user1);
        swarmCoordinator.registerPeer("QmUser");

        // Submit winners
        vm.prank(_user1);
        swarmCoordinator.submitWinners(0, winners, "QmUser");

        // Get top 100 winners
        (string[] memory topWinners, uint256[] memory topWins) = swarmCoordinator.winnerLeaderboard(0, 100);
        assertEq(topWinners.length, 100);
        for (uint256 i = 0; i < 100; i++) {
            assertEq(topWinners[i], winners[i]);
        }

        // Add two votes for a new winner
        string[] memory topWinner = new string[](1);
        topWinner[0] = "QmUser";

        // Forward to next round
        _forwardToNextRound();

        // Submit winners
        vm.prank(_user1);
        swarmCoordinator.submitWinners(1, topWinner, "QmUser");

        // Forward to next round
        _forwardToNextRound();

        // Submit winners
        vm.prank(_user1);
        swarmCoordinator.submitWinners(2, topWinner, "QmUser");

        // New winner bubbled up the leaderboard
        (topWinners, topWins) = swarmCoordinator.winnerLeaderboard(0, 1);
        assertEq(topWinners[0], "QmUser");
        assertEq(swarmCoordinator.getTotalWins("QmUser"), 2);
    }

    function test_VoterLeaderboard_CorrectlyHandlesMoreThanMaxTopVoters_Successfully() public {
        // Create 100 voters
        string[] memory voterPeerIds = new string[](100);
        for (uint256 i = 0; i < 100; i++) {
            voterPeerIds[i] = string(abi.encodePacked("QmVoter", i));
            vm.prank(_user1);
            swarmCoordinator.registerPeer(voterPeerIds[i]);
        }

        // Register a peer for voting
        string[] memory winners = new string[](1);
        winners[0] = "QmWinner1";

        // Have each voter vote once
        for (uint256 i = 0; i < 100; i++) {
            vm.prank(_user1);
            swarmCoordinator.submitWinners(0, winners, voterPeerIds[i]);
        }

        // Get top 100 voters
        (string[] memory topVoters, uint256[] memory topVoteCounts) = swarmCoordinator.voterLeaderboard(0, 100);
        assertEq(topVoters.length, 100);
        for (uint256 i = 0; i < 100; i++) {
            assertEq(topVoters[i], voterPeerIds[i]);
            assertEq(swarmCoordinator.getVoterVoteCount(topVoters[i]), 1);
        }

        // Forward to next round
        _forwardToNextRound();

        // Add two more votes for a new voter
        string memory newVoterPeerId = "QmNewVoter";
        vm.prank(_user1);
        swarmCoordinator.registerPeer(newVoterPeerId);

        vm.prank(_user1);
        swarmCoordinator.submitWinners(1, winners, newVoterPeerId);

        // _forwardToNextRound to next round
        _forwardToNextRound();

        vm.prank(_user1);
        swarmCoordinator.submitWinners(2, winners, newVoterPeerId);

        // New voter should bubble up the leaderboard
        (topVoters, topVoteCounts) = swarmCoordinator.voterLeaderboard(0, 1);
        assertEq(topVoters[0], newVoterPeerId);
        assertEq(swarmCoordinator.getVoterVoteCount(newVoterPeerId), 2);
    }

    function test_UniqueVoters_StartsAtZero_Successfully() public view {
        assertEq(swarmCoordinator.uniqueVoters(), 0);
    }

    function test_UniqueVoters_IncrementsForNewVoter_Successfully() public {
        string[] memory winners = new string[](1);
        winners[0] = "QmWinner1";

        // Register peer ID first
        vm.prank(_user1);
        swarmCoordinator.registerPeer(winners[0]);

        // First vote should increment unique voters
        vm.prank(_user1);
        swarmCoordinator.submitWinners(0, winners, winners[0]);
        assertEq(swarmCoordinator.uniqueVoters(), 1);
    }

    function test_UniqueVoters_DoesNotIncrementForSameVoter_Successfully() public {
        string[] memory winners = new string[](1);
        winners[0] = "QmWinner1";

        string memory peerId1 = "QmPeer1";

        // Register peer ID first
        vm.startPrank(_user1);
        swarmCoordinator.registerPeer(winners[0]);
        swarmCoordinator.registerPeer(peerId1);
        vm.stopPrank();

        // First vote should increment unique voters
        vm.prank(_user1);
        swarmCoordinator.submitWinners(0, winners, peerId1);
        assertEq(swarmCoordinator.uniqueVoters(), 1);

        // Forward to next round
        _forwardToNextRound();

        // Second vote from same voter should not increment
        vm.prank(_user1);
        swarmCoordinator.submitWinners(1, winners, peerId1);
        assertEq(swarmCoordinator.uniqueVoters(), 1);
    }

    function test_UniqueVoters_IncrementsForDifferentVoters_Successfully() public {
        string[] memory winners1 = new string[](1);
        winners1[0] = "QmWinner1";

        string[] memory winners2 = new string[](1);
        winners2[0] = "QmWinner2";

        string memory peerId1 = "QmPeer1";
        string memory peerId2 = "QmPeer2";

        // Register peer ID first
        vm.startPrank(_user1);
        swarmCoordinator.registerPeer(winners1[0]);
        swarmCoordinator.registerPeer(peerId1);
        vm.stopPrank();

        vm.startPrank(_user2);
        swarmCoordinator.registerPeer(winners2[0]);
        swarmCoordinator.registerPeer(peerId2);
        vm.stopPrank();

        // First vote should increment unique voters
        vm.prank(_user1);
        swarmCoordinator.submitWinners(0, winners1, peerId1);
        assertEq(swarmCoordinator.uniqueVoters(), 1);

        // Second vote from different voter should increment
        vm.prank(_user2);
        swarmCoordinator.submitWinners(0, winners2, peerId2);
        assertEq(swarmCoordinator.uniqueVoters(), 2);
    }

    function test_UniqueVoters_DoesNotIncrementAcrossRounds_Successfully() public {
        string[] memory winners = new string[](1);
        winners[0] = "QmWinner1";

        string memory peerId1 = "QmPeer1";

        // Register peer ID first
        vm.startPrank(_user1);
        swarmCoordinator.registerPeer(winners[0]);
        swarmCoordinator.registerPeer(peerId1);
        vm.stopPrank();

        // First vote should increment unique voters
        vm.prank(_user1);
        swarmCoordinator.submitWinners(0, winners, peerId1);
        assertEq(swarmCoordinator.uniqueVoters(), 1);

        // Forward to next round
        _forwardToNextRound();

        // Vote in next round should not increment
        vm.prank(_user1);
        swarmCoordinator.submitWinners(1, winners, peerId1);
        assertEq(swarmCoordinator.uniqueVoters(), 1);
    }

    function test_UniqueVotedPeers_StartsAtZero_Successfully() public view {
        assertEq(swarmCoordinator.uniqueVotedPeers(), 0);
    }

    function test_UniqueVotedPeers_IncrementsForNewPeer_Successfully() public {
        string[] memory winners = new string[](1);
        winners[0] = "QmWinner1";

        // Register peer ID first
        vm.prank(_user1);
        swarmCoordinator.registerPeer(winners[0]);

        // First vote should increment unique voted peers
        vm.prank(_user1);
        swarmCoordinator.submitWinners(0, winners, winners[0]);
        assertEq(swarmCoordinator.uniqueVotedPeers(), 1);
    }

    function test_UniqueVotedPeers_DoesNotIncrementForSamePeer_Successfully() public {
        string[] memory winners = new string[](1);
        winners[0] = "QmWinner1";

        string memory peerId1 = "QmPeer1";
        string memory peerId2 = "QmPeer2";

        // Register peer ID first
        vm.startPrank(_user1);
        swarmCoordinator.registerPeer(winners[0]);
        swarmCoordinator.registerPeer(peerId1);
        swarmCoordinator.registerPeer(peerId2);
        vm.stopPrank();
        // First vote should increment unique voted peers
        vm.prank(_user1);
        swarmCoordinator.submitWinners(0, winners, peerId1);
        assertEq(swarmCoordinator.uniqueVotedPeers(), 1);

        // Second vote for same peer should not increment
        vm.prank(_user1);
        swarmCoordinator.submitWinners(0, winners, peerId2);
        assertEq(swarmCoordinator.uniqueVotedPeers(), 1);
    }

    function test_UniqueVotedPeers_IncrementsForDifferentPeers_Successfully() public {
        string[] memory winners1 = new string[](1);
        winners1[0] = "QmWinner1";
        string[] memory winners2 = new string[](1);
        winners2[0] = "QmWinner2";

        string memory peerId1 = "QmPeer1";
        string memory peerId2 = "QmPeer2";

        // Register peer IDs first
        vm.startPrank(_user1);
        swarmCoordinator.registerPeer(winners1[0]);
        swarmCoordinator.registerPeer(peerId1);
        vm.stopPrank();

        vm.startPrank(_user2);
        swarmCoordinator.registerPeer(winners2[0]);
        swarmCoordinator.registerPeer(peerId2);
        vm.stopPrank();

        // First vote should increment unique voted peers
        vm.prank(_user1);
        swarmCoordinator.submitWinners(0, winners1, peerId1);
        assertEq(swarmCoordinator.uniqueVotedPeers(), 1);

        // Second vote for different peer should increment
        vm.prank(_user2);
        swarmCoordinator.submitWinners(0, winners2, peerId2);
        assertEq(swarmCoordinator.uniqueVotedPeers(), 2);
    }

    function test_UniqueVotedPeers_DoesNotIncrementAcrossRounds_Successfully() public {
        string[] memory winners = new string[](1);
        winners[0] = "QmWinner1";

        string memory peerId1 = "QmPeer1";

        // Register peer ID first
        vm.startPrank(_user1);
        swarmCoordinator.registerPeer(winners[0]);
        swarmCoordinator.registerPeer(peerId1);
        vm.stopPrank();

        // First vote should increment unique voted peers
        vm.prank(_user1);
        swarmCoordinator.submitWinners(0, winners, peerId1);
        assertEq(swarmCoordinator.uniqueVotedPeers(), 1);

        // Forward to next round
        _forwardToNextRound();

        // Vote in next round should not increment since peer was already voted on
        vm.prank(_user1);
        swarmCoordinator.submitWinners(1, winners, peerId1);
        assertEq(swarmCoordinator.uniqueVotedPeers(), 1);
    }

    function test_UniqueVotedPeers_TracksUniquenessAcrossRounds_Successfully() public {
        string[] memory winners1 = new string[](1);
        winners1[0] = "QmWinner1";
        string[] memory winners2 = new string[](1);
        winners2[0] = "QmWinner2";

        string memory peerId1 = "QmPeer1";
        string memory peerId2 = "QmPeer2";

        // Register peer IDs first
        vm.startPrank(_user1);
        swarmCoordinator.registerPeer(winners1[0]);
        swarmCoordinator.registerPeer(peerId1);
        vm.stopPrank();

        vm.startPrank(_user2);
        swarmCoordinator.registerPeer(winners2[0]);
        swarmCoordinator.registerPeer(peerId2);
        vm.stopPrank();

        // First vote should increment unique voted peers
        vm.prank(_user1);
        swarmCoordinator.submitWinners(0, winners1, peerId1);
        assertEq(swarmCoordinator.uniqueVotedPeers(), 1);

        // Forward to next round
        _forwardToNextRound();

        // Vote for a different peer in next round should increment
        vm.prank(_user2);
        swarmCoordinator.submitWinners(1, winners2, peerId2);
        assertEq(swarmCoordinator.uniqueVotedPeers(), 2);

        // Forward to next round
        _forwardToNextRound();

        // Vote for first peer again in next round should not increment
        vm.prank(_user1);
        swarmCoordinator.submitWinners(2, winners1, peerId1);
        assertEq(swarmCoordinator.uniqueVotedPeers(), 2);
    }

    function test_Anyone_CanSubmitReward_Successfully() public {
        uint256 reward = 100;
        string memory peerId1 = "QmPeer1";

        vm.startPrank(_user1);
        swarmCoordinator.registerPeer(peerId1);
        vm.expectEmit(true, true, true, true);
        emit SwarmCoordinator.RewardSubmitted(_user1, 0, 0, reward, peerId1);
        vm.expectEmit(true, true, true, true);
        emit SwarmCoordinator.CumulativeRewardsUpdated(_user1, peerId1, reward);
        swarmCoordinator.submitReward(0, 0, reward, peerId1);
        vm.stopPrank();

        // Verify reward was recorded
        address[] memory accounts = new address[](1);
        accounts[0] = _user1;
        uint256[] memory rewards = swarmCoordinator.getRoundStageReward(0, 0, accounts);
        string[] memory peerIds = new string[](1);
        peerIds[0] = peerId1;
        uint256[] memory totalRewards = swarmCoordinator.getTotalRewards(peerIds);
        assertEq(rewards[0], reward);
        assertEq(totalRewards[0], reward);
        assertTrue(swarmCoordinator.hasSubmittedRoundStageReward(0, 0, _user1));
    }

    function test_Nobody_CanSubmitReward_TwiceInSameRoundAndStage_Fails() public {
        uint256 reward1 = 100;
        uint256 reward2 = 200;
        string memory peerId1 = "QmPeer1";

        // First submission
        vm.startPrank(_user1);
        swarmCoordinator.registerPeer(peerId1);
        swarmCoordinator.submitReward(0, 0, reward1, peerId1);

        // Try to submit again
        vm.expectRevert(SwarmCoordinator.RewardAlreadySubmitted.selector);
        swarmCoordinator.submitReward(0, 0, reward2, peerId1);
        vm.stopPrank();
    }

    function test_Anyone_CanSubmitReward_InDifferentStages_Successfully() public {
        uint256 reward1 = 100;
        uint256 reward2 = 200;

        string memory peerId1 = "QmPeer1";

        // Submit reward in stage 0
        vm.startPrank(_user1);
        swarmCoordinator.registerPeer(peerId1);
        vm.expectEmit(true, true, true, true);
        emit SwarmCoordinator.RewardSubmitted(_user1, 0, 0, reward1, peerId1);
        vm.expectEmit(true, true, true, true);
        emit SwarmCoordinator.CumulativeRewardsUpdated(_user1, peerId1, reward1);
        swarmCoordinator.submitReward(0, 0, reward1, peerId1);

        // Submit reward in stage 1
        vm.expectEmit(true, true, true, true);
        emit SwarmCoordinator.RewardSubmitted(_user1, 0, 1, reward2, peerId1);
        vm.expectEmit(true, true, true, true);
        emit SwarmCoordinator.CumulativeRewardsUpdated(_user1, peerId1, reward1 + reward2);
        swarmCoordinator.submitReward(0, 1, reward2, peerId1);

        // Verify rewards were recorded correctly
        address[] memory accounts = new address[](1);
        accounts[0] = _user1;
        uint256[] memory rewards0 = swarmCoordinator.getRoundStageReward(0, 0, accounts);
        uint256[] memory rewards1 = swarmCoordinator.getRoundStageReward(0, 1, accounts);
        string[] memory peerIds = new string[](1);
        peerIds[0] = peerId1;
        uint256[] memory totalRewards = swarmCoordinator.getTotalRewards(peerIds);
        assertEq(rewards0[0], reward1);
        assertEq(rewards1[0], reward2);
        assertEq(totalRewards[0], reward1 + reward2);
    }

    function test_Anyone_CanSubmitReward_InDifferentRounds_Successfully() public {
        uint256 reward1 = 100;
        uint256 reward2 = 200;
        string memory peerId1 = "QmPeer1";

        // Submit reward in round 0
        vm.startPrank(_user1);
        swarmCoordinator.registerPeer(peerId1);
        vm.expectEmit(true, true, true, true);
        emit SwarmCoordinator.RewardSubmitted(_user1, 0, 0, reward1, peerId1);
        vm.expectEmit(true, true, true, true);
        emit SwarmCoordinator.CumulativeRewardsUpdated(_user1, peerId1, reward1);
        swarmCoordinator.submitReward(0, 0, reward1, peerId1);
        vm.stopPrank();

        // Forward to next round
        _forwardToNextRound();

        // Submit reward in round 1
        vm.startPrank(_user1);
        vm.expectEmit(true, true, true, true);
        emit SwarmCoordinator.RewardSubmitted(_user1, 1, 0, reward2, peerId1);
        vm.expectEmit(true, true, true, true);
        emit SwarmCoordinator.CumulativeRewardsUpdated(_user1, peerId1, reward1 + reward2);
        swarmCoordinator.submitReward(1, 0, reward2, peerId1);

        // Verify rewards were recorded correctly
        address[] memory accounts = new address[](1);
        accounts[0] = _user1;
        uint256[] memory rewards0 = swarmCoordinator.getRoundStageReward(0, 0, accounts);
        uint256[] memory rewards1 = swarmCoordinator.getRoundStageReward(1, 0, accounts);
        string[] memory peerIds = new string[](1);
        peerIds[0] = peerId1;
        uint256[] memory totalRewards = swarmCoordinator.getTotalRewards(peerIds);
        assertEq(rewards0[0], reward1);
        assertEq(rewards1[0], reward2);
        assertEq(totalRewards[0], reward1 + reward2);
    }

    function test_Anyone_CanSubmitReward_ForPastRound_Successfully() public {
        uint256 reward1 = 100;
        uint256 reward2 = 200;

        string memory peerId1 = "QmPeer1";
        string memory peerId2 = "QmPeer2";

        // Submit reward in round 0
        vm.startPrank(_user1);
        swarmCoordinator.registerPeer(peerId1);
        swarmCoordinator.submitReward(0, 0, reward1, peerId1);
        vm.stopPrank();

        // Forward to next round
        _forwardToNextRound();

        // Submit reward for round 0 again (as a different user)
        vm.startPrank(_user2);
        swarmCoordinator.registerPeer(peerId2);
        swarmCoordinator.submitReward(0, 0, reward2, peerId2);
        vm.stopPrank();

        // Verify rewards were recorded correctly
        address[] memory accounts = new address[](2);
        accounts[0] = _user1;
        accounts[1] = _user2;
        uint256[] memory rewards = swarmCoordinator.getRoundStageReward(0, 0, accounts);
        assertEq(rewards[0], reward1);
        assertEq(rewards[1], reward2);
    }

    function test_Nobody_CanSubmitRewards_ForDifferentPeer_Fails() public {
        uint256 reward1 = 100;

        string memory peerId1 = "QmPeer1";
        string memory peerId2 = "QmPeer2";

        vm.prank(_user1);
        swarmCoordinator.registerPeer(peerId1);

        vm.prank(_user2);
        swarmCoordinator.registerPeer(peerId2);

        vm.prank(_user1);
        vm.expectRevert();
        swarmCoordinator.submitReward(0, 0, reward1, peerId2);
    }

    function test_GetRoundStageReward_MultipleAddresses_Successfully() public {
        uint256 reward1 = 100;
        uint256 reward2 = 200;
        uint256 reward3 = 300;

        string memory peerId1 = "QmPeer1";
        string memory peerId2 = "QmPeer2";
        string memory peerId3 = "QmPeer3";

        // Submit rewards for different users
        vm.startPrank(_user1);
        swarmCoordinator.registerPeer(peerId1);
        swarmCoordinator.submitReward(0, 0, reward1, peerId1);
        vm.stopPrank();

        vm.startPrank(_user2);
        swarmCoordinator.registerPeer(peerId2);
        swarmCoordinator.submitReward(0, 0, reward2, peerId2);
        vm.stopPrank();

        vm.startPrank(_user3);
        swarmCoordinator.registerPeer(peerId3);
        swarmCoordinator.submitReward(0, 0, reward3, peerId3);
        vm.stopPrank();

        // Get rewards for multiple addresses
        address[] memory accounts = new address[](3);
        accounts[0] = _user1;
        accounts[1] = _user2;
        accounts[2] = _user3;
        uint256[] memory rewards = swarmCoordinator.getRoundStageReward(0, 0, accounts);

        // Verify the rewards
        assertEq(rewards.length, 3);
        assertEq(rewards[0], reward1);
        assertEq(rewards[1], reward2);
        assertEq(rewards[2], reward3);
    }

    function test_GetRoundStageReward_EmptyArray_Successfully() public view {
        address[] memory accounts = new address[](0);
        uint256[] memory rewards = swarmCoordinator.getRoundStageReward(0, 0, accounts);
        assertEq(rewards.length, 0);
    }

    function test_GetTotalRewards_MultipleAddresses_Successfully() public {
        uint256 reward1 = 100;
        uint256 reward2 = 200;
        uint256 reward3 = 300;

        string memory peerId1 = "QmPeer1";
        string memory peerId2 = "QmPeer2";
        string memory peerId3 = "QmPeer3";

        // Submit rewards for different users
        vm.startPrank(_user1);
        swarmCoordinator.registerPeer(peerId1);
        swarmCoordinator.submitReward(0, 0, reward1, peerId1);
        vm.stopPrank();

        vm.startPrank(_user2);
        swarmCoordinator.registerPeer(peerId2);
        swarmCoordinator.submitReward(0, 0, reward2, peerId2);
        vm.stopPrank();

        vm.startPrank(_user3);
        swarmCoordinator.registerPeer(peerId3);
        swarmCoordinator.submitReward(0, 0, reward3, peerId3);
        vm.stopPrank();

        // Get total rewards for multiple peer IDs
        string[] memory peerIds = new string[](3);
        peerIds[0] = peerId1;
        peerIds[1] = peerId2;
        peerIds[2] = peerId3;
        uint256[] memory totalRewards = swarmCoordinator.getTotalRewards(peerIds);

        // Verify the total rewards
        assertEq(totalRewards.length, 3);
        assertEq(totalRewards[0], reward1);
        assertEq(totalRewards[1], reward2);
        assertEq(totalRewards[2], reward3);
    }

    function test_GetTotalRewards_EmptyArray_Successfully() public view {
        string[] memory peerIds = new string[](0);
        uint256[] memory totalRewards = swarmCoordinator.getTotalRewards(peerIds);
        assertEq(totalRewards.length, 0);
    }
}
