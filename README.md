# FundMe

A learning-focused Ethereum crowdfunding project built with **Solidity**, **Foundry**, and **Chainlink Data Feeds**.

Funders can send ETH when its calculated USD value meets a minimum threshold. The contract records contributions by wallet address and allows the owner to withdraw the collected ETH.

> **Project status:** Educational and experimental. The contracts have not been independently audited and are **not intended for production use or real funds**.

## Overview

This project demonstrates:

- Writing and testing a payable Solidity contract.
- Reading an on-chain ETH/USD price through Chainlink's `AggregatorV3Interface`.
- Separating price-conversion logic into a Solidity library.
- Selecting network-specific feed addresses with a deployment helper.
- Using a mock price feed for local development and deterministic tests.
- Building, testing, measuring gas, and deploying with Foundry.

The minimum funding requirement is currently `MINIMUMUSD = 5e18`, representing **$5 scaled to 18 decimals**.

## How it works

### Funding flow

1. A user calls `fund()` and attaches ETH.
2. `fund()` passes `msg.value` and the stored feed reference (`s_pricefeed`) to the `priceconverter` library.
3. The library calls `latestRoundData()` on the selected feed contract and converts its price answer to the project's 18-decimal USD scale.
4. If the calculated value is below `MINIMUMUSD`, the transaction reverts.
5. Otherwise, the sender is added to the funder array and their contribution is added to the mapping of total contributions.

### Price feed and mock

`AggregatorV3Interface` is an interface, not an oracle and not an API client. It describes functions that the target price-feed contract exposes. The address passed to `fundme` identifies the actual contract that will receive calls.

- **Sepolia/Mainnet:** the helper selects a configured Chainlink feed address. Chainlink's oracle system publishes feed updates on-chain; FundMe reads the stored data through the contract interface.
- **Local development/tests:** `MockV3Aggregator` is deployed from this project's source code. It implements the expected interface and returns the price provided to its constructor or subsequently set through its update functions. It does not contact Chainlink or fetch market prices.

### Deployment flow

1. `deployfundme.sol` creates a `helperconfig` instance.
2. `helperconfig` checks `block.chainid` and selects a configured address for supported networks. Its fallback branch deploys a mock feed.
3. The deployment script passes the selected feed address to `new fundme(ethusdpricefeed)`.
4. The `fundme` constructor stores that address as an `AggregatorV3Interface` reference in `s_pricefeed` for later calls.

**Important:** the current helper's fallback branch is used for every chain ID other than the explicitly configured Sepolia and Mainnet IDs. It is not an explicit check for Anvil only. Do not use this fallback design for unsupported public networks without adding explicit chain validation.

## Contract responsibilities

| File                              | Responsibility                                                                                      |
| --------------------------------- | --------------------------------------------------------------------------------------------------- |
| `src/fundme.sol`                  | Funding rules, funder tracking, ownership, and withdrawals.                                         |
| `src/price_converter.sol`         | Reads the feed's price and converts an ETH amount (in wei) into the project's 18-decimal USD scale. |
| `script/deployfundme.sol`         | Deployment entry point; obtains a feed address and deploys FundMe.                                  |
| `script/helperconfig.sol`         | Selects the feed for the current chain or deploys a mock for the fallback branch.                   |
| `test/fundmetest.sol`             | Foundry tests for the contract's behavior.                                                          |
| `test/MOCKS/mockV3Aggregator.sol` | Mock implementation of the Chainlink feed interface.                                                |
| `foundry.toml`                    | Foundry configuration, compiler settings, and Chainlink import remapping.                           |

File and directory names are case-sensitive on Linux and WSL. Make sure the mock's import path matches its exact path in your checkout (for example, `MOCKS` and `mocks` are different names).

## Technology and prerequisites

You will need:

