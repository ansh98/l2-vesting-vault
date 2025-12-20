# VestingVault: Secure Token Vesting Smart Contract

VestingVault is a secure, audit-style ERC20 token vesting smart contract built using Solidity and Foundry.  
It supports cliff-based and linear vesting schedules, pause and revoke mechanisms, and protocol-level fee handling.

This project demonstrates production-grade smart contract design, security best practices, and comprehensive test coverage.

---

## Key Features

- Cliff-based vesting
- Linear vesting over time
- Multiple vesting schedules per beneficiary
- Pause and resume functionality
- Revocable vesting schedules
- Protocol fee sent to treasury
- Reentrancy protection
- Extensive Foundry-based test suite

---

## Architecture Overview

src/
├── VestingVault.sol # vesting logic
└── mocks/
├── FeeToken.sol # token with fee logic
└── ReentrantAttacker.sol # Reentrancy test helper
test/
└── VestingVault.t.sol 


---

## Installation & Setup

```bash
git clone https://github.com/ansh98/l2-vesting-vault.git
cd l2-vesting-vault
forge install
forge test -vv
