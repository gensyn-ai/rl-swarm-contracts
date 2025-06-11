// SPDX-License-Identifier: MIT
pragma solidity ^0.8;

import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

/**
 * @title SwarmCoordinator
 * @dev Manages coordination of a swarm network including round progression,
 * peer registration, bootnode management, and winner selection.
 */
contract SwarmCoordinator is UUPSUpgradeable {
    // .---------------------------------------------------.
    // |  █████████   █████               █████            |
    // | ███░░░░░███ ░░███               ░░███             |
    // |░███    ░░░  ███████    ██████   ███████    ██████ |
    // |░░█████████ ░░░███░    ░░░░░███ ░░░███░    ███░░███|
    // | ░░░░░░░░███  ░███      ███████   ░███    ░███████ |
    // | ███    ░███  ░███ ███ ███░░███   ░███ ███░███░░░  |
    // |░░█████████   ░░█████ ░░████████  ░░█████ ░░██████ |
    // | ░░░░░░░░░     ░░░░░   ░░░░░░░░    ░░░░░   ░░░░░░  |
    // '---------------------------------------------------'

    // Current round number
    uint256 _currentRound = 0;
    // Maps EOA addresses to their corresponding peer IDs
    mapping(address => string[]) _eoaToPeerId;
    // Maps peer IDs to their corresponding EOA addresses
    mapping(string => address) _peerIdToEoa;

    // Winner management state
    // Maps peer ID to total number of wins
    mapping(string => uint256) private _totalWins;
    // Maps round number to mapping of voter address to their voted peer IDs
    mapping(uint256 => mapping(string => string[])) private _roundVotes;
    // List of bootnode addresses/endpoints
    string[] private _bootnodes;
    // Maps round number to mapping of account address to their submitted reward
    mapping(uint256 => mapping(address => int256)) private _roundRewards;
    // Maps round number to mapping of peer ID to whether they have submitted a reward
    mapping(uint256 => mapping(string => bool)) private _hasSubmittedRoundReward;
    // Maps peer ID to their total rewards across all rounds
    mapping(string => int256) private _totalRewards;

    // .----------------------------------------------.
    // | ███████████            ████                  |
    // |░░███░░░░░███          ░░███                  |
    // | ░███    ░███   ██████  ░███   ██████   █████ |
    // | ░██████████   ███░░███ ░███  ███░░███ ███░░  |
    // | ░███░░░░░███ ░███ ░███ ░███ ░███████ ░░█████ |
    // | ░███    ░███ ░███ ░███ ░███ ░███░░░   ░░░░███|
    // | █████   █████░░██████  █████░░██████  ██████ |
    // |░░░░░   ░░░░░  ░░░░░░  ░░░░░  ░░░░░░  ░░░░░░  |
    // '----------------------------------------------'

    mapping(bytes32 => mapping(address => bool)) private _roleToAddress;

    bytes32 public constant OWNER_ROLE = keccak256("OWNER_ROLE");
    bytes32 public constant BOOTNODE_MANAGER_ROLE = keccak256("BOOTNODE_MANAGER_ROLE");
    bytes32 public constant ROUND_MANAGER_ROLE = keccak256("ROUND_MANAGER_ROLE");

    // .-------------------------------------------------------------.
    // | ██████████                                  █████           |
    // |░░███░░░░░█                                 ░░███            |
    // | ░███  █ ░  █████ █████  ██████  ████████   ███████    █████ |
    // | ░██████   ░░███ ░░███  ███░░███░░███░░███ ░░░███░    ███░░  |
    // | ░███░░█    ░███  ░███ ░███████  ░███ ░███   ░███    ░░█████ |
    // | ░███ ░   █ ░░███ ███  ░███░░░   ░███ ░███   ░███ ███ ░░░░███|
    // | ██████████  ░░█████   ░░██████  ████ █████  ░░█████  ██████ |
    // |░░░░░░░░░░    ░░░░░     ░░░░░░  ░░░░ ░░░░░    ░░░░░  ░░░░░░  |
    // '-------------------------------------------------------------'

    event RoundAdvanced(uint256 indexed newRoundNumber);
    event PeerRegistered(address indexed eoa, string peerId);
    event BootnodesAdded(address indexed manager, uint256 count);
    event BootnodeRemoved(address indexed manager, uint256 index);
    event AllBootnodesCleared(address indexed manager);
    event WinnerSubmitted(address indexed account, string peerId, uint256 indexed roundNumber, string[] winners);
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);
    event RewardSubmitted(address indexed account, uint256 indexed roundNumber, int256 reward, string peerId);
    event CumulativeRewardsUpdated(address indexed account, string peerId, int256 totalRewards);

    // .----------------------------------------------------------.
    // | ██████████                                               |
    // |░░███░░░░░█                                               |
    // | ░███  █ ░  ████████  ████████   ██████  ████████   █████ |
    // | ░██████   ░░███░░███░░███░░███ ███░░███░░███░░███ ███░░  |
    // | ░███░░█    ░███ ░░░  ░███ ░░░ ░███ ░███ ░███ ░░░ ░░█████ |
    // | ░███ ░   █ ░███      ░███     ░███ ░███ ░███      ░░░░███|
    // | ██████████ █████     █████    ░░██████  █████     ██████ |
    // |░░░░░░░░░░ ░░░░░     ░░░░░      ░░░░░░  ░░░░░     ░░░░░░  |
    // '----------------------------------------------------------'

    error InvalidBootnodeIndex();
    error InvalidRoundNumber();
    error WinnerAlreadyVoted();
    error PeerIdAlreadyRegistered();
    error InvalidVoterPeerId();
    error OnlyOwner();
    error OnlyBootnodeManager();
    error OnlyRoundManager();
    error RewardAlreadySubmitted();
    error InvalidVote();

    // .-------------------------------------------------------------------------------------.
    // | ██████   ██████              █████  ███     ██████   ███                            |
    // |░░██████ ██████              ░░███  ░░░     ███░░███ ░░░                             |
    // | ░███░█████░███   ██████   ███████  ████   ░███ ░░░  ████   ██████  ████████   █████ |
    // | ░███░░███ ░███  ███░░███ ███░░███ ░░███  ███████   ░░███  ███░░███░░███░░███ ███░░  |
    // | ░███ ░░░  ░███ ░███ ░███░███ ░███  ░███ ░░░███░     ░███ ░███████  ░███ ░░░ ░░█████ |
    // | ░███      ░███ ░███ ░███░███ ░███  ░███   ░███      ░███ ░███░░░   ░███      ░░░░███|
    // | █████     █████░░██████ ░░████████ █████  █████     █████░░██████  █████     ██████ |
    // |░░░░░     ░░░░░  ░░░░░░   ░░░░░░░░ ░░░░░  ░░░░░     ░░░░░  ░░░░░░  ░░░░░     ░░░░░░  |
    // '-------------------------------------------------------------------------------------'

    // Owner modifier
    modifier onlyOwner() {
        require(_roleToAddress[OWNER_ROLE][msg.sender], OnlyOwner());
        _;
    }

    // Round manager modifier
    modifier onlyRoundManager() {
        require(_roleToAddress[ROUND_MANAGER_ROLE][msg.sender], OnlyRoundManager());
        _;
    }

    // Bootnode manager modifier
    modifier onlyBootnodeManager() {
        require(_roleToAddress[BOOTNODE_MANAGER_ROLE][msg.sender], OnlyBootnodeManager());
        _;
    }

    // .--------------------------------------------------------------------------------------------------------------.
    // |   █████████                               █████                                   █████                      |
    // |  ███░░░░░███                             ░░███                                   ░░███                       |
    // | ███     ░░░   ██████  ████████    █████  ███████   ████████  █████ ████  ██████  ███████    ██████  ████████ |
    // |░███          ███░░███░░███░░███  ███░░  ░░░███░   ░░███░░███░░███ ░███  ███░░███░░░███░    ███░░███░░███░░███|
    // |░███         ░███ ░███ ░███ ░███ ░░█████   ░███     ░███ ░░░  ░███ ░███ ░███ ░░░   ░███    ░███ ░███ ░███ ░░░ |
    // |░░███     ███░███ ░███ ░███ ░███  ░░░░███  ░███ ███ ░███      ░███ ░███ ░███  ███  ░███ ███░███ ░███ ░███     |
    // | ░░█████████ ░░██████  ████ █████ ██████   ░░█████  █████     ░░████████░░██████   ░░█████ ░░██████  █████    |
    // |  ░░░░░░░░░   ░░░░░░  ░░░░░░     ░░░░░░     ░░░░░  ░░░░░       ░░░░░░░░  ░░░░░░     ░░░░░   ░░░░░░  ░░░░░     |
    // '--------------------------------------------------------------------------------------------------------------'

    function initialize(address owner_) external initializer {
        _grantRole(OWNER_ROLE, owner_);
        _grantRole(ROUND_MANAGER_ROLE, owner_);
        _grantRole(BOOTNODE_MANAGER_ROLE, owner_);
        __UUPSUpgradeable_init();
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {
        // Intentionally left blank
    }

    // .---------------------------------------.
    // |   █████████     █████████  █████      |
    // |  ███░░░░░███   ███░░░░░███░░███       |
    // | ░███    ░███  ███     ░░░  ░███       |
    // | ░███████████ ░███          ░███       |
    // | ░███░░░░░███ ░███          ░███       |
    // | ░███    ░███ ░░███     ███ ░███      █|
    // | █████   █████ ░░█████████  ███████████|
    // |░░░░░   ░░░░░   ░░░░░░░░░  ░░░░░░░░░░░ |
    // '---------------------------------------'

    /**
     * @dev Grants a role to an account
     * @param role The role to grant
     * @param account The address of the account to grant the role to
     */
    function _grantRole(bytes32 role, address account) internal {
        _roleToAddress[role][account] = true;
        emit RoleGranted(role, account, msg.sender);
    }

    /**
     * @dev Grants a role to an account
     * @param role The role to grant
     * @param account The address of the account to grant the role to
     * @notice Only callable by the contract owner
     */
    function grantRole(bytes32 role, address account) public onlyOwner {
        _grantRole(role, account);
    }

    /**
     * @dev Removes a role from an account
     * @param role The role to revoke
     * @param account The address of the account to revoke the role from
     * @notice Only callable by the contract owner
     */
    function revokeRole(bytes32 role, address account) public onlyOwner {
        _roleToAddress[role][account] = false;
        emit RoleRevoked(role, account, msg.sender);
    }

    /**
     * @dev Checks if an account has a role
     * @param role The role to check
     * @param account The address of the account to check
     * @return True if the account has the role, false otherwise
     */
    function hasRole(bytes32 role, address account) public view returns (bool) {
        return _roleToAddress[role][account];
    }

    // .---------------------------------------------------------------.
    // | ███████████                                      █████        |
    // |░░███░░░░░███                                    ░░███         |
    // | ░███    ░███   ██████  █████ ████ ████████    ███████   █████ |
    // | ░██████████   ███░░███░░███ ░███ ░░███░░███  ███░░███  ███░░  |
    // | ░███░░░░░███ ░███ ░███ ░███ ░███  ░███ ░███ ░███ ░███ ░░█████ |
    // | ░███    ░███ ░███ ░███ ░███ ░███  ░███ ░███ ░███ ░███  ░░░░███|
    // | █████   █████░░██████  ░░████████ ████ █████░░████████ ██████ |
    // |░░░░░   ░░░░░  ░░░░░░    ░░░░░░░░ ░░░░ ░░░░░  ░░░░░░░░ ░░░░░░  |
    // '---------------------------------------------------------------'

    /**
     * @dev Returns the current round number
     * @return Current round number
     */
    function currentRound() public view returns (uint256) {
        return _currentRound;
    }

    /**
     * @dev Advances to the next round
     * @return The new round number
     * @notice Only callable by the round manager
     */
    function advanceRound() external onlyRoundManager returns (uint256) {
        _currentRound++;
        emit RoundAdvanced(_currentRound);
        return _currentRound;
    }

    // .-------------------------------------------------.
    // | ███████████                                     |
    // |░░███░░░░░███                                    |
    // | ░███    ░███  ██████   ██████  ████████   █████ |
    // | ░██████████  ███░░███ ███░░███░░███░░███ ███░░  |
    // | ░███░░░░░░  ░███████ ░███████  ░███ ░░░ ░░█████ |
    // | ░███        ░███░░░  ░███░░░   ░███      ░░░░███|
    // | █████       ░░██████ ░░██████  █████     ██████ |
    // |░░░░░         ░░░░░░   ░░░░░░  ░░░░░     ░░░░░░  |
    // '-------------------------------------------------'

    /**
     * @dev Registers a peer's ID and associates it with the sender's address
     * @param peerId The peer ID to register
     */
    function registerPeer(string calldata peerId) external {
        address eoa = msg.sender;

        // Check if the peer ID is already registered
        if (_peerIdToEoa[peerId] != address(0)) revert PeerIdAlreadyRegistered();

        // Set new mappings
        _eoaToPeerId[eoa].push(peerId);
        _peerIdToEoa[peerId] = eoa;

        emit PeerRegistered(eoa, peerId);
    }

    /**
     * @dev Retrieves the peer IDs associated with multiple EOA addresses
     * @param eoas Array of EOA addresses to look up
     * @return Array of peer IDs associated with the EOA addresses
     */
    function getPeerId(address[] calldata eoas) external view returns (string[][] memory) {
        string[][] memory peerIds = new string[][](eoas.length);
        for (uint256 i = 0; i < eoas.length; i++) {
            peerIds[i] = _eoaToPeerId[eoas[i]];
        }
        return peerIds;
    }

    /**
     * @dev Retrieves the EOA addresses associated with multiple peer IDs
     * @param peerIds Array of peer IDs to look up
     * @return Array of EOA addresses associated with the peer IDs
     */
    function getEoa(string[] calldata peerIds) external view returns (address[] memory) {
        address[] memory eoas = new address[](peerIds.length);
        for (uint256 i = 0; i < peerIds.length; i++) {
            eoas[i] = _peerIdToEoa[peerIds[i]];
        }
        return eoas;
    }

    // .----------------------------------------------------------------------------------------.
    // | ███████████                     █████                            █████                 |
    // |░░███░░░░░███                   ░░███                            ░░███                  |
    // | ░███    ░███  ██████   ██████  ███████   ████████    ██████   ███████   ██████   █████ |
    // | ░██████████  ███░░███ ███░░███░░░███░   ░░███░░███  ███░░███ ███░░███  ███░░███ ███░░  |
    // | ░███░░░░░███░███ ░███░███ ░███  ░███     ░███ ░███ ░███ ░███░███ ░███ ░███████ ░░█████ |
    // | ░███    ░███░███ ░███░███ ░███  ░███ ███ ░███ ░███ ░███ ░███░███ ░███ ░███░░░   ░░░░███|
    // | ███████████ ░░██████ ░░██████   ░░█████  ████ █████░░██████ ░░████████░░██████  ██████ |
    // |░░░░░░░░░░░   ░░░░░░   ░░░░░░     ░░░░░  ░░░░ ░░░░░  ░░░░░░   ░░░░░░░░  ░░░░░░  ░░░░░░  |
    // '----------------------------------------------------------------------------------------'

    /**
     * @dev Adds multiple bootnodes to the list
     * @param newBootnodes Array of bootnode strings to add
     * @notice Only callable by the bootnode manager
     */
    function addBootnodes(string[] calldata newBootnodes) external onlyBootnodeManager {
        uint256 count = newBootnodes.length;
        for (uint256 i = 0; i < count; i++) {
            _bootnodes.push(newBootnodes[i]);
        }
        emit BootnodesAdded(msg.sender, count);
    }

    /**
     * @dev Removes a bootnode at the specified index
     * @param index The index of the bootnode to remove
     * @notice Only callable by the bootnode manager
     */
    function removeBootnode(uint256 index) external onlyBootnodeManager {
        if (index >= _bootnodes.length) revert InvalidBootnodeIndex();

        // Move the last element to the position being deleted (unless it's the last element)
        if (index < _bootnodes.length - 1) {
            _bootnodes[index] = _bootnodes[_bootnodes.length - 1];
        }

        // Remove the last element
        _bootnodes.pop();

        emit BootnodeRemoved(msg.sender, index);
    }

    /**
     * @dev Clears all bootnodes from the list
     * @notice Only callable by the bootnode manager
     */
    function clearBootnodes() external onlyBootnodeManager {
        delete _bootnodes;
        emit AllBootnodesCleared(msg.sender);
    }

    /**
     * @dev Returns all registered bootnodes
     * @return Array of all bootnode strings
     */
    function getBootnodes() external view returns (string[] memory) {
        return _bootnodes;
    }

    /**
     * @dev Returns the number of registered bootnodes
     * @return The count of bootnodes
     */
    function getBootnodesCount() external view returns (uint256) {
        return _bootnodes.length;
    }

    // .-------------------------------------------------------------------------------------.
    // | █████   █████  ███           █████                                                  |
    // |░░███   ░░███  ░░░           ░░███                                                   |
    // | ░███    ░███  ████   ███████ ░███████    █████   ██████   ██████  ████████   ██████ |
    // | ░███████████ ░░███  ███░░███ ░███░░███  ███░░   ███░░███ ███░░███░░███░░███ ███░░███|
    // | ░███░░░░░███  ░███ ░███ ░███ ░███ ░███ ░░█████ ░███ ░░░ ░███ ░███ ░███ ░░░ ░███████ |
    // | ░███    ░███  ░███ ░███ ░███ ░███ ░███  ░░░░███░███  ███░███ ░███ ░███     ░███░░░  |
    // | █████   █████ █████░░███████ ████ █████ ██████ ░░██████ ░░██████  █████    ░░██████ |
    // |░░░░░   ░░░░░ ░░░░░  ░░░░░███░░░░ ░░░░░ ░░░░░░   ░░░░░░   ░░░░░░  ░░░░░      ░░░░░░  |
    // |                     ███ ░███                                                        |
    // |                    ░░██████                                                         |
    // |                     ░░░░░░                                                          |
    // '-------------------------------------------------------------------------------------'

    /**
     * @dev Submits a list of winners for a specific round
     * @param roundNumber The round number for which to submit the winners
     * @param winners The list of peer IDs that should win
     * @param peerId The peer ID of the voter
     */
    function submitWinners(uint256 roundNumber, string[] memory winners, string calldata peerId) external {
        // Check if round number is valid (must be less than or equal to current round)
        if (roundNumber > _currentRound) revert InvalidRoundNumber();

        // Check if sender has already voted
        if (_roundVotes[roundNumber][peerId].length > 0) revert WinnerAlreadyVoted();

        // Check if the peer ID belongs to the sender
        if (_peerIdToEoa[peerId] != msg.sender) revert InvalidVoterPeerId();

        // Check for duplicate winners
        for (uint256 i = 0; i < winners.length; i++) {
            for (uint256 j = i + 1; j < winners.length; j++) {
                if (keccak256(bytes(winners[i])) == keccak256(bytes(winners[j]))) {
                    revert InvalidVote();
                }
            }
        }

        // Record the vote
        _roundVotes[roundNumber][peerId] = winners;

        // Update total wins
        for (uint256 i = 0; i < winners.length; i++) {
            _totalWins[winners[i]]++;
        }

        emit WinnerSubmitted(msg.sender, peerId, roundNumber, winners);
    }

    /**
     * @dev Gets the votes for a specific round from a specific peer ID
     * @param roundNumber The round number to query
     * @param peerId The peer ID of the voter
     * @return Array of peer IDs that the voter voted for
     */
    function getVoterVotes(uint256 roundNumber, string calldata peerId) external view returns (string[] memory) {
        return _roundVotes[roundNumber][peerId];
    }

    /**
     * @dev Gets the total number of wins for a peer ID
     * @param peerId The peer ID to query
     * @return The total number of wins for the peer ID
     */
    function getTotalWins(string calldata peerId) external view returns (uint256) {
        return _totalWins[peerId];
    }

    /**
     * @dev Submits a reward for a specific round
     * @param roundNumber The round number for which to submit the reward
     * @param reward The reward amount to submit (can be positive or negative)
     * @param peerId The peer ID reporting the rewards
     */
    function submitReward(uint256 roundNumber, int256 reward, string calldata peerId) external {
        // Check if round number is valid (must be less than or equal to current round)
        if (roundNumber > _currentRound) revert InvalidRoundNumber();

        // Check if peer ID has already submitted a reward for this round
        if (_hasSubmittedRoundReward[roundNumber][peerId]) revert RewardAlreadySubmitted();

        // Check if the peer ID belongs to the sender
        if (_peerIdToEoa[peerId] != msg.sender) revert InvalidVoterPeerId();

        // Record the reward
        _roundRewards[roundNumber][msg.sender] += reward;
        _hasSubmittedRoundReward[roundNumber][peerId] = true;

        // Update total rewards per peerId
        _totalRewards[peerId] += reward;

        emit RewardSubmitted(msg.sender, roundNumber, reward, peerId);
        emit CumulativeRewardsUpdated(msg.sender, peerId, _totalRewards[peerId]);
    }

    /**
     * @dev Gets the reward submitted by accounts for a specific round
     * @param roundNumber The round number to query
     * @param accounts Array of addresses to query
     * @return rewards Array of corresponding reward amounts for each account
     */
    function getRoundReward(uint256 roundNumber, address[] calldata accounts) external view returns (int256[] memory) {
        int256[] memory rewards = new int256[](accounts.length);
        for (uint256 i = 0; i < accounts.length; i++) {
            rewards[i] = _roundRewards[roundNumber][accounts[i]];
        }
        return rewards;
    }

    /**
     * @dev Checks if a peer ID has submitted a reward for a specific round
     * @param roundNumber The round number to check
     * @param peerId The peer ID to check
     * @return True if the peer ID has submitted a reward for that round, false otherwise
     */
    function hasSubmittedRoundReward(uint256 roundNumber, string calldata peerId) external view returns (bool) {
        return _hasSubmittedRoundReward[roundNumber][peerId];
    }

    /**
     * @dev Gets the total rewards earned by accounts across all rounds
     * @param peerIds Array of peer IDs to query
     * @return rewards Array of corresponding total rewards for each peer ID
     */
    function getTotalRewards(string[] calldata peerIds) external view returns (int256[] memory) {
        int256[] memory rewards = new int256[](peerIds.length);
        for (uint256 i = 0; i < peerIds.length; i++) {
            rewards[i] = _totalRewards[peerIds[i]];
        }
        return rewards;
    }
}
