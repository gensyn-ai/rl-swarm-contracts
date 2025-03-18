# RL Swarm Contracts

This repository contains the smart contracts for the RL Swarm project, focusing on coordinating swarm behavior onchain.

## Overview

The main contract `SwarmCoordinator` manages a round-based system for coordinating swarm participants, tracking winners, and managing bootnode infrastructure. The contract includes features for:

- Round and stage management
- Peer registration and tracking
- Bootnode management
- Winner submission and reward tracking

## Contract Architecture

### Key Components

1. **Stage and Round Management**
   - Rounds progress through multiple stages
   - Each stage has a configurable duration
   - Stages automatically advance when their duration is complete

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

## Roles

1. **Owner**
   - Can set stage durations and count
   - Can assign bootnode manager role
   - Can add and remove judges
   - Initially deployed contract owner

2. **Bootnode Manager**
   - Can add and remove bootnodes
   - Can clear all bootnodes
   - Initially set to contract owner

3. **Judges**
   - Can submit winners for completed rounds
   - Assigns rewards to winners
   - Multiple judges can be active simultaneously
   - Initially set to contract owner

## Interacting with the Contract

### For Participants

1. Register your peer:

```solidity
function registerPeer(bytes calldata peerId) external
```

2. Check your accrued rewards:

```solidity
function getAccruedRewards(address account) external view returns (uint256)
```

3. View current round and stage:

```solidity
function currentRound() external view returns (uint256)
function currentStage() external view returns (uint256)
```

### For Administrators

#### Owner

Manages stages and other managers.

```solidity
function setStageCount(uint256 stageCount_)
function setStageDuration(uint256 stage_, uint256 stageDuration_)
function setBootnodeManager(address newManager)
function addJudge(address newJudge)
function removeJudge(address judgeToRemove)
```

#### Bootnode manager

Manages bootnode list.

```solidity
function addBootnodes(string[] calldata newBootnodes)
function removeBootnode(uint256 index)
function clearBootnodes()
```

#### Judges

Submit winners. Can be defined as different smart contracts that manage consensus before posting a winner.

```solidity
function submitWinner(uint256 roundNumber, address[] calldata winners)
function getRoundWinners(uint256 roundNumber) external view returns (address[] memory)
function isJudge(address account) external view returns (bool)
function getJudgeCount() external view returns (uint256)
```

## Development

For more information about the development environment:
- [Foundry Book](https://book.getfoundry.sh/)