- Git
- [Foundry](https://getfoundry.sh/) (`forge`, `cast`, and `anvil`)
- An RPC endpoint for the network you plan to use
- Sepolia test ETH for a Sepolia deployment

Check that Foundry is available:

```bash
forge --version
cast --version
anvil --version
```

## Fork and clone

A **GitHub fork** is your own copy of the source repository. It is different from a Foundry network fork, which simulates a chain using an RPC endpoint.

1. Open the repository on GitHub and select **Fork** if you want your own copy to work on.
2. Clone your fork. Replace the placeholders with your GitHub username and repository name:

   ```bash
   git clone --recurse-submodules https://github.com/<your-username>/<repository-name>.git
   cd <repository-name>
   ```

3. If the project's dependencies are Git submodules, initialize them:

   ```bash
   git submodule update --init --recursive
   ```

4. Create a branch for your changes:

   ```bash
   git switch -c feat/your-change
   ```

If you only want to use the project, cloning the original repository is sufficient; creating a fork is optional.

## Compiler and reproducible builds

Use the **exact Solidity compiler version that you have built and tested the project with**, rather than silently switching to a newer compiler during deployment. Pinning the compiler makes builds more reproducible and helps when verifying deployed bytecode on a block explorer.

This project previously used Solidity `0.8.24`. If that is still the version validated by your current checkout, pin it in `foundry.toml` under `[profile.default]`:

```toml
[profile.default]
src = "src"
out = "out"
libs = ["lib"]
solc_version = "0.8.24"
evm_version = "cancun"
remappings = ["@chainlink/contracts/=lib/chainlink-brownie-contracts/contracts/"]
```

Keep the compiler and EVM versions that your current code and dependencies actually pass tests with. If you intentionally move to another version, rebuild and rerun the test suite before using that build for deployment. A Solidity `pragma` specifies which compiler versions are permitted; it does not itself pin the compiler that Foundry selects.

**Do not confuse compiler selection with `--legacy`:** Foundry's `--legacy` option changes the transaction type used for sending transactions. It is a troubleshooting option for RPC networks that do not support EIP-1559 transactions; it does **not** select or downgrade Solidity.

## Install dependencies and build

From the project root, first try:

```bash
forge build
```

If dependencies are missing and they are not already included as submodules, install them:

```bash
forge install foundry-rs/forge-std --no-commit
forge install smartcontractkit/chainlink-brownie-contracts --no-commit
```

The Chainlink remapping in `foundry.toml` allows imports such as:

```solidity
import {AggregatorV3Interface} from
    "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";
```

to resolve from the installed `chainlink-brownie-contracts` package.

Then compile:

```bash
forge build
```

## Tests and gas snapshots

Run the complete test suite:

```bash
forge test
```

Show detailed execution traces when debugging:

```bash
forge test -vvv
```

Run one test by its exact, case-sensitive function name:

```bash
forge test --match-test testfundfailswithoutenougheth
```

List the test functions Forge discovers:

```bash
forge test --list
```

Create or update gas snapshots with the separate `forge snapshot` command:

```bash
forge snapshot
forge snapshot --match-test testfundfailswithoutenougheth
```

Do not use `forge test snapshot ...`; `snapshot` is a separate Forge command.

Unit tests should generally deploy their mock feed and FundMe contract directly in the test environment. Avoid calling a broadcast deployment script from `setUp()` unless the test specifically needs to test script behavior.

## Local development with Anvil

Anvil is the local blockchain node. `MockV3Aggregator` is a contract that you deploy **onto** that node; it does not create the blockchain.

Start Anvil in one terminal:

```bash
anvil
```

Anvil prints a local RPC URL (commonly `http://127.0.0.1:8545`) and development accounts/private keys. These keys are for the local Anvil chain only. Never fund them with real assets or reuse them on a public network.

In another terminal, from the project root, deploy to the local chain:

```bash
forge script script/deployfundme.sol:deployfundme \
  --rpc-url http://127.0.0.1:8545 \
  --private-key <ANVIL_PRIVATE_KEY> \
  --broadcast -vvvv
```

Replace `<ANVIL_PRIVATE_KEY>` with a key printed by your running Anvil process. This assumes the helper's fallback branch is intended to deploy the mock on the chain ID returned by Anvil.

## Deploying to Sepolia safely

**Never use Mainnet as a place to debug deployment scripts.** Use unit tests and Anvil while developing, simulate the deployment against the intended RPC, and only then consider broadcasting to a testnet. A Mainnet deployment uses real ETH for gas, and a successful local test does not make a deployment safe for real funds.

### 1. Set the Sepolia RPC URL

Use an RPC endpoint from a provider you trust:

```bash
export SEPOLIA_RPC_URL="https://your-sepolia-rpc-endpoint"
```

Check the chain ID before proceeding:

```bash
cast chain-id --rpc-url "$SEPOLIA_RPC_URL"
```

For Sepolia, the expected chain ID is `11155111`. If the result differs, stop and check the endpoint before deploying.

Ensure that the deployer has enough **Sepolia test ETH** to cover the deployment transaction's gas. Do not use a wallet containing valuable Mainnet assets for experiments.

### 2. Keep the deployer key out of source control

Prefer a Foundry encrypted keystore rather than writing a private key into a source file or README. To import a dedicated test wallet, run:

```bash
cast wallet import fundme-sepolia-deployer --interactive
```

Follow the prompts. Keep the keystore password safe. Never commit private keys, seed phrases, `.env` files, or RPC credentials; make sure secret files are excluded by `.gitignore`.

### 3. Dry-run the deployment first

**Always run the script without `--broadcast` first.** This lets Foundry simulate the script and show traces, estimated gas, and the transactions it intends to send, without publishing those transactions to the network.

```bash
forge script script/deployfundme.sol:deployfundme \
  --rpc-url "$SEPOLIA_RPC_URL" \
  --account fundme-sepolia-deployer \
  --sender <DEPLOYER_PUBLIC_ADDRESS> \
  -vvvv
```

Replace `<DEPLOYER_PUBLIC_ADDRESS>` with the public address for the imported account. Review the entire output. Confirm the RPC's chain ID, selected feed address, sender, constructor arguments, and any warnings or reverts. A dry-run is a valuable safety check, but it cannot guarantee that a later transaction will be accepted or included by the network.

### 4. Broadcast only after reviewing the dry-run

When you are satisfied with the simulation and are intentionally ready to deploy to **Sepolia**, rerun the same script and add `--broadcast`:

```bash
forge script script/deployfundme.sol:deployfundme \
  --rpc-url "$SEPOLIA_RPC_URL" \
  --account fundme-sepolia-deployer \
  --sender <DEPLOYER_PUBLIC_ADDRESS> \
  --broadcast -vvvv
```

This publishes the deployment transactions and uses Sepolia test ETH for gas. Do not add `--broadcast` during the initial dry-run.

## Why a script can work but deployment can still fail

Successful compilation, passing unit tests, and a successful script dry-run are different checks. A real broadcast can still fail for reasons including:

- **Wrong RPC or chain:** the endpoint points to a different network, is unavailable, or returns a different chain ID than expected.
- **Insufficient gas funds:** the deployer has no native ETH on the target chain, or not enough to pay the actual transaction fee.
- **Transaction fee incompatibility:** the RPC/network rejects EIP-1559 transactions with an error such as `EIP-1559 not activated`. Only in that case, check that the network really requires legacy transactions and retry with `--legacy` if appropriate. This is not a compiler fix.
- **Account, nonce, or signing issues:** a wrong account/key, an incorrect sender, a pending transaction, or a nonce conflict can prevent the transaction from being accepted.
- **RPC/provider problems:** rate limits, timeouts, stale responses, endpoint outages, or broadcast failures can interrupt deployment.
- **Runtime or configuration errors:** the script can encounter a revert, wrong chain configuration, incorrect constructor parameters, or an unsuitable feed address when it executes against the target network.
- **A bad feed address can go unnoticed at deployment:** converting an address to `AggregatorV3Interface` does not prove that a working feed exists there. An incorrect address might allow FundMe to deploy but cause later feed calls to fail.
- **Verification failure is a separate issue:** deployment may succeed even if block-explorer verification fails. Verification generally requires the matching source code, exact compiler version, optimizer settings, EVM settings, and constructor arguments.

If deployment fails, read the first meaningful error in the terminal output rather than immediately changing compiler versions or adding flags. Confirm the chain ID and account balance, rerun tests, inspect the dry-run trace, and consult the relevant Foundry/RPC error message. Use `--legacy` only when the RPC's transaction-type compatibility is the actual issue.

## Network configuration

The helper selects configuration using `block.chainid`:

|           Chain ID | Configuration                                                        |
| -----------------: | -------------------------------------------------------------------- |
|         `11155111` | The Sepolia ETH/USD feed address in `getsepoliaethconfig()`          |
|                `1` | The Ethereum Mainnet ETH/USD feed address in `getmainnetethconfig()` |
| Any other chain ID | The mock-feed fallback in `getanvilethconfig()`                      |

Verify feed addresses against [Chainlink's official feed directory](https://data.chain.link/) before deploying. A feed address is specific to a chain; an address that is valid on one network is not guaranteed to represent the same contract on another.

The mock's price is whatever is passed to its constructor or set through its update functions. For example, `new MockV3Aggregator(8, 2000e8)` represents `$2,000` with 8 decimals, while `new MockV3Aggregator(8, 20e8)` represents `$20`. Keep the helper and test prices consistent with the behavior you intend to test.

## Implementation details and security limitations

- **ETH units:** `msg.value` is denominated in wei; `1 ETH = 1e18 wei`.
- **USD scaling:** `MINIMUMUSD = 5e18` represents $5 scaled to 18 decimals. The conversion result must use the same scale.
- **Feed decimals:** the current converter multiplies the feed answer by `1e10`, which assumes the selected feed reports 8 decimals. Check that assumption for each configured feed.
- **Oracle validation:** the current converter should be hardened to reject non-positive answers and stale data, using the feed's `updatedAt` and a suitable freshness policy. The current implementation should not be treated as production-ready.
- **Funder tracking:** the array records each successful funding call, so the same wallet can appear more than once. The mapping accumulates each address's total contribution.
- **Ownership:** `i_owner` is set to `msg.sender` in the constructor, which is the deployment sender in the intended script workflow.
- **Withdrawal logic:** review checks-effects-interactions and reentrancy assumptions around the low-level ETH `call` before using real funds.
- **Direct transfers:** `receive()` and `fallback()` invoke `fund()`, so they also run the minimum-value check.
- **Configuration:** the current fallback treats every unlisted chain ID as a mock/local configuration. Explicitly reject unsupported networks before any production deployment.

This README documents an educational project and a development workflow. It is not a security audit or a guarantee that the code is safe for real funds.

## License

The Solidity files shown for this project use `SPDX-License-Identifier: MIT`. If you intend to publish or redistribute the repository under the MIT license, include a repository-level `LICENSE` file containing the MIT license text.

## References

- [Foundry documentation](https://getfoundry.sh/)
- [Foundry Book](https://book.getfoundry.sh/)
- [Forge deployment guide](https://getfoundry.sh/forge/deploying)
- [Solidity compiler configuration in Foundry](https://getfoundry.sh/reference/config/solidity-compiler)
- [Solidity version pragmas](https://docs.soliditylang.org/en/latest/layout-of-source-files.html#version-pragma)
- [Chainlink Data Feeds documentation](https://docs.chain.link/data-feeds)
- [Chainlink Data Feeds API reference](https://docs.chain.link/data-feeds/api-reference)
- [Chainlink feed directory](https://data.chain.link/)

---

Built while learning Solidity, smart-contract testing, deployment scripts, and Chainlink price feeds with Foundry.
