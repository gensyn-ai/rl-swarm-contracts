// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {SwarmCoordinator} from "../src/SwarmCoordinator.sol";

contract SwarmCoordinatorPermissionsTest is Test {
    SwarmCoordinator public swarmCoordinator;

    address public _owner = makeAddr("owner");
    address public _newAccount = makeAddr("newAccount");

    function setUp() public {
        vm.startPrank(_owner);
        swarmCoordinator = new SwarmCoordinator();
        swarmCoordinator.initialize(_owner);
        vm.stopPrank();
    }

    function test_Owner_CanAdd_Owners() public {
        vm.startPrank(_owner);

        assertEq(swarmCoordinator.hasRole(swarmCoordinator.OWNER_ROLE(), _newAccount), false);
        swarmCoordinator.grantRole(swarmCoordinator.OWNER_ROLE(), _newAccount);
        assertEq(swarmCoordinator.hasRole(swarmCoordinator.OWNER_ROLE(), _newAccount), true);

        vm.stopPrank();
    }

    function test_Owner_CanRemove_Owners() public {
        vm.startPrank(_owner);

        swarmCoordinator.grantRole(swarmCoordinator.OWNER_ROLE(), _newAccount);
        assertEq(swarmCoordinator.hasRole(swarmCoordinator.OWNER_ROLE(), _newAccount), true);

        swarmCoordinator.revokeRole(swarmCoordinator.OWNER_ROLE(), _newAccount);
        assertEq(swarmCoordinator.hasRole(swarmCoordinator.OWNER_ROLE(), _newAccount), false);

        vm.stopPrank();
    }

    function test_NonOwner_CannotAdd_Owners() public {
        address _nonOwner = makeAddr("nonOwner");
        address _newOwner = makeAddr("newOwner");

        vm.startPrank(_nonOwner);
        bytes32 ownerRole = swarmCoordinator.OWNER_ROLE();
        vm.expectRevert(SwarmCoordinator.OnlyOwner.selector);
        swarmCoordinator.grantRole(ownerRole, _newOwner);
        vm.stopPrank();
    }

    function test_Owner_CanAdd_RoundManagers() public {
        vm.startPrank(_owner);
        swarmCoordinator.grantRole(swarmCoordinator.ROUND_MANAGER_ROLE(), _newAccount);
        assertEq(swarmCoordinator.hasRole(swarmCoordinator.ROUND_MANAGER_ROLE(), _newAccount), true);
        vm.stopPrank();
    }

    function test_Owner_CanRemove_RoundManagers() public {
        vm.startPrank(_owner);
        swarmCoordinator.grantRole(swarmCoordinator.ROUND_MANAGER_ROLE(), _newAccount);
        assertEq(swarmCoordinator.hasRole(swarmCoordinator.ROUND_MANAGER_ROLE(), _newAccount), true);

        swarmCoordinator.revokeRole(swarmCoordinator.ROUND_MANAGER_ROLE(), _newAccount);
        assertEq(swarmCoordinator.hasRole(swarmCoordinator.ROUND_MANAGER_ROLE(), _newAccount), false);
        vm.stopPrank();
    }

    function test_Owner_CanAdd_BootnodeManagers() public {
        vm.startPrank(_owner);
        swarmCoordinator.grantRole(swarmCoordinator.BOOTNODE_MANAGER_ROLE(), _newAccount);
        assertEq(swarmCoordinator.hasRole(swarmCoordinator.BOOTNODE_MANAGER_ROLE(), _newAccount), true);
        vm.stopPrank();
    }

    function test_Owner_CanRemove_BootnodeManagers() public {
        vm.startPrank(_owner);
        swarmCoordinator.grantRole(swarmCoordinator.BOOTNODE_MANAGER_ROLE(), _newAccount);
        assertEq(swarmCoordinator.hasRole(swarmCoordinator.BOOTNODE_MANAGER_ROLE(), _newAccount), true);

        swarmCoordinator.revokeRole(swarmCoordinator.BOOTNODE_MANAGER_ROLE(), _newAccount);
        assertEq(swarmCoordinator.hasRole(swarmCoordinator.BOOTNODE_MANAGER_ROLE(), _newAccount), false);
        vm.stopPrank();
    }
}
