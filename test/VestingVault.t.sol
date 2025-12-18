// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/VestingVault.sol";
import "../src/mocks/FeeToken.sol";

contract VestingVaultTest is Test {
    VestingVault vault;
    FeeToken token;

    address beneficiary = address(0xBEEF);
    address treasury = address(0xCAFE);

    function setUp() public {
        token = new FeeToken();
        vault = new VestingVault(
            IERC20(address(token)),
            treasury,
            50 // 0.5%
        );

        token.transfer(address(vault), 100_000 ether);
    }

    function testCliffBlocksClaim() public {
        uint64 start = uint64(block.timestamp);
        uint64 cliff = 10;
        uint64 duration = 100;

        vault.createSchedule(
            beneficiary,
            start,
            cliff,
            duration,
            10_000 ether,
            true
        );

        vm.expectRevert();
        vault.claim(beneficiary, 0);
    }

    function testClaimAfterCliff() public {
        uint64 start = uint64(block.timestamp);
        uint64 cliff = 10;
        uint64 duration = 100;

        vault.createSchedule(
            beneficiary,
            start,
            cliff,
            duration,
            10_000 ether,
            true
        );

        vm.warp(block.timestamp + 20);
        vault.claim(beneficiary, 0);
    }
}
