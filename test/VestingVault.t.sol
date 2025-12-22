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

        token.transfer(address(vault), 100_000 ether);
    }

    function testCliffBlocksClaim() public {
        vault.createSchedule(
            beneficiary,
            uint64(block.timestamp),
            10,
            100,
            10_000 ether,
            true
        );

        vm.expectRevert();
        vault.claim(beneficiary, 0);
    }

    function testClaimAfterCliff() public {
        vault.createSchedule(
            beneficiary,
            uint64(block.timestamp),
            10,
            100,
            10_000 ether,
            true
        );

        vm.warp(block.timestamp + 20);

        uint256 beforeBal = token.balanceOf(beneficiary);
        vault.claim(beneficiary, 0);
        uint256 afterBal = token.balanceOf(beneficiary);

        assertGt(afterBal, beforeBal);
    }

    function testPauseBlocksClaims() public {
        vault.createSchedule(
            beneficiary,
            uint64(block.timestamp),
            10,
            100,
            10_000 ether,
            true
        );

        vault.pause();

        vm.expectRevert();
        vault.claim(beneficiary, 0);
    }

    function testFullVestingReleasesAll() public {
        vault.createSchedule(
            beneficiary,
            uint64(block.timestamp),
            10,
            100,
            10_000 ether,
            true
        );

        vm.warp(block.timestamp + 200);
        vault.claim(beneficiary, 0);

        assertGt(token.balanceOf(beneficiary), 9_000 ether);
    }

    function testRevokeBlocksClaim() public {
        vault.createSchedule(
            beneficiary,
            uint64(block.timestamp),
            10,
            100,
            10_000 ether,
            true
        );

        vault.revokeSchedule(beneficiary, 0);

        vm.expectRevert();
        vault.claim(beneficiary, 0);
    }

    function testFeeSentToTreasury() public {
        vault.createSchedule(
            beneficiary,
            uint64(block.timestamp),
            10,
            100,
            10_000 ether,
            true
        );

        vm.warp(block.timestamp + 200);

        uint256 beforeFee = token.balanceOf(treasury);
        vault.claim(beneficiary, 0);
        uint256 afterFee = token.balanceOf(treasury);

        assertGt(afterFee, beforeFee);
    }
}
