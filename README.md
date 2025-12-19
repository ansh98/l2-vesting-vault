VestingVault: Secure Token Vesting Smart Contract

VestingVault is a secure, audited-style ERC20 token vesting smart contract built using Solidity and Foundry.
It supports cliff-based and linear vesting schedules, pause and revoke mechanisms, and protocol-level fee handling.
This project demonstrates production-grade contract design, security best practices, and comprehensive test coverage.
Key Features:
⏳ Cliff-based vesting
📈 Linear vesting over time
🧾 Multiple vesting schedules per beneficiary
⏸ Pause & resume functionality
❌ Revocable schedules
💰 Protocol fee sent to treasury
🔒 Reentrancy protection
🧪 Extensive Foundry test suite

Architecture Overview:

src/
 ├── VestingVault.sol        # Core vesting logic
 └── mocks/
     ├── FeeToken.sol        # ERC20 token with fee logic
     └── ReentrantAttacker.sol

test/
 └── VestingVault.t.sol      # Full test suite

 
Installation & Setup:
git clone <repo-url>
cd l2-vesting-vault
forge install
forge test -vv
