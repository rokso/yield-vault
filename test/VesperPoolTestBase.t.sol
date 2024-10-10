// SPDX-License-Identifier: MIT

pragma solidity 0.8.23;

import {Test, console} from "forge-std/Test.sol";
import {MockERC20} from "forge-std/mocks/MockERC20.sol";
import {VesperPool} from "src/VesperPool.sol";
import {Constants} from "test/helpers/Constants.sol";

contract VesperPoolTestBase is Test {
    VesperPool pool;
    MockERC20 asset;
    address alice = makeAddr("alice");
    address feeCollector = makeAddr("feeCollector");
    address strategy = makeAddr("strategy");
    uint256 debtRatio = 9_000;
    address strategy2 = makeAddr("strategy2");
    uint256 debtRatio2 = 1_000;
    uint256 assetUnit;

    function setUp() public {
        pool = new VesperPool();
        asset = deployMockERC20("Test Token", "TST", 6);
        assetUnit = 10 ** asset.decimals();
        // clear storage to initialize pool
        vm.store(address(pool), Constants.INITIALIZABLE_STORAGE, bytes32(uint256(0)));
        pool.initialize("Vesper Pool V6", "VesperPoolV6", address(asset));
    }

    /// @dev Usage of this function makes sure that any ERC4626 overrides are still good.
    function _toShares(uint256 assets_) internal view returns (uint256) {
        return (assets_ * 1e18) / assetUnit;
    }

    /// @dev Usage of this function makes sure that any ERC4626 overrides are still good.
    function _toAssets(uint256 shares_) internal view returns (uint256) {
        return (shares_ * assetUnit) / 1e18;
    }
}
