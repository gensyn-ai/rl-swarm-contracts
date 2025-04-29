# RL Swarm Contracts

This repository contains the smart contracts for the RL Swarm project, focusing on coordinating swarm behavior onchain.

## Deployed contract

### Gensyn testnet

If you want to interact with the contract, use the `SwarmCoordinatorProxy`.

- v0.4.0
   - Small:
      - [SwarmCoordinatorProxy](https://gensyn-testnet.explorer.alchemy.com/address/0x69C6e1D608ec64885E7b185d39b04B491a71768C)
      - [SwarmCoordinator Implementation](https://gensyn-testnet.explorer.alchemy.com/address/0x50EF4D38c9306ED74441C3E792Ca8f079d1BDfC8)
   - Big:
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

- Round and stage management
- Peer registration and tracking
- Bootnode management
- Winner submission and reward tracking
- Unique voter tracking across rounds
- Unique voted peer tracking across rounds

## Roles

1. **Owner**
   - Can set stage count
   - Can assign bootnode manager role
   - Can set stage updater
   - Can grant and revoke any role
   - Initially deployed contract owner

2. **Stage Manager**
   - Can advance stages and rounds
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

#### View current round and stage

```solidity
function currentRound() external view returns (uint256)
function currentStage() external view returns (uint256)
```

#### Check total wins

```solidity
function getTotalWins(string calldata peerId) external view returns (uint256)
```

#### View the leaderboard

```solidity
function winnerLeaderboard(uint256 start, uint256 end) external view returns (string[] memory peerIds, uint256[] memory wins)
function voterLeaderboard(uint256 start, uint256 end) external view returns (string[] memory peerIds, uint256[] memory voteCounts)
```

Returns slices of the leaderboards:

- `winnerLeaderboard`: Returns peer IDs and their win counts, sorted by number of wins (descending)
- `voterLeaderboard`: Returns peer IDs and their vote counts, sorted by number of votes (descending)

Both leaderboards track up to 100 top entries. The `start` and `end` parameters define the range of positions to return (inclusive start, exclusive end).

#### Check unique voter count

```solidity
function uniqueVoters() external view returns (uint256)
```

Returns the total number of unique addresses that have participated in voting across all rounds. Each address is counted only once, regardless of how many times they have voted.

#### Check unique voted peer count

```solidity
function uniqueVotedPeers() external view returns (uint256)
```

Returns the total number of unique peer IDs that have received votes across all rounds. Each peer is counted only once, regardless of how many times they have been voted for.

#### Get peer and EOA mappings

```solidity
function getPeerId(address[] calldata eoas) external view returns (string[][] memory)
function getEoa(string[] calldata peerIds) external view returns (address[] memory)
```

Get peer IDs for multiple EOAs or EOAs for multiple peer IDs.

#### Get voting information

```solidity
function getVoterVoteCount(string calldata peerId) external view returns (uint256)
function getVoterVotes(uint256 roundNumber, string calldata peerId) external view returns (string[] memory)
function getPeerVoteCount(uint256 roundNumber, string calldata peerId) external view returns (uint256)
```

Get detailed voting information including:

- Number of times a voter has voted
- Votes cast by a specific voter in a round
- Number of votes received by a peer in a round

### For Administrators

#### Owner

Manages contract configuration and roles.

```solidity
function grantRole(bytes32 role, address account)
function revokeRole(bytes32 role, address account)
```

The deployer of the contract is automatically granted the roles:

- `OWNER_ROLE`
- `STAGE_MANAGER_ROLE`
- `BOOTNODE_MANAGER_ROLE`

To grant a role to a new account, the owner can call `grantRole` with:

- `role`: The role identifier (e.g., `OWNER_ROLE`, `STAGE_MANAGER_ROLE`, `BOOTNODE_MANAGER_ROLE`)
- `account`: The address to grant the role to

For example, to grant the STAGE_MANAGER_ROLE to an address:

```solidity
grantRole(STAGE_MANAGER_ROLE, 0x1234...5678)
```

Roles can be revoked using `revokeRole` with the same parameters.

#### Stage Manager

Advances stages and rounds.

```solidity
function updateStageAndRound() external returns (uint256, uint256)
```

#### Bootnode manager

Manages bootnode list.

```solidity
function addBootnodes(string[] calldata newBootnodes)
function removeBootnode(uint256 index)
function clearBootnodes()
function getBootnodesCount() external view returns (uint256)
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
```

Load the environment file:

```bash
source .env
```

After loading the environment file continue to deployment.

### Proxy

This contract uses an UUPSUpgradeable pattern. Thus, a proxy and the implementation need to be deployed and verified.

#### Deploy initial proxy

```bash
forge script script/DeploySwarmCoordinatorProxy.s.sol --slow --rpc-url=$ETH_RPC_URL --private-key=$ETH_PRIVATE_KEY --broadcast
```

This deploys a contract implementation, the proxy and initializes the proxy.

Verify the proxy on Blockscout:

```bash
forge verify-contract \
  --rpc-url https://gensyn-testnet.g.alchemy.com/public \
  --verifier blockscout \
  --verifier-url 'https://gensyn-testnet.explorer.alchemy.com/api/' \
  [ERC1967Proxy] \
  lib/openzeppelin-contracts/contracts/proxy/ERC1967/ERC1967Proxy.sol:ERC1967Proxy
```

Verify the implementation on Blockscout:

```bash
forge verify-contract \
  --rpc-url https://gensyn-testnet.g.alchemy.com/public \
  --verifier blockscout \
  --verifier-url 'https://gensyn-testnet.explorer.alchemy.com/api/' \
  [SwarmCoordinator-Implementation] \
  src/SwarmCoordinator.sol:SwarmCoordinator
```

#### Deploy new version

Once the proxy was deployed and we need to deploy a new contract version, we have to use the existing proxy address contract.

```bash
forge script script/DeploySwarmCoordinatorProxy.s.sol --slow \
   --rpc-url=$ETH_RPC_URL \
   --private-key=$ETH_PRIVATE_KEY \
   --sig "deployNewVersion()" \
   --broadcast
```

Make sure to verify the new implementation:

```bash
forge verify-contract \
  --rpc-url https://gensyn-testnet.g.alchemy.com/public \
  --verifier blockscout \
  --verifier-url 'https://gensyn-testnet.explorer.alchemy.com/api/' \
  [SwarmCoordinator-NewVersion] \
  src/SwarmCoordinator.sol:SwarmCoordinator
```

### Generic framework info

For more information about the development environment:

- [Foundry Book](https://book.getfoundry.sh/)

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
