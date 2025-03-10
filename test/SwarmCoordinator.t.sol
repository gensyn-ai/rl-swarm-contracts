// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {SwarmCoordinator} from "../src/SwarmCoordinator.sol";

contract SwarmCoordinatorTest is Test {
    SwarmCoordinator public swarmCoordinator;

    uint256[3] stageDurations = [uint256(100), uint256(100), uint256(100)];

    address owner = makeAddr("owner");

    function setUp() public {
        vm.startPrank(owner);
        swarmCoordinator = new SwarmCoordinator();
        vm.stopPrank();
    }

    function test_SwarmCoordinator_IsCorrectlyDeployed() public {
        assertEq(swarmCoordinator.owner(), address(owner));
    }

    function test_Owner_CanSetStageDurations_Successfully() public {
        vm.prank(owner);
        swarmCoordinator.setStageDurations(stageDurations);
    }

    function test_Nobody_CanSetStageDurations_Successfully() public {
        vm.expectRevert();
        swarmCoordinator.setStageDurations(stageDurations);
    }

    function test_Owner_CanSetStageCount_Successfully(uint stageCount) public {
        vm.prank(owner);
        swarmCoordinator.setStageCount(stageCount);
        assertEq(stageCount, swarmCoordinator.stageCount());
    }

    function test_Nobody_CanSetStageCount_Successfully(uint stageCount) public {
        vm.expectRevert();
        swarmCoordinator.setStageCount(stageCount);
    }

    function test_Anyone_Can_QueryCurrentRound() public {
        uint256 currentRound = swarmCoordinator.currentRound();
        assertEq(currentRound, 0);
    }

    function test_Anyone_CanAdvanceStage_IfEnoughTimeHasPassed() public {
        vm.startPrank(owner);
        swarmCoordinator.setStageDurations(stageDurations);
        swarmCoordinator.setStageCount(stageDurations.length);
        vm.stopPrank();

        uint256 currentStage = uint256(swarmCoordinator.currentStage());

        vm.roll(block.number + stageDurations[currentStage] + 1);
        (, uint256 newStage) = swarmCoordinator.updateStageAndRound();

        assertEq(newStage, currentStage + 1);
    }

    function test_Nobody_CanAdvanceStage_IfNotEnoughTimeHasPassed() public {
        vm.prank(owner);
        swarmCoordinator.setStageDurations(stageDurations);

        uint256 currentStage = uint256(swarmCoordinator.currentStage());

        vm.roll(block.number + stageDurations[currentStage] - 1);

        vm.expectRevert(SwarmCoordinator.StageDurationNotElapsed.selector);
        swarmCoordinator.updateStageAndRound();
    }

    function test_Anyone_CanAdvanceRound_IfEnoughTimeHasPassed() public {
        vm.startPrank(owner);
        swarmCoordinator.setStageDurations(stageDurations);
        swarmCoordinator.setStageCount(stageDurations.length);
        vm.stopPrank();

        uint256 currentRound = uint256(swarmCoordinator.currentRound());

        for (uint256 i = 0; i < stageDurations.length; i++) {
            vm.roll(block.number + stageDurations[i] + 1);
            swarmCoordinator.updateStageAndRound();
        }

        uint256 newRound = uint256(swarmCoordinator.currentRound());
        uint256 newStage = uint256(swarmCoordinator.currentStage());
        assertEq(newRound, currentRound + 1);
        assertEq(newStage, 0);
    }
}
