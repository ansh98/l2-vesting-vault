# l2-vesting-vault
L2-grade vesting vault with revocation, treasury fee on claims, and Foundry test coverage (Arbitrum/Base).


## Testing

This project uses Foundry for unit testing.

Covered scenarios:
- Cliff enforcement
- Linear vesting
- Pause protection
- Revocation logic
- Treasury fee accounting

Run tests:
```bash
forge test -vv
