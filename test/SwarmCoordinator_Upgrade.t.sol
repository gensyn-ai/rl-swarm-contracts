// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8;

import {Test, console} from "forge-std/Test.sol";
import {SwarmCoordinator} from "../src/SwarmCoordinator.sol";

import {UUPSUpgradeable} from "@openzeppelin/contracts/proxy/utils/UUPSUpgradeable.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

contract SwarmCoordinatorUpgradeTest is Test {
    SwarmCoordinator public swarmCoordinator_implementation;
    SwarmCoordinator public swarmCoordinator;

    ERC1967Proxy public proxy;

    address public _owner = makeAddr("owner");

    function setUp() public {
        swarmCoordinator_implementation = new SwarmCoordinator();
        // Not really needed, but just to be sure
        swarmCoordinator_implementation.initialize(_owner);

        bytes memory initializeCallData = abi.encodeWithSelector(SwarmCoordinator.initialize.selector, _owner);
        proxy = new ERC1967Proxy(address(swarmCoordinator_implementation), initializeCallData);

        swarmCoordinator = SwarmCoordinator(address(proxy));
    }

    function test_DeployedSuccessfully() public {
        vm.startPrank(_owner);
        assertEq(swarmCoordinator.currentRound(), 0);
        vm.stopPrank();
    }

    function test_Owner_Can_Upgrade() public {
        SwarmCoordinator newImplementation = new SwarmCoordinator();

        vm.startPrank(_owner);
        UUPSUpgradeable proxyLocation = UUPSUpgradeable(address(swarmCoordinator));
        proxyLocation.upgradeToAndCall(address(newImplementation), "");
        vm.stopPrank();
    }

    function test_NonOwner_Cannot_Upgrade() public {
        vm.startPrank(makeAddr("notOwner"));

        SwarmCoordinator newImplementation = new SwarmCoordinator();
        UUPSUpgradeable proxyLocation = UUPSUpgradeable(address(swarmCoordinator));

        vm.expectRevert(SwarmCoordinator.OnlyOwner.selector);
        proxyLocation.upgradeToAndCall(address(newImplementation), "");

        vm.stopPrank();
    }
}
