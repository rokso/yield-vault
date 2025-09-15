// SPDX-License-Identifier: MIT

pragma solidity 0.8.30;

import {VesperPool} from "src/VesperPool.sol";
import {VesperPoolTestBase} from "test/VesperPoolTestBase.t.sol";

/// Tests for Maintainer role
contract VesperPool_Maintainer_Test is VesperPoolTestBase {
    function test_updateDebtRatio() public {
        pool.addStrategy(strategy, debtRatio);
        assertEq(pool.getStrategyConfig(strategy).debtRatio, debtRatio);

        uint256 _newDebtRatio = 5_000;
        pool.updateDebtRatio(strategy, _newDebtRatio);
        assertEq(pool.getStrategyConfig(strategy).debtRatio, _newDebtRatio);
    }

    function test_updateDebtRatio_revertWhen_callerItNotMaintainer() public {
        vm.expectRevert(VesperPool.CallerIsNotMaintainer.selector);
        vm.prank(alice);
        pool.updateDebtRatio(strategy, 4_000);
    }

    function test_updateDebtRatio_revertWhen_debtRatioIsInvalid() public {
        pool.addStrategy(strategy, debtRatio);

        vm.expectRevert(VesperPool.InvalidDebtRatio.selector);
        pool.updateDebtRatio(strategy, 11_000);
    }

    function test_updateDebtRatio_revertWhen_strategyIsNotActive() public {
        vm.expectRevert(VesperPool.StrategyIsNotActive.selector);
        pool.updateDebtRatio(strategy, 5_000);
    }

    function test_updateWithdrawQueue() public {
        pool.addStrategy(strategy, debtRatio);
        pool.addStrategy(strategy2, debtRatio2);
        address[] memory _withdrawQueue = pool.getWithdrawQueue();
        assertEq(_withdrawQueue.length, 2);
        assertEq(_withdrawQueue[0], strategy);
        assertEq(_withdrawQueue[1], strategy2);

        address[] memory _newWithdrawQueue = new address[](2);
        _newWithdrawQueue[0] = strategy2;
        _newWithdrawQueue[1] = strategy;
        pool.updateWithdrawQueue(_newWithdrawQueue);
        address[] memory _withdrawQueueAfter = pool.getWithdrawQueue();
        assertEq(_withdrawQueueAfter.length, 2);
        assertEq(_withdrawQueueAfter, _newWithdrawQueue);
    }

    function test_updateWithdrawQueue_revertWhen_arrayLengthMismatch() public {
        pool.addStrategy(strategy, debtRatio);
        pool.addStrategy(strategy2, debtRatio2);
        assertEq(pool.getWithdrawQueue().length, 2);

        vm.expectRevert(VesperPool.ArrayLengthMismatch.selector);
        address[] memory _newWithdrawQueue = new address[](1);
        _newWithdrawQueue[0] = strategy2;
        pool.updateWithdrawQueue(_newWithdrawQueue);
    }

    function test_updateWithdrawQueue_revertWhen_callerItNotMaintainer() public {
        address[] memory _newWithdrawQueue = new address[](1);
        _newWithdrawQueue[0] = strategy;
        vm.expectRevert(VesperPool.CallerIsNotMaintainer.selector);
        vm.prank(alice);
        pool.updateWithdrawQueue(_newWithdrawQueue);
    }

    function test_updateWithdrawQueue_revertWhen_strategyIsNotActive() public {
        pool.addStrategy(strategy, debtRatio);
        pool.addStrategy(strategy2, debtRatio2);
        assertEq(pool.getWithdrawQueue().length, 2);

        vm.expectRevert(VesperPool.StrategyIsNotActive.selector);
        address _newStrategy = address(0x3);
        address[] memory _newWithdrawQueue = new address[](2);
        _newWithdrawQueue[0] = strategy2;
        _newWithdrawQueue[1] = _newStrategy;
        pool.updateWithdrawQueue(_newWithdrawQueue);
    }
}
