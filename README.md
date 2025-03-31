# RL Swarm Contracts

This repository contains the smart contracts for the RL Swarm project, focusing on coordinating swarm behavior onchain.

## Deployed contract

### Gensyn testnet

- v0.3 - [0x2fC68a233EF9E9509f034DD551FF90A79a0B8F82](https://gensyn-testnet.explorer.alchemy.com/address/0x2fC68a233EF9E9509f034DD551FF90A79a0B8F82?tab=contract)
- v0.2 - [0xcD1351B125b0ae4f023ADA5D09443087a7d99101](https://gensyn-testnet.explorer.alchemy.com/address/0xcD1351B125b0ae4f023ADA5D09443087a7d99101?tab=contract)
- v0.1 - [0x77bd0fcB5349F67C8fA1236E98e2b93334F4Db6E](https://gensyn-testnet.explorer.alchemy.com/address/0x77bd0fcB5349F67C8fA1236E98e2b93334F4Db6E?tab=contract)

## Overview

The main contract `SwarmCoordinator` manages a round-based system for coordinating swarm participants, tracking winners, and managing bootnode infrastructure. The contract includes features for:

- Round and stage management
- Peer registration and tracking
- Bootnode management
- Winner submission and reward tracking
- Unique voter tracking across rounds
- Unique voted peer tracking across rounds

## Contract Architecture

### Key Components

1. **Stage and Round Management**
   - Rounds progress through multiple stages
   - Stages are advanced by a designated stage updater
   - No time-based duration checks for stage progression

2. **Peer Management**
   - Users can register their peer IDs by linking them to their EOA
   - EOA addresses are linked to peer IDs (permission-less for now)

3. **Bootnode Infrastructure**
   - Managed by a designated bootnode manager
   - Supports adding, removing, and listing bootnodes
   - Helps maintain network connectivity

4. **Winner Management**
   - Designated winner manager can submit winners for each round
   - Tracks accrued rewards per participant
   - Prevents duplicate winner submissions

5. **Voter Tracking**
   - Tracks unique voters across all rounds
   - Counts each address only once, regardless of how many times they vote
   - Provides total count of unique participants

6. **Voted Peer Tracking**
   - Tracks unique peers that have received votes
   - Counts each peer only once, regardless of how many times they are voted for
   - Provides total count of unique peers that have been voted on

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
function registerPeer(bytes calldata peerId) external
```

#### View current round and stage

```solidity
function currentRound() external view returns (uint256)
function currentStage() external view returns (uint256)
```

#### Check total wins

```solidity
function getTotalWins(address account) external view returns (uint256)
```

#### View the leaderboard

```solidity
function winnerLeaderboard(uint256 start, uint256 end) external view returns (string[] memory peerIds, uint256[] memory wins)
function voterLeaderboard(uint256 start, uint256 end) external view returns (address[] memory voters, uint256[] memory voteCounts)
```

Returns slices of the leaderboards:

- `winnerLeaderboard`: Returns peer IDs and their win counts, sorted by number of wins (descending)
- `voterLeaderboard`: Returns voter addresses and their vote counts, sorted by number of votes (descending)

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
function getPeerId(address[] calldata eoas) external view returns (string[] memory)
function getEoa(string[] calldata peerIds) external view returns (address[] memory)
```

Get peer IDs for multiple EOAs or EOAs for multiple peer IDs.

#### Get voting information

```solidity
function getVoterVoteCount(address voter) external view returns (uint256)
function getVoterVotes(uint256 roundNumber, address voter) external view returns (string[] memory)
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
function setStageCount(uint256 stageCount_)
function grantRole(bytes32 role, address account)
function revokeRole(bytes32 role, address account)
```

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
- Set up test rounds and winners
- Display contract address and leaderboard

You can now interact with the contract at the address printed in the deployment output.

### Deploy

To deploy to a network (either testnet, mainnet, ..), you need to set up these environment variables in a file such as `.env`:

```env
ETH_RPC_URL=https://gensyn-testnet.g.alchemy.com/public
ETH_PRIVATE_KEY=0xPRIVATEKEY
```

Load the environment file:

```bash
source .env
```

Alternatively, an anvil (local deployment) specific environment file is already in the repo, load it with:

```bash
source .env.anvil
```

After loading the environment file, deploy it:

```bash
forge script script/DeploySwarmCoordinator.s.sol --slow --rpc-url=$ETH_RPC_URL --private-key=$ETH_PRIVATE_KEY --broadcast
```

Verify the contract on blockscout:

```bash
forge verify-contract \
  --rpc-url https://gensyn-testnet.g.alchemy.com/public \
  --verifier blockscout \
  --verifier-url 'https://gensyn-testnet.explorer.alchemy.com/api/' \
  [contract-address] \
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
