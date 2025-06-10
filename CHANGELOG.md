# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.6.0]

### Changed

- Reduce stage count to 1

## [0.5.1]

### Added

- Add uniqueVoters back

## [0.5.0]

### Deprecated

- Deprecated on chain leaderboard management for off chain event management [PR#45](https://github.com/gensyn-ai/rl-swarm-contracts/pull/45)

### Removed

- Removed methods: getPeerVoteCount, voterLeaderboard, winnerLeaderboard, uniqueVotedPeers [PR#45](https://github.com/gensyn-ai/rl-swarm-contracts/pull/45)

## [0.4.3]

### Fixed

- `submitReward` takes into account current round when checking stage validity [PR#43](https://github.com/gensyn-ai/rl-swarm-contracts/pull/43)

## [0.4.2]

### Changed

- `submitReward` accepts integer rewards [PR#42](https://github.com/gensyn-ai/rl-swarm-contracts/pull/42)

## [0.4.1]

### Fixed

- `submitReward` checks provided stageNumber to be current or past [PR#41](https://github.com/gensyn-ai/rl-swarm-contracts/pull/41)

## [0.4.0]

### Added

- Peers can submit rewards [PR#31](https://github.com/gensyn-ai/rl-swarm-contracts/pull/31)
- Makefile

### Changed

- Relationship PeerID (many) to EOA (one) [PR#28](https://github.com/gensyn-ai/rl-swarm-contracts/pull/28)
- Hardcode 3 stages instead of having a configurable number

### Security

- Prevent double voting for the same peer in a round [PR#30](https://github.com/gensyn-ai/rl-swarm-contracts/pull/30)

## [0.3.1]

### Changed

- removed validation of submitted peer ids [PR#26](https://github.com/gensyn-ai/rl-swarm-contracts/pull/26)

## [0.3.0]

### Added

- Changelog to track changes
- `grantRole` and `revokeRole` to handle roles, callable only by owners
- `hasRole` to check if an account has a role
- `OWNER_ROLE`, `BOOTNODE_MANAGER_ROLE`, `STAGE_MANAGER_ROLE` as `byte32` replacing existing roles

### Changed

- SwarmCoordinator works as a UUPS proxy

### Deprecated

- `setBootnodeManager`
- `bootnodeManager`
- `setStageUpdater`
- `stageUpdater`

<!-- Links -->
[keep a changelog]: https://keepachangelog.com/en/1.0.0/
[semantic versioning]: https://semver.org/spec/v2.0.0.html

<!-- Versions -->
[unreleased]: https://github.com/gensyn-ai/rl-swarm-contracts/compare/v0.3...HEAD
[0.2.0]: https://github.com/gensyn-ai/rl-swarm-contracts/compare/v0.2.0...v0.1.0
[0.1.0]: https://github.com/gensyn-ai/rl-swarm-contracts/releases/tag/v0.1.0
