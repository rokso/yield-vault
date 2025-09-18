// SPDX-License-Identifier: MIT

pragma solidity 0.8.30;

import {PausableUpgradeable as Pausable} from "@openzeppelin/contracts-upgradeable/utils/PausableUpgradeable.sol";
import {IPoolRewards} from "src/interfaces/IPoolRewards.sol";
import {IStrategy} from "src/interfaces/IStrategy.sol";
import {ShutdownableUpgradeable as Shutdownable} from "src/ShutdownableUpgradeable.sol";
import {VesperPool} from "src/VesperPool.sol";

import {VesperPoolTestBase} from "test/VesperPoolTestBase.t.sol";
import {MockERC20} from "test/mocks/MockERC20.sol";

contract VesperPool_Test is VesperPoolTestBase {
    address bob = makeAddr("bob");

    // This is mock function and will be called in strategy context
    function withdraw(uint256 assets_) public {
        VesperPool _pool = VesperPool(msg.sender);
        address _strategy = address(this);
        MockERC20 _asset = MockERC20(_pool.asset());
        // deal assets amount at strategy address
        deal(address(_asset), _strategy, assets_);
        // transfer assets to pool
        require(_asset.transfer(address(_pool), assets_));
    }

    function _deposit(VesperPool pool_, address user_, uint256 assets_) internal {
        deal(pool_.asset(), user_, assets_);
        vm.startPrank(user_);
        MockERC20(pool_.asset()).approve(address(pool_), assets_);
        pool_.deposit(assets_, user_);
        vm.stopPrank();
    }

    function test_deposit() public {
        uint256 _assets = 100 * assetUnit;
        deal(address(asset), alice, _assets);
        vm.startPrank(alice);
        asset.approve(address(pool), _assets);
        pool.deposit(_assets, alice);
        vm.stopPrank();

        assertEq(pool.totalAssets(), _assets);
        assertEq(asset.balanceOf(address(pool)), _assets);
        assertEq(pool.pricePerShare(), assetUnit);
        assertEq(pool.balanceOf(alice), _toShares(_assets));
    }

    function test_deposit_revertWhen_assetsAreLessThanMinimumLimit() public {
        vm.expectRevert(VesperPool.AmountIsBelowDepositLimit.selector);
        pool.deposit(0, alice);
    }

    function test_deposit_revertWhen_poolIsPaused() public {
        pool.pause();
        vm.expectRevert(Pausable.EnforcedPause.selector);
        pool.deposit(10 * assetUnit, alice);
    }

    function test_deposit_updateRewards() public {
        address _poolRewards = makeAddr("poolRewards");
        pool.updatePoolRewards(_poolRewards);
        vm.mockCall(_poolRewards, abi.encodeWithSelector(IPoolRewards.updateReward.selector), "");

        // expect updateRewards to called 1 time for deposit/mint
        vm.expectCall(_poolRewards, abi.encodeWithSelector(IPoolRewards.updateReward.selector), 1);
        uint256 _assets = 100 * assetUnit;
        _deposit(pool, alice, _assets);
        assertEq(pool.balanceOf(alice), _toShares(_assets));
    }

    function test_mint() public {
        uint256 _shares = 100 ether;
        deal(address(asset), alice, _shares);
        vm.startPrank(alice);
        asset.approve(address(pool), _shares);
        pool.mint(_shares, alice);
        vm.stopPrank();
        uint256 _assets = _toAssets(_shares);
        assertEq(pool.totalAssets(), _assets);
        assertEq(asset.balanceOf(address(pool)), _assets);
        assertEq(pool.pricePerShare(), assetUnit);
        assertEq(pool.balanceOf(alice), _shares);
    }

    function test_mint_revertWhen_assetsAreLessThanMinimumLimit() public {
        vm.expectRevert(VesperPool.AmountIsBelowDepositLimit.selector);
        pool.mint(0, alice);
    }

    function test_mint_revertWhen_poolIsPaused() public {
        pool.pause();
        vm.expectRevert(Pausable.EnforcedPause.selector);
        pool.mint(1 ether, alice);
    }

    function test_redeem_success() public {
        uint256 _assets = 50 * assetUnit;
        _deposit(pool, alice, _assets);
        assertEq(pool.balanceOf(alice), (_assets * 1e18) / assetUnit);
        assertEq(asset.balanceOf(bob), 0);

        vm.prank(alice);
        pool.redeem(_toShares(_assets), bob, alice);
        assertEq(pool.balanceOf(alice), 0);
        assertEq(asset.balanceOf(bob), _assets);
    }

    function test_redeem_revertWhen_assetsCanNotBeWithdrawn() public {
        pool.addStrategy(strategy, debtRatio);
        _deposit(pool, alice, 100 * assetUnit);
        vm.prank(strategy);
        pool.reportEarning(0, 0, 0);

        uint256 _sharesToRedeem = pool.balanceOf(alice);
        // mock strategy.withdraw() call to do nothing
        vm.mockCall(strategy, abi.encodeWithSelector(IStrategy.withdraw.selector), "");
        // expect revert. only 10 assetUnit available to withdraw
        vm.expectRevert(abi.encodeWithSelector(VesperPool.AssetsCanNotBeWithdrawn.selector, 10 * assetUnit));
        vm.prank(alice);
        pool.redeem(_sharesToRedeem, alice, alice);
    }

    function test_redeem_revertWhen_poolIsShutdown() public {
        pool.shutdown();
        vm.expectRevert(Shutdownable.EnforcedShutdown.selector);
        pool.redeem(1 ether, bob, alice);
    }

    function test_redeem_revertWhen_sharesAreZero() public {
        vm.expectRevert(VesperPool.ZeroShares.selector);
        pool.redeem(0, bob, alice);
    }

    function test_redeem_withdrawFromStrategy() public {
        pool.addStrategy(strategy, debtRatio);
        uint256 _assets = 100 * assetUnit;
        _deposit(pool, alice, _assets);
        vm.prank(strategy);
        pool.reportEarning(0, 0, 0);

        // Add this contracts code at strategy address so that withdraw() of this contract can be called in strategy context.
        vm.etch(strategy, address(this).code);

        assertEq(asset.balanceOf(alice), 0);
        uint256 _sharesToRedeem = pool.balanceOf(alice);
        vm.prank(alice);
        pool.redeem(_sharesToRedeem, alice, alice);

        assertEq(pool.balanceOf(alice), 0);
        assertEq(asset.balanceOf(alice), _assets);
    }

    function test_redeem_withdrawFromSecondStrategy() public {
        // no fund in firstStrategy
        address _firstStrategy = makeAddr("_firstStrategy");
        pool.addStrategy(_firstStrategy, 100);
        pool.addStrategy(strategy, debtRatio);

        uint256 _assets = 100 * assetUnit;
        _deposit(pool, alice, _assets);
        vm.prank(strategy);
        pool.reportEarning(0, 0, 0); // deploy fund in strategy

        // Add this contracts code at strategy address so that withdraw() of this contract can be called in strategy context.
        vm.etch(strategy, address(this).code);

        assertEq(asset.balanceOf(alice), 0);
        uint256 _sharesToRedeem = pool.balanceOf(alice);
        vm.prank(alice);
        pool.redeem(_sharesToRedeem, alice, alice);

        assertEq(asset.balanceOf(alice), _assets);
    }

    function test_redeem_withdrawFromMultipleStrategy() public {
        pool.addStrategy(strategy, 5_000);
        pool.addStrategy(strategy2, 4_000);
        uint256 _assets = 100 * assetUnit;
        _deposit(pool, alice, _assets);
        vm.prank(strategy);
        pool.reportEarning(0, 0, 0); // deploy fund in strategy

        vm.prank(strategy2);
        pool.reportEarning(0, 0, 0); // deploy fund in strategy2

        assertEq(asset.balanceOf(alice), 0);
        assertGt(pool.getStrategyConfig(strategy).totalDebt, 0);
        assertGt(pool.getStrategyConfig(strategy2).totalDebt, 0);

        // Add this contracts code at strategy address so that withdraw() of this contract can be called in strategy context.
        vm.etch(strategy, address(this).code);
        vm.etch(strategy2, address(this).code);
        uint256 _sharesToRedeem = pool.balanceOf(alice);
        vm.prank(alice);
        pool.redeem(_sharesToRedeem, alice, alice);

        assertEq(asset.balanceOf(alice), _assets);
        assertEq(pool.getStrategyConfig(strategy).totalDebt, 0);
        assertEq(pool.getStrategyConfig(strategy2).totalDebt, 0);
    }

    function test_redeem_withdrawFromStrategy_errorInTryCatch() public {
        pool.addStrategy(strategy, debtRatio);
        pool.addStrategy(strategy2, debtRatio2);
        _deposit(pool, alice, 100 * assetUnit);
        vm.prank(strategy);
        pool.reportEarning(0, 0, 0); // deploy fund in strategy

        vm.prank(strategy2);
        pool.reportEarning(0, 0, 0); // deploy fund in strategy2

        assertEq(asset.balanceOf(alice), 0);
        uint256 _debtOfStrategy1 = pool.getStrategyConfig(strategy).totalDebt;
        uint256 _debtOfStrategy2 = pool.getStrategyConfig(strategy2).totalDebt;

        // revert withdraw() for 1st strategy
        vm.mockCallRevert(strategy, abi.encodeWithSelector(IStrategy.withdraw.selector), "");
        // Add this contracts code at strategy address so that withdraw() of this contract can be called in strategy context.
        vm.etch(strategy2, address(this).code);
        vm.prank(alice);
        // Total debtRatio of strategies is 10_000, so any withdraw/redeem will call withdraw on strategy
        uint256 _sharesToRedeem = 1 ether; // pps is 1:1
        pool.redeem(_sharesToRedeem, alice, alice);

        uint256 _assets = _toAssets(_sharesToRedeem);
        assertEq(asset.balanceOf(alice), _assets);
        assertEq(pool.getStrategyConfig(strategy).totalDebt, _debtOfStrategy1);
        assertEq(pool.getStrategyConfig(strategy2).totalDebt, _debtOfStrategy2 - _assets);
    }

    function test_withdraw() public {
        uint256 _assets = 50 * assetUnit;
        _deposit(pool, alice, _assets);
        assertEq(pool.balanceOf(alice), (_assets * 1e18) / assetUnit);
        assertEq(asset.balanceOf(bob), 0);

        vm.prank(alice);
        pool.withdraw(_assets, bob, alice);
        assertEq(pool.balanceOf(alice), 0);
        assertEq(asset.balanceOf(bob), _assets);
    }

    function test_withdraw_revertWhen_assetsAreZero() public {
        vm.expectRevert(VesperPool.ZeroAssets.selector);
        pool.withdraw(0, bob, alice);
    }

    function test_withdraw_revertWhen_poolIsShutdown() public {
        pool.shutdown();
        vm.expectRevert(Shutdownable.EnforcedShutdown.selector);
        pool.withdraw(1 * assetUnit, bob, alice);
    }

    function test_withdraw_updateRewards() public {
        address _poolRewards = makeAddr("poolRewards");
        pool.updatePoolRewards(_poolRewards);
        vm.mockCall(_poolRewards, abi.encodeWithSelector(IPoolRewards.updateReward.selector), "");

        uint256 _assets = 100 * assetUnit;
        _deposit(pool, alice, _assets);

        // expect updateRewards to called 1 time for withdraw/redeem
        vm.expectCall(_poolRewards, abi.encodeWithSelector(IPoolRewards.updateReward.selector), 1);
        vm.prank(alice);
        pool.withdraw(_assets, bob, alice);
        assertEq(pool.balanceOf(alice), 0);
    }

    function test_transfer_updateRewards() public {
        address _poolRewards = makeAddr("poolRewards");
        pool.updatePoolRewards(_poolRewards);
        vm.mockCall(_poolRewards, abi.encodeWithSelector(IPoolRewards.updateReward.selector), "");

        _deposit(pool, alice, 100 * assetUnit);

        // expect updateRewards to called 2 times for transfer()
        vm.expectCall(_poolRewards, abi.encodeWithSelector(IPoolRewards.updateReward.selector), 2);
        uint256 _sharesToTransfer = pool.balanceOf(alice);
        vm.prank(alice);
        require(pool.transfer(bob, _sharesToTransfer));
        assertEq(pool.balanceOf(alice), 0);
        assertEq(pool.balanceOf(bob), _sharesToTransfer);
    }
}
