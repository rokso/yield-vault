// SPDX-License-Identifier: MIT

pragma solidity 0.8.30;

import {PausableUpgradeable as Pausable} from "@openzeppelin/contracts-upgradeable/utils/PausableUpgradeable.sol";
import {ShutdownableUpgradeable as Shutdownable} from "src/ShutdownableUpgradeable.sol";
import {VesperPool} from "src/VesperPool.sol";
import {VesperPoolTestBase} from "test/VesperPoolTestBase.t.sol";

/// Tests for Keeper role
contract VesperPool_Keeper_Test is VesperPoolTestBase {
    function test_pause() public {
        assertFalse(pool.paused());
        pool.pause();
        assertTrue(pool.paused());
    }

    function test_pause_revertWhen_callerIsNotKeeper() public {
        assertFalse(pool.isKeeper(alice));

        vm.expectRevert(VesperPool.CallerIsNotKeeper.selector);
        vm.prank(alice);
        pool.pause();
    }

    function test_unpause() public {
        pool.pause();
        assertTrue(pool.paused());
        pool.unpause();
        assertFalse(pool.paused());
    }

    function test_unpause_revertWhen_poolIsNotPaused() public {
        assertFalse(pool.paused());
        vm.expectRevert(Pausable.ExpectedPause.selector);
        pool.unpause();
    }

    function test_unpause_revertWhen_poolIsShutdown() public {
        pool.shutdown();
        assertTrue(pool.isShutdown());
        vm.expectRevert(Shutdownable.EnforcedShutdown.selector);
        pool.unpause();
    }

    function test_unpause_revertWhen_callerIsNotKeeper() public {
        assertFalse(pool.isKeeper(alice));
        vm.expectRevert(VesperPool.CallerIsNotKeeper.selector);
        vm.prank(alice);
        pool.unpause();
    }

    function test_shutdown() public {
        assertFalse(pool.isShutdown());
        pool.shutdown();
        assertTrue(pool.isShutdown());
    }

    function test_shutdown_revertWhen_callerIsNotKeeper() public {
        assertFalse(pool.isKeeper(alice));

        vm.expectRevert(VesperPool.CallerIsNotKeeper.selector);
        vm.prank(alice);
        pool.shutdown();
    }

    function test_restart() public {
        pool.shutdown();
        assertTrue(pool.isShutdown());
        pool.restart();
        assertFalse(pool.isShutdown());
    }

    function test_restart_revertWhen_poolIsNotShutdown() public {
        assertFalse(pool.isShutdown());
        vm.expectRevert(Shutdownable.ExpectedShutdown.selector);
        pool.restart();
    }

    function test_restart_revertWhen_callerIsNotKeeper() public {
        assertFalse(pool.isKeeper(alice));
        vm.expectRevert(VesperPool.CallerIsNotKeeper.selector);
        vm.prank(alice);
        pool.restart();
    }

    function test_addKeeper() public {
        assertFalse(pool.isKeeper(alice));
        pool.addKeeper(alice);
        assertTrue(pool.isKeeper(alice));
    }

    function test_addKeeper_revertWhen_addingSameKeeperAgain() public {
        pool.addKeeper(alice);
        vm.expectRevert(VesperPool.AddInListFailed.selector);
        pool.addKeeper(alice);
    }

    function test_addKeeper_revertWhen_callerIsNotKeeper() public {
        assertFalse(pool.isKeeper(alice));
        vm.expectRevert(VesperPool.CallerIsNotKeeper.selector);
        vm.prank(alice);
        pool.addKeeper(alice);
    }

    function test_removeKeeper() public {
        pool.addKeeper(alice);
        pool.removeKeeper(alice);
        assertFalse(pool.isKeeper(alice));
    }

    function test_removeKeeper_revertWhen_removingNonExistingKeeper() public {
        assertFalse(pool.isKeeper(alice));
        vm.expectRevert(VesperPool.RemoveFromListFailed.selector);
        pool.removeKeeper(alice);
    }

    function test_removeKeeper_revertWhen_callerIsNotKeeper() public {
        assertFalse(pool.isKeeper(alice));
        vm.expectRevert(VesperPool.CallerIsNotKeeper.selector);
        vm.prank(alice);
        pool.removeKeeper(alice);
    }

    function test_addMaintainer() public {
        assertFalse(pool.isMaintainer(alice));
        pool.addMaintainer(alice);
        assertTrue(pool.isMaintainer(alice));
    }

    function test_addMaintainer_revertWhen_addingSameMaintainerAgain() public {
        pool.addMaintainer(alice);
        vm.expectRevert(VesperPool.AddInListFailed.selector);
        pool.addMaintainer(alice);
    }

    function test_addMaintainer_revertWhen_callerIsNotKeeper() public {
        assertFalse(pool.isKeeper(alice));
        vm.expectRevert(VesperPool.CallerIsNotKeeper.selector);
        vm.prank(alice);
        pool.addMaintainer(alice);
    }

    function test_removeMaintainer() public {
        pool.addMaintainer(alice);
        pool.removeMaintainer(alice);
        assertFalse(pool.isMaintainer(alice));
    }

    function test_removeMaintainer_revertWhen_removingNonExistingMaintainer() public {
        assertFalse(pool.isMaintainer(alice));
        vm.expectRevert(VesperPool.RemoveFromListFailed.selector);
        pool.removeMaintainer(alice);
    }

    function test_removeMaintainer_revertWhen_callerIsNotKeeper() public {
        assertFalse(pool.isKeeper(alice));
        vm.expectRevert(VesperPool.CallerIsNotKeeper.selector);
        vm.prank(alice);
        pool.removeMaintainer(alice);
    }
}
