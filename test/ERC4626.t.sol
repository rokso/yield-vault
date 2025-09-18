// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.30;

import {ERC4626Test} from "erc4626-tests/ERC4626.test.sol";

import {ERC20Mock} from "@openzeppelin/contracts/mocks/token/ERC20Mock.sol";
import {VesperPool} from "src/VesperPool.sol";
import {Constants} from "test/helpers/Constants.sol";

contract ERC4626StdTest is ERC4626Test {
    function setUp() public override {
        _underlying_ = address(new ERC20Mock());

        VesperPool _pool = new VesperPool();
        // clear storage to initialize pool
        vm.store(address(_pool), Constants.INITIALIZABLE_STORAGE, bytes32(uint256(0)));
        _pool.initialize("Vesper Pool V6", "VesperPoolV6", address(_underlying_));

        _vault_ = address(_pool);
        _delta_ = 0;
        _vaultMayBeEmpty = true;
        _unlimitedAmount = true;
    }
}
