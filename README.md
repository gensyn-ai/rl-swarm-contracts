# RL Swarm Contracts

This repository contains the smart contracts for the RL Swarm project, focusing on coordinating swarm behavior onchain.

## Deployed contract

### Gensyn testnet

If you want to interact with the contract, use the `SwarmCoordinatorProxy`.

- v0.5.1
   - math:
      - [SwarmCoordinatorProxy](https://gensyn-testnet.explorer.alchemy.com/address/0x69C6e1D608ec64885E7b185d39b04B491a71768C)
      - [SwarmCoordinator Implementation](https://gensyn-testnet.explorer.alchemy.com/address/0x227b6e52dd0C081ae27eC61E9514E2E0648fA5BC)
   - math-hard:
      - [SwarmCoordinatorProxy](https://gensyn-testnet.explorer.alchemy.com/address/0x6947c6E196a48B77eFa9331EC1E3e45f3Ee5Fd58)
      - [SwarmCoordinator Implementation](https://gensyn-testnet.explorer.alchemy.com/address/0xB191fAd6F942a2AB2d27f9571dCaDF8E6A317917)
- v0.5.0
   - math:
      - [SwarmCoordinatorProxy](https://gensyn-testnet.explorer.alchemy.com/address/0x69C6e1D608ec64885E7b185d39b04B491a71768C)
      - [SwarmCoordinator Implementation](https://gensyn-testnet.explorer.alchemy.com/address/0xAe8E8e52b595CA6546877caa7bFC6C4E7126597c)
   - math-hard:
      - [SwarmCoordinatorProxy](https://gensyn-testnet.explorer.alchemy.com/address/0x6947c6E196a48B77eFa9331EC1E3e45f3Ee5Fd58)
      - [SwarmCoordinator Implementation](https://gensyn-testnet.explorer.alchemy.com/address/0xeFaE44cBbafC81671551fbB9209A03D3930aA31B)
- v0.4.3
   - math:
      - [SwarmCoordinatorProxy](https://gensyn-testnet.explorer.alchemy.com/address/0x69C6e1D608ec64885E7b185d39b04B491a71768C)
      - [SwarmCoordinator Implementation](https://gensyn-testnet.explorer.alchemy.com/address/0xC713Defe71F7CA2b2c4a3973A25744818EE473A9)
   - math-hard:
      - [SwarmCoordinatorProxy](https://gensyn-testnet.explorer.alchemy.com/address/0x6947c6E196a48B77eFa9331EC1E3e45f3Ee5Fd58)
      - [SwarmCoordinator Implementation](https://gensyn-testnet.explorer.alchemy.com/address/0x1E6698DFC31Ead6AFBa8F9Ba485E017337661bD3)
- v0.4.2
   - math:
      - [SwarmCoordinatorProxy](https://gensyn-testnet.explorer.alchemy.com/address/0x69C6e1D608ec64885E7b185d39b04B491a71768C)
      - [SwarmCoordinator Implementation](https://gensyn-testnet.explorer.alchemy.com/address/0x0F78161498F09E0C3d7d846B066F217B026f88D1)
   - math-hard:
      - [SwarmCoordinatorProxy](https://gensyn-testnet.explorer.alchemy.com/address/0x6947c6E196a48B77eFa9331EC1E3e45f3Ee5Fd58)
      - [SwarmCoordinator Implementation](https://gensyn-testnet.explorer.alchemy.com/address/0x8eCad295510716C8435F09d692F7C622b24c1C89)
- v0.4.1
   - math:
      - [SwarmCoordinatorProxy](https://gensyn-testnet.explorer.alchemy.com/address/0x69C6e1D608ec64885E7b185d39b04B491a71768C)
      - [SwarmCoordinator Implementation](https://gensyn-testnet.explorer.alchemy.com/address/0x5D5c1409Ec33E058F9ae0C2C06293993Af5C12a4)
   - math-hard:
      - [SwarmCoordinatorProxy](https://gensyn-testnet.explorer.alchemy.com/address/0x6947c6E196a48B77eFa9331EC1E3e45f3Ee5Fd58)
      - [SwarmCoordinator Implementation](https://gensyn-testnet.explorer.alchemy.com/address/0x79088DEEF5b766ef3C2a33a20774aB513Ca44abc)
- v0.4.0
   - math:
      - [SwarmCoordinatorProxy](https://gensyn-testnet.explorer.alchemy.com/address/0x69C6e1D608ec64885E7b185d39b04B491a71768C)
      - [SwarmCoordinator Implementation](https://gensyn-testnet.explorer.alchemy.com/address/0x50EF4D38c9306ED74441C3E792Ca8f079d1BDfC8)
   - math-hard:
      - [SwarmCoordinatorProxy](https://gensyn-testnet.explorer.alchemy.com/address/0x6947c6E196a48B77eFa9331EC1E3e45f3Ee5Fd58)
      - [SwarmCoordinator Implementation](https://gensyn-testnet.explorer.alchemy.com/address/0xb95fF779f77AADfD0991fD0150E2A8E17DE0B19C)
- v0.3.1
   - [SwarmCoordinatorProxy](https://gensyn-testnet.explorer.alchemy.com/address/0x2fC68a233EF9E9509f034DD551FF90A79a0B8F82?tab=read_write_proxy)
   - [SwarmCoordinator Implementation](https://gensyn-testnet.explorer.alchemy.com/address/0xdf7FC8E7A58495407FfCe6Ae3b1146A5E089898b)
- v0.3.0
   - [SwarmCoordinatorProxy](https://gensyn-testnet.explorer.alchemy.com/address/0x2fC68a233EF9E9509f034DD551FF90A79a0B8F82?tab=read_write_proxy)
   - [SwarmCoordinator Implementation](https://gensyn-testnet.explorer.alchemy.com/address/0xdf7fc8e7a58495407ffce6ae3b1146a5e089898b)
- v0.2.0 - [0xcD1351B125b0ae4f023ADA5D09443087a7d99101](https://gensyn-testnet.explorer.alchemy.com/address/0xcD1351B125b0ae4f023ADA5D09443087a7d99101?tab=contract)
- v0.1.0 - [0x77bd0fcB5349F67C8fA1236E98e2b93334F4Db6E](https://gensyn-testnet.explorer.alchemy.com/address/0x77bd0fcB5349F67C8fA1236E98e2b93334F4Db6E?tab=contract)

## Overview

The main contract `SwarmCoordinator` manages a round-based system for coordinating swarm participants, tracking winners, reporting rewards, and managing bootnode infrastructure. The contract includes features for:

- Round management
- Peer registration and tracking
- Bootnode management
- Winner submission and reward tracking

## Roles

1. **Owner**
   - Can assign bootnode manager role
   - Can set round manager
   - Can grant and revoke any role
   - Initially deployed contract owner

2. **Round Manager**
   - Can advance rounds
   - Initially set to contract owner

3. **Bootnode Manager**
   - Can add and remove bootnodes
   - Can clear all bootnodes
   - Initially set to contract owner

## Interacting with the Contract

### For Participants

#### Register your peer

```solidity
function registerPeer(string calldata peerId) external
```

#### View current round

```solidity
function currentRound() external view returns (uint256)
```

#### Check total wins

```solidity
function getTotalWins(string calldata peerId) external view returns (uint256)
```

#### View the leaderboard

This should be done off-chain by listening to events since v0.5.0.

#### Check rewards earned by peers

```solidity
function getTotalRewards(string[] calldata peerIds) external view returns (int256[] memory)
```

#### Submit rewards

```solidity
function submitReward(uint256 roundNumber, int256 reward, string calldata peerId) external
```

#### Submit winners

```solidity
function submitWinners(uint256 roundNumber, string[] memory winners, string calldata peerId) external
```

### For Admins

#### Grant and Revoke Roles

Only callable by accounts with the `OWNER_ROLE`.

```solidity
function grantRole(bytes32 role, address account) external
function revokeRole(bytes32 role, address account) external
```

Available roles:
- `OWNER_ROLE`
- `ROUND_MANAGER_ROLE`
- `BOOTNODE_MANAGER_ROLE`

Role management events:
- `role`: The role identifier (e.g., `OWNER_ROLE`, `ROUND_MANAGER_ROLE`, `BOOTNODE_MANAGER_ROLE`)
- `account`: The account to grant or revoke the role from

For example, to grant the ROUND_MANAGER_ROLE to an address:

```solidity
grantRole(ROUND_MANAGER_ROLE, 0x1234...5678)
```

#### Check Role Membership

```solidity
function hasRole(bytes32 role, address account) external view returns (bool)
```

#### Advance Rounds

Only callable by accounts with the `ROUND_MANAGER_ROLE`.

```solidity
function advanceRound() external returns (uint256)
```

#### Manage Bootnodes

Only callable by accounts with the `BOOTNODE_MANAGER_ROLE`.

```solidity
function addBootnodes(string[] calldata newBootnodes) external
function removeBootnode(uint256 index) external
function clearBootnodes() external
```

## Development

### Prerequisites

- [foundry](https://book.getfoundry.sh/getting-started/installation)
- [curl](https://curl.se/download.html)

### Testing

Run the test suite:

```bash
forge test
```

Run with verbosity for more details:

```bash
forge test -vvv
```

### Code Style

- Use [Conventional Commits](https://www.conventionalcommits.org/en/v1.0.0/)
- Use Solidity style guide
- Run formatter before committing:

```bash
forge fmt
```

- Or set up a git hook to format pre-commit:
  - Create a pre-commit hook file `.git/hooks/pre-commit` with this content:

```bash
#!/bin/bash

# Format staged files using forge fmt
git diff --cached |forge fmt

# Add the formatted changes back to the index
git add .

# Proceed with commit
exit 0
```

### Contributing

1. Fork the repository
2. Create a feature branch
3. Commit your changes
4. Push to the branch
5. Create a Pull Request

### Deploy locally with mock data

One can set up a local environment for testing.

Requirements:

- [foundry](https://book.getfoundry.sh/getting-started/installation)
- [curl](https://curl.se/download.html)

Foundry comes with a local Ethereum node called `anvil`. To set up your local environment:

1. Start the local Ethereum node:

```bash
anvil
```

2. Keep this terminal running and open a new terminal to deploy the mock data:

```bash
forge script script/DeployLocalMockData.s.sol --rpc-url=http://localhost:8545 --broadcast
```

This script will:

- Deploy the SwarmCoordinator contract
- Register mock peers
- Add bootnode entries
- Submit winners and rewards
- Display leaderboard

You can now interact with the contract at the address printed in the deployment output.

## Deploy

To deploy to a network (either testnet, mainnet, ..), you need to set up these environment variables in a file such as `.env`:

```env
ETH_RPC_URL=https://gensyn-testnet.g.alchemy.com/public
ETH_PRIVATE_KEY=0xPRIVATEKEY

# Array of proxy addresses to deploy to
PROXY_ADDRESSES=("0x69C6e1D608ec64885E7b185d39b04B491a71768C" "0x6947c6E196a48B77eFa9331EC1E3e45f3Ee5Fd58")
```

### Deploy and verify contracts

The repository includes a script that handles both deployment and verification of contracts. You can use it in different ways:

```bash
# Deploy and verify all contracts
./scripts/deploy-and-verify.sh

# Only deploy all contracts
./scripts/deploy-and-verify.sh --deploy-only

# Only verify all contracts
./scripts/deploy-and-verify.sh --verify-only

# Show help
./scripts/deploy-and-verify.sh --help
```

The script will:

1. Deploy a new implementation for each proxy address
2. Extract the implementation address
3. Verify the implementation on Blockscout
4. Show clear progress for each operation

## FAQ

### How did you generate the ascii sections in the source code?

I used https://www.asciiart.eu/text-to-ascii-art with:

- font DOS Rebel
- border simple

### How do I generate a code coverage report?

```bash
forge coverage --report lcov ; genhtml lcov.info -o report
```

Once that's done you can use either:

- [Live Preview](https://marketplace.visualstudio.com/items?itemName=ms-vscode.live-server)
- [Coverage Gutters](https://marketplace.visualstudio.com/items?itemName=ryanluker.vscode-coverage-gutters)
