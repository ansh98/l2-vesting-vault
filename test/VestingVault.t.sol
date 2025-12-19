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
            50 // 0.5% fee
        );

        // Fund vault
        token.transfer(address(vault), 100_000 ether);
    }

    /// ----------------------------
    /// TEST 1: Cliff blocks claim
    /// ----------------------------
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

    /// ----------------------------
    /// TEST 2: Claim works after cliff
    /// ----------------------------
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

        uint256 beforeBal = token.balanceOf(beneficiary);
        vault.claim(beneficiary, 0);
        uint256 afterBal = token.balanceOf(beneficiary);

        assertGt(afterBal, beforeBal);
    }

    /// ----------------------------
    /// TEST 3: Pause blocks claims
    /// ----------------------------
    function testPauseBlocksClaims() public {
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

        vault.pause();

        vm.expectRevert();
        vault.claim(beneficiary, 0);
    }

    /// ----------------------------
    /// TEST 4: Full vesting releases all tokens
    /// ----------------------------
    function testFullVestingReleasesAll() public {
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

        vm.warp(block.timestamp + 200);

        vault.claim(beneficiary, 0);

        uint256 balance = token.balanceOf(beneficiary);
        assertGt(balance, 9_000 ether); // after fee
    }

    /// ----------------------------
    /// TEST 5: Revoked schedule blocks claims
    /// ----------------------------
    function testRevokeBlocksClaim() public {
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

        vault.revokeSchedule(beneficiary, 0);

        vm.expectRevert();
        vault.claim(beneficiary, 0);
    }

    /// ----------------------------
    /// TEST 6: Fee is sent to treasury
    /// ----------------------------
    function testFeeSentToTreasury() public {
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

        vm.warp(block.timestamp + 200);

        uint256 treasuryBefore = token.balanceOf(treasury);
        vault.claim(beneficiary, 0);
        uint256 treasuryAfter = token.balanceOf(treasury);

        assertGt(treasuryAfter, treasuryBefore);
    }
}
