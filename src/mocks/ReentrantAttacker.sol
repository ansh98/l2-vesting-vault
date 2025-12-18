// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @notice Minimal interface for VestingVault
 */
interface IVestingVault {
    function claim(address beneficiary, uint256 id) external;
}

/**
 * @title ReentrantAttacker
 * @notice Attempts to re-enter VestingVault.claim()
 * Used to test ReentrancyGuard protection
 */
contract ReentrantAttacker {
    IVestingVault public vault;
    address public beneficiary;
    uint256 public scheduleId;
    bool internal attacked;

    constructor(
        address _vault,
        address _beneficiary,
        uint256 _scheduleId
    ) {
        vault = IVestingVault(_vault);
        beneficiary = _beneficiary;
        scheduleId = _scheduleId;
    }

    function attack() external {
        vault.claim(beneficiary, scheduleId);
    }

    fallback() external {
        if (!attacked) {
            attacked = true;
            vault.claim(beneficiary, scheduleId);
        }
    }
}

