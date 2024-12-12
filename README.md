# Proof: No External Calls in Phase 4 for WABBIT Contract

## Overview
This project demonstrates the analysis and testing of the WABBIT contract's `_update` function, specifically to verify that no external calls are made during Phase 4. It provides a detailed explanation of the contract phases and offers definitive proof through testing.

## Key Findings
1. The `_update` function's behavior is tied to trading phases:
   - **Phase 0**: Trading not active.
   - **Phase 1**: Whitelist restricted by internal mapping.
   - **Phase 2**: Whitelist may use external contract calls.
   - **Phase 3**: Only internal checks; no external calls.
   - **Phase 4**: No restrictions; open trading.
2. During **Phase 4**, all restrictions and whitelist checks are bypassed, ensuring no external calls are made.

## Hardhat Testing Setup
This project includes a test suite for the `_update` function in `test/externalTesting.js`. The tests leverage the Hardhat framework to validate the absence of external calls during Phase 4.

### Running Tests
1. Install dependencies:
   ```shell
   npm install
   ```

2. Run tests:
   ```shell
   npx hardhat test
   ```

3. To simulate gas reporting:
   ```shell
   REPORT_GAS=true npx hardhat test
   ```

### Additional Hardhat Commands
- Start a local Hardhat node:
  ```shell
  npx hardhat node
  ```
- Deploy contracts (example):
  ```shell
  npx hardhat deploy
  ```

## Contract Analysis

The critical section of the `_update` function is as follows:

```solidity
function _update(
    address from,
    address to,
    uint256 amount
) internal virtual override {
    super._update(from, to, amount);

    if (liquidityPool == address(0)) {
      require(from == owner() || to == owner(), "No LP set");
      return;
    }

    if (to != liquidityPool) {
      if (tradingPhase() == 0) {
        require(false, "Trading not active");

      } else if (tradingPhase() == 1) {
        require(isWhitelistedPhase1(to), "Not whitelisted");
        whitelist_buys[to][1] += amount;
        require(whitelist_buys[to][1] <= maxBuyWL(), "Buy Phase 1 amount exceeded");

      } else if (tradingPhase() == 2) {
        require(isWhitelistedPhase2(to), "Not whitelisted"); // External call here
        whitelist_buys[to][2] += amount;
        require(whitelist_buys[to][2] <= maxBuyWL(), "Buy Phase 2 amount exceeded");

      } else if (tradingPhase() == 3) {
        whitelist_buys[to][3] += amount;
        require(whitelist_buys[to][3] <= maxBuyWL() * 5, "Buy Phase 3 amount exceeded");
      }
    }
}
```

### Key Findings
1. **Trading Phases and External Calls**:
   - The only scenario where an external call is possible is during **Phase 2**, where `isWhitelistedPhase2(to)` can call an external contract (`IWhitelist(wlChecker).isWhitelisted(account)`).
   - In **Phase 4**, the restrictions imposed by earlier phases are bypassed entirely.

2. **Phase 4 Logic**:
   - The `tradingPhase()` function determines the current trading phase. Phase 4 is defined as:
     ```solidity
     function tradingPhase() public view returns (uint256) {
       if (!tradingActive()) {
         return 0;
       } else if (tradingRestricted()) {
         // ... Phases 1, 2, and 3
       } else {
         return 4; // Phase 4
       }
     }
     ```
   - During Phase 4, no checks are made that would lead to external calls. The `_update` function simply executes `super._update(from, to, amount)` without invoking any additional logic that could interact with external contracts.

3. **Definitive Proof**:
   - The absence of whitelist or trading restrictions in Phase 4 confirms that no external calls are triggered. All external contract interactions cease after Phase 3.

## Conclusion
The `_update` function does **not** make any external calls during **Phase 4**, as:
- All restrictions and external contract checks are tied to earlier phases (1, 2, and 3).
- Phase 4 explicitly lifts all such restrictions, enabling unrestricted trading.

You can review the full code [here](https://snowscan.xyz/address/0x77776aB9495729E0939E9bADAf7E7c3312777777#code) for further verification.

## Related Links
- Contract Explorer: [WABBIT Contract](https://snowscan.xyz/address/0x77776aB9495729E0939E9bADAf7E7c3312777777#code)
- Twitter: [@WABBIT_AVAX](https://twitter.com/WABBIT_AVAX)
- Website: [WABBIT](https://wabbit.meme)

This is an independent review of the contract because of some risen awareness of external contract calls made by GoPlus. After careful review and testing, it is evident that no external calls are made in Phase 4. The claims made in the [GoPlus report](https://gopluslabs.io/token-security/43114/0x77776aB9495729E0939E9bADAf7E7c3312777777) are inaccurate and should be updated to reflect this analysis.
