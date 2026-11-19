# AgentStreak

Daily check-in for Binance Agent ID holders — built for the [Agent ID Hackathon](https://www.binance.com/en/support/announcement/detail/95f5dbe0ea674a48a739b59e046648bf) (Binance Wallet × BNB Chain, 60,000 USDC).

**Website:** https://risa19.github.io/agentstreak/

## What it is

AgentStreak is a tiny on-chain loyalty loop for Agent ID holders (SPACE ID
Agent ID, the `.ai` name of an Agentic Wallet):

- Hold an Agent ID → check in once per UTC day.
- Consecutive days build a streak; missing a day resets it.
- Your streak, total check-ins, and the global totals are public on-chain.

Streaks and check-in counts are on-chain reputation only. **They have no cash
value, no token is issued, and no reward of any kind is promised.**

## Agent ID usage

The contract reads `balanceOf(address)` on the SPACE ID Agent ID contract
(`0x60B9262456dE011F7d15a54CdD8c48bAaa8B022F`, BNB Chain) and requires it to be
greater than zero before a check-in is accepted. Agent ID is the product's
access control: without one, no interaction is possible.

## Contract

- Network: BNB Smart Chain (chain ID 56)
- Contract: [`0x2993602cb38eC33ff90AFcDdB3110Dd49A5C171B`](https://bscscan.com/address/0x2993602cb38eC33ff90AFcDdB3110Dd49A5C171B) (deployed 2026-11-19, block 134465464)
- Source: [`src/AgentStreak.sol`](src/AgentStreak.sol), Sourcify-verified (exact match, creation + runtime)
- The contract holds no funds and has **no owner functions**: nothing to
  mint, pause, withdraw, or change after deployment. The deployer key has no
  ongoing power over the contract.

## Safety

- No QR-code login, no session storage, no signing on behalf of users.
- Every check-in is a transaction the user signs and confirms themselves.
- No approvals are requested. No seed phrases, private keys, or pairing codes
  are ever collected.
- No returns are promised anywhere in the product.
- The project does not use the Binance or BNB brand in its name, token (it
  has none), or domain.

## Build & test

```sh
forge build
forge test   # 7 tests, incl. streak growth, reset after a missed day, and the Agent ID gate
```

## Deploy

```sh
forge script script/Deploy.s.sol --rpc-url <BSC_RPC> --broadcast
```

## License

MIT — see [LICENSE](LICENSE).
