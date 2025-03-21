// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {SwarmCoordinator} from "../src/SwarmCoordinator.sol";

contract SwarmCoordinatorTest is Test {
    SwarmCoordinator public swarmCoordinator;

    address _owner = makeAddr("owner");
    address _bootnodeManager = makeAddr("bootnodeManager");
    address _judge = makeAddr("judge");
    address _user = makeAddr("user");

    function setUp() public {
        vm.startPrank(_owner);
        swarmCoordinator = new SwarmCoordinator();
        vm.stopPrank();
    }

    function test_SwarmCoordinator_IsCorrectlyDeployed() public view {
        assertEq(swarmCoordinator.owner(), address(_owner));
    }

    function test_Owner_CanSetStageDurations_Successfully() public {
        uint256 stage_ = 5;
        uint256 stageDuration_ = 100;

        vm.startPrank(_owner);
        // We make sure we got enough stages set to avoid an out of bounds error
        swarmCoordinator.setStageCount(stage_ + 1);
        swarmCoordinator.setStageDuration(stage_, stageDuration_);
        vm.stopPrank();
    }

    function test_Owner_CannotSetStageDuration_ForOutOfBoundsStage() public {
        uint256 stageCount_ = 3;

        vm.startPrank(_owner);
        swarmCoordinator.setStageCount(stageCount_);
        vm.expectRevert(SwarmCoordinator.StageOutOfBounds.selector);
        swarmCoordinator.setStageDuration(stageCount_, 100);
        vm.stopPrank();
    }

    function test_Nobody_CanSetStageDurations_Successfully() public {
        vm.expectRevert();
        swarmCoordinator.setStageDuration(0, 1);
    }

    function test_Owner_CanSetStageCount_Successfully(uint256 stageCount) public {
        vm.prank(_owner);
        swarmCoordinator.setStageCount(stageCount);
        assertEq(stageCount, swarmCoordinator.stageCount());
    }

    function test_Nobody_CanSetStageCount_Successfully(uint256 stageCount) public {
        vm.expectRevert();
        swarmCoordinator.setStageCount(stageCount);
    }

    function test_Anyone_CanQuery_CurrentRound() public view {
        uint256 currentRound = swarmCoordinator.currentRound();
        assertEq(currentRound, 0);
    }

    function test_Anyone_CanAdvanceStage_IfEnoughTimeHasPassed() public {
        uint256 stageCount_ = 2;
        uint256 stageDuration_ = 100;

        vm.startPrank(_owner);
        swarmCoordinator.setStageCount(stageCount_);
        swarmCoordinator.setStageDuration(0, stageDuration_);
        swarmCoordinator.setStageDuration(1, stageDuration_);
        vm.stopPrank();

        uint256 startingStage = uint256(swarmCoordinator.currentStage());

        vm.roll(block.number + stageDuration_ + 1);
        (, uint256 newStage) = swarmCoordinator.updateStageAndRound();

        assertEq(newStage, startingStage + 1);
    }

    function test_Nobody_CanAdvanceStage_IfNotEnoughTimeHasPassed() public {
        uint256 stageDuration_ = 100;

        vm.startPrank(_owner);
        swarmCoordinator.setStageCount(1);
        swarmCoordinator.setStageDuration(0, stageDuration_);
        vm.stopPrank();

        vm.roll(block.number + stageDuration_ - 1);

        vm.expectRevert(SwarmCoordinator.StageDurationNotElapsed.selector);
        swarmCoordinator.updateStageAndRound();
    }

    function test_Anyone_CanAdvanceRound_IfEnoughTimeHasPassed() public {
        uint256 stageCount_ = 3;
        uint256 stageDuration_ = 100;

        vm.startPrank(_owner);
        swarmCoordinator.setStageCount(stageCount_);
        swarmCoordinator.setStageDuration(0, stageDuration_);
        swarmCoordinator.setStageDuration(1, stageDuration_);
        swarmCoordinator.setStageDuration(2, stageDuration_);
        vm.stopPrank();

        uint256 startingRound = uint256(swarmCoordinator.currentRound());

        for (uint256 i = 0; i < stageCount_; i++) {
            vm.roll(block.number + stageDuration_ + 1);
            swarmCoordinator.updateStageAndRound();
        }

        uint256 newRound = uint256(swarmCoordinator.currentRound());
        uint256 newStage = uint256(swarmCoordinator.currentStage());
        assertEq(newRound, startingRound + 1);
        assertEq(newStage, 0);
    }

    function test_Anyone_CanAddPeer_Successfully() public {
        address user = makeAddr("user");
        bytes memory peerId = bytes("QmYyQSo1c1Ym7orWxLYvCrM2EmxFTANf8wXmmE7DWjhx5N");

        vm.startPrank(user);
        vm.expectEmit(true, true, false, true);
        emit SwarmCoordinator.PeerRegistered(user, peerId);
        swarmCoordinator.registerPeer(peerId);
        vm.stopPrank();

        // Verify the mapping was updated correctly using the getter function
        bytes memory storedPeerId = swarmCoordinator.getPeerId(user);
        assertEq(keccak256(storedPeerId), keccak256(peerId), "Peer ID not stored correctly");
    }

    function test_Anyone_CanRegister_DifferentPeerIds() public {
        address user1 = makeAddr("user1");
        address user2 = makeAddr("user2");
        bytes memory peerId1 = bytes("peerId1");
        bytes memory peerId2 = bytes("peerId2");

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
        bytes memory storedPeerId1 = swarmCoordinator.getPeerId(user1);
        bytes memory storedPeerId2 = swarmCoordinator.getPeerId(user2);
        assertEq(keccak256(storedPeerId1), keccak256(peerId1), "Peer ID 1 not stored correctly");
        assertEq(keccak256(storedPeerId2), keccak256(peerId2), "Peer ID 2 not stored correctly");
    }

    function test_Anyone_CanUpdate_ItsOwnPeerId() public {
        address user = makeAddr("user");
        bytes memory peerId1 = bytes("peerId1");
        bytes memory peerId2 = bytes("peerId2");

        // User registers first peer
        vm.prank(user);
        vm.expectEmit(true, true, false, true);
        emit SwarmCoordinator.PeerRegistered(user, peerId1);
        swarmCoordinator.registerPeer(peerId1);

        // Verify first peer ID was stored correctly
        bytes memory storedPeerId1 = swarmCoordinator.getPeerId(user);
        assertEq(keccak256(storedPeerId1), keccak256(peerId1), "First peer ID not stored correctly");

        // User updates to second peer
        vm.prank(user);
        vm.expectEmit(true, true, false, true);
        emit SwarmCoordinator.PeerRegistered(user, peerId2);
        swarmCoordinator.registerPeer(peerId2);

        // Verify second peer ID overwrote the first one
        bytes memory storedPeerId2 = swarmCoordinator.getPeerId(user);
        assertEq(keccak256(storedPeerId2), keccak256(peerId2), "Second peer ID not stored correctly");
        assertTrue(keccak256(storedPeerId2) != keccak256(peerId1), "Peer ID was not updated");
    }

    // Bootnode tests
    function test_SwarmCoordinatorDeployment_SetsBootnodeManager_ToOwner() public view {
        assertEq(swarmCoordinator.bootnodeManager(), _owner);
    }

    function test_Owner_CanSet_BootnodeManager() public {
        vm.startPrank(_owner);
        vm.expectEmit(true, true, false, false);
        emit SwarmCoordinator.BootnodeManagerUpdated(_owner, _bootnodeManager);
        swarmCoordinator.setBootnodeManager(_bootnodeManager);
        vm.stopPrank();

        assertEq(swarmCoordinator.bootnodeManager(), _bootnodeManager);
    }

    function test_NonOwner_CannotSet_BootnodeManager() public {
        vm.prank(_user);
        vm.expectRevert();
        swarmCoordinator.setBootnodeManager(_bootnodeManager);
    }

    function test_BootnodeManager_CanAdd_Bootnodes() public {
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

    function test_NonBootnodeManager_CannotAddBootnodes() public {
        string[] memory newBootnodes = new string[](1);
        newBootnodes[0] = "/ip4/127.0.0.1/tcp/4001/p2p/QmBootnode1";

        vm.prank(_user);
        vm.expectRevert(SwarmCoordinator.OnlyBootnodeManager.selector);
        swarmCoordinator.addBootnodes(newBootnodes);
    }

    function test_BootnodeManager_CanRemoveBootnode() public {
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

    function test_BootnodeManager_CannotRemoveInvalidIndex() public {
        vm.prank(_owner);
        vm.expectRevert(SwarmCoordinator.InvalidBootnodeIndex.selector);
        swarmCoordinator.removeBootnode(0); // No bootnodes yet
    }

    function test_NonBootnodeManager_CannotRemoveBootnode() public {
        // First add a bootnode as the owner
        string[] memory newBootnodes = new string[](1);
        newBootnodes[0] = "bootnode1";

        vm.prank(_owner);
        swarmCoordinator.addBootnodes(newBootnodes);

        // Try to remove as non-manager
        vm.prank(_user);
        vm.expectRevert(SwarmCoordinator.OnlyBootnodeManager.selector);
        swarmCoordinator.removeBootnode(0);
    }

    function test_BootnodeManager_CanClearAllBootnodes() public {
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

    function test_NonBootnodeManager_CannotClearBootnodes() public {
        // First add a bootnode as the owner
        string[] memory newBootnodes = new string[](1);
        newBootnodes[0] = "bootnode1";

        vm.prank(_owner);
        swarmCoordinator.addBootnodes(newBootnodes);

        // Try to clear as non-manager
        vm.prank(_user);
        vm.expectRevert(SwarmCoordinator.OnlyBootnodeManager.selector);
        swarmCoordinator.clearBootnodes();
    }

    function test_Anyone_CanGetBootnodes() public {
        // First add some bootnodes as the owner
        string[] memory newBootnodes = new string[](2);
        newBootnodes[0] = "bootnode1";
        newBootnodes[1] = "bootnode2";

        vm.prank(_owner);
        swarmCoordinator.addBootnodes(newBootnodes);

        // Get bootnodes as a regular user
        vm.prank(_user);
        string[] memory storedBootnodes = swarmCoordinator.getBootnodes();

        // Verify the bootnodes are accessible
        assertEq(storedBootnodes.length, 2);
        assertEq(storedBootnodes[0], newBootnodes[0]);
        assertEq(storedBootnodes[1], newBootnodes[1]);
    }

    function test_Anyone_CanGetBootnodesCount() public {
        // First add some bootnodes as the owner
        string[] memory newBootnodes = new string[](3);
        newBootnodes[0] = "bootnode1";
        newBootnodes[1] = "bootnode2";
        newBootnodes[2] = "bootnode3";

        vm.prank(_owner);
        swarmCoordinator.addBootnodes(newBootnodes);

        // Get bootnode count as a regular user
        vm.prank(_user);
        uint256 count = swarmCoordinator.getBootnodesCount();

        // Verify the count is correct
        assertEq(count, 3);
    }

    // Judge tests
    function test_SwarmCoordinatorDeployment_SetsJudge_ToOwner() public view {
        assertEq(swarmCoordinator.judge(), _owner);
    }

    function test_Owner_CanSet_Judge() public {
        vm.startPrank(_owner);
        vm.expectEmit(true, true, false, false);
        emit SwarmCoordinator.JudgeUpdated(_owner, _judge);
        swarmCoordinator.setJudge(_judge);
        vm.stopPrank();

        assertEq(swarmCoordinator.judge(), _judge);
    }

    function test_NonOwner_CannotSet_Judge() public {
        vm.prank(_user);
        vm.expectRevert();
        swarmCoordinator.setJudge(_judge);
    }

    function test_Judge_CanSubmitWinners_Successfully() public {
        address[] memory winners = new address[](2);
        winners[0] = makeAddr("winner1");
        winners[1] = makeAddr("winner2");

        // Set judge
        vm.prank(_owner);
        swarmCoordinator.setJudge(_judge);

        // Submit winners for round 0
        vm.prank(_judge);
        vm.expectEmit(true, true, false, true);
        emit SwarmCoordinator.WinnerSubmitted(0, winners);
        swarmCoordinator.submitWinner(0, winners);

        // Verify winners
        address[] memory roundWinners = swarmCoordinator.getRoundWinners(0);
        assertEq(roundWinners.length, 2);
        assertEq(roundWinners[0], winners[0]);
        assertEq(roundWinners[1], winners[1]);
    }

    function test_NonJudge_CannotSubmit_Winners() public {
        address[] memory winners = new address[](1);
        winners[0] = makeAddr("winner");

        vm.prank(_user);
        vm.expectRevert(SwarmCoordinator.NotJudge.selector);
        swarmCoordinator.submitWinner(0, winners);
    }

    function test_Nobody_CanSubmitWinners_ForFutureRound() public {
        address[] memory winners = new address[](1);
        winners[0] = makeAddr("winner");

        // Set judge
        vm.prank(_owner);
        swarmCoordinator.setJudge(_judge);

        // Try to submit winners for future round
        vm.prank(_judge);
        vm.expectRevert(SwarmCoordinator.InvalidRoundNumber.selector);
        swarmCoordinator.submitWinner(1, winners);
    }

    function test_Anyone_CanGetRoundWinners() public {
        address[] memory winners = new address[](2);
        winners[0] = makeAddr("winner1");
        winners[1] = makeAddr("winner2");

        // Set judge and submit winners
        vm.prank(_owner);
        swarmCoordinator.setJudge(_judge);

        vm.prank(_judge);
        swarmCoordinator.submitWinner(0, winners);

        // Get winners as regular user
        vm.prank(_user);
        address[] memory roundWinners = swarmCoordinator.getRoundWinners(0);

        // Verify winners
        assertEq(roundWinners.length, 2);
        assertEq(roundWinners[0], winners[0]);
        assertEq(roundWinners[1], winners[1]);
    }

    // Leaderboard tests
    function test_TotalWins_AreTrackedCorrectly() public {
        address[] memory winners = new address[](2);
        winners[0] = makeAddr("winner1");
        winners[1] = makeAddr("winner2");

        // Set judge and submit winners for multiple rounds
        vm.prank(_owner);
        swarmCoordinator.setJudge(_judge);

        // Submit winners for round 0
        vm.prank(_judge);
        swarmCoordinator.submitWinner(0, winners);

        // Forward to next round
        vm.startPrank(_owner);
        swarmCoordinator.setStageCount(1);
        swarmCoordinator.setStageDuration(0, 10);
        vm.roll(block.number + 10);
        (uint256 newRound,) = swarmCoordinator.updateStageAndRound();
        assertEq(newRound, 1);
        vm.stopPrank();

        // Submit winners for round 1
        vm.prank(_judge);
        swarmCoordinator.submitWinner(1, winners);

        // Verify total wins
        assertEq(swarmCoordinator.getTotalWins(winners[0]), 2);
        assertEq(swarmCoordinator.getTotalWins(winners[1]), 2);
    }

    function test_GetTopWinners_ReturnsCorrectOrder() public {
        address[] memory winners1 = new address[](2);
        winners1[0] = makeAddr("winner1");
        winners1[1] = makeAddr("winner2");

        address[] memory winners2 = new address[](1);
        winners2[0] = makeAddr("winner3");

        // Set stage count and duration
        vm.startPrank(_owner);
        swarmCoordinator.setStageCount(1);
        swarmCoordinator.setStageDuration(0, 10);
        vm.stopPrank();

        // Set judge and submit winners for multiple rounds
        vm.prank(_owner);
        swarmCoordinator.setJudge(_judge);

        // Submit winners for round 0
        vm.prank(_judge);
        swarmCoordinator.submitWinner(0, winners1);

        // Forward to next round
        vm.roll(block.number + 10);
        swarmCoordinator.updateStageAndRound();

        // Submit winners for round 1
        vm.prank(_judge);
        swarmCoordinator.submitWinner(1, winners2);

        // Forward to next round
        vm.roll(block.number + 10);
        swarmCoordinator.updateStageAndRound();

        // Submit winners for round 2 (same as round 0)
        vm.prank(_judge);
        swarmCoordinator.submitWinner(2, winners1);

        // Get top 3 winners
        address[] memory topWinners = swarmCoordinator.leaderboard(0, 3);

        // Verify order (winners1[0] and winners1[1] should be tied with 2 wins each)
        assertEq(topWinners.length, 3);
        assertEq(topWinners[0], winners1[0]);
        assertEq(topWinners[1], winners1[1]);
        assertEq(topWinners[2], winners2[0]);
        assertEq(swarmCoordinator.getTotalWins(topWinners[0]), 2);
        assertEq(swarmCoordinator.getTotalWins(topWinners[1]), 2);
        assertEq(swarmCoordinator.getTotalWins(topWinners[2]), 1);
    }

    function test_GetTopWinners_HandlesLessWinnersThanRequested() public {
        address[] memory winners = new address[](2);
        winners[0] = makeAddr("winner1");
        winners[1] = makeAddr("winner2");

        // Set judge and submit winners
        vm.prank(_owner);
        swarmCoordinator.setJudge(_judge);

        // Submit winners for round 0
        vm.prank(_judge);
        swarmCoordinator.submitWinner(0, winners);

        // Request top 5 winners when only 2 exist
        address[] memory topWinners = swarmCoordinator.leaderboard(0, 5);

        // Verify we only get 2 winners
        assertEq(topWinners.length, 2);
        assertEq(swarmCoordinator.getTotalWins(topWinners[0]), 1);
        assertEq(swarmCoordinator.getTotalWins(topWinners[1]), 1);
    }

    function test_Leaderboard_HandlesInvalidIndexes() public {
        address[] memory winners = new address[](2);
        winners[0] = makeAddr("winner1");
        winners[1] = makeAddr("winner2");

        // Set judge and submit winners
        vm.prank(_owner);
        swarmCoordinator.setJudge(_judge);

        // Submit winners for round 0
        vm.prank(_judge);
        swarmCoordinator.submitWinner(0, winners);

        // Test with start > end
        vm.expectRevert("Start index must be less than or equal to end index");
        swarmCoordinator.leaderboard(2, 1);

        // Test with start > length
        address[] memory result = swarmCoordinator.leaderboard(5, 10);
        assertEq(result.length, 0);

        // Test with end > length
        result = swarmCoordinator.leaderboard(0, 10);
        assertEq(result.length, 2);
    }

    function test_Leaderboard_ReturnsCorrectSlice() public {
        address[] memory winners1 = new address[](2);
        winners1[0] = makeAddr("winner1");
        winners1[1] = makeAddr("winner2");

        address[] memory winners2 = new address[](1);
        winners2[0] = makeAddr("winner3");

        // Set stage count and duration
        vm.startPrank(_owner);
        swarmCoordinator.setStageCount(1);
        swarmCoordinator.setStageDuration(0, 10);
        vm.stopPrank();

        // Set judge and submit winners for multiple rounds
        vm.prank(_owner);
        swarmCoordinator.setJudge(_judge);

        // Submit winners for round 0
        vm.prank(_judge);
        swarmCoordinator.submitWinner(0, winners1);

        // Forward to next round
        vm.roll(block.number + 10);
        swarmCoordinator.updateStageAndRound();

        // Submit winners for round 1
        vm.prank(_judge);
        swarmCoordinator.submitWinner(1, winners2);

        // Forward to next round
        vm.roll(block.number + 10);
        swarmCoordinator.updateStageAndRound();

        // Submit winners for round 2 (same as round 0)
        vm.prank(_judge);
        swarmCoordinator.submitWinner(2, winners1);

        // Get slice from index 2 to 3
        address[] memory slice = swarmCoordinator.leaderboard(2, 3);
        assertEq(slice.length, 1);
        assertEq(slice[0], winners2[0]);
        assertEq(swarmCoordinator.getTotalWins(slice[0]), 1);
    }
}
