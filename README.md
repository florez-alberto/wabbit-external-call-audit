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
   ```bash
   npm install
