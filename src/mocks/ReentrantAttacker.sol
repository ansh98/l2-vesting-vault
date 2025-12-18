// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IVestingVault {
    function claim(address beneficiary, uint256 id) external;
}

contract ReentrantAttacker {
    IVestingVault public vault;
    address public beneficiary;
    uint256 public id;
    bool private entered;

    constructor(address _vault, address _beneficiary, uint256 _id) {
        vault = IVestingVault(_vault);
        beneficiary = _beneficiary;
        id = _id;
    }

    function attack() external {
        vault.claim(beneficiary, id);
    }

    fallback() external {
        if (!entered) {
            entered = true;
            vault.claim(beneficiary, id);
        }
    }
}
