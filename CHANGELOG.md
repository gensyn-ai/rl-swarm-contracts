# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

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

### Removed

### Fixed

### Security

<!-- Links -->
[keep a changelog]: https://keepachangelog.com/en/1.0.0/
[semantic versioning]: https://semver.org/spec/v2.0.0.html

<!-- Versions -->
[unreleased]: https://github.com/gensyn-ai/rl-swarm-contracts/compare/v0.3...HEAD
[0.2.0]: https://github.com/gensyn-ai/rl-swarm-contracts/compare/v0.2.0...v0.1.0
[0.1.0]: https://github.com/gensyn-ai/rl-swarm-contracts/releases/tag/v0.1.0
