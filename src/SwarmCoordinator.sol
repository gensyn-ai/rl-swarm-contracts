// SPDX-License-Identifier: MIT
pragma solidity ^0.8;

import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

/**
 * @title SwarmCoordinator
 * @dev Manages coordination of a swarm network including round/stage progression,
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
    // Current stage within the round
    uint256 _currentStage = 0;
    // Total number of stages in a round
    uint256 constant _stageCount = 3;
    // Maps EOA addresses to their corresponding peer IDs
    mapping(address => string[]) _eoaToPeerId;
    // Maps peer IDs to their corresponding EOA addresses
    mapping(string => address) _peerIdToEoa;

    // Winner management state
    // Maps peer ID to total number of wins
    mapping(string => uint256) private _totalWins;
    // Array of top winners (sorted by wins)
    string[] private _topWinners;
    // Maximum number of top winners to track
    uint256 private constant MAX_TOP_WINNERS = 100;
    // Maps round number to mapping of voter address to their voted peer IDs
    mapping(uint256 => mapping(string => bool)) private _roundVoted;
    // Maps round number to mapping of peer ID to number of votes received
    mapping(uint256 => mapping(string => uint256)) private _roundVoteCounts;
    // Maps voter address to number of times they have voted
    mapping(string => uint256) private _voterVoteCounts;
    // Array of top voters (sorted by number of votes)
    string[] private _topVoters;
    // Number of unique voters who have participated
    uint256 private _uniqueVoters;
    // Number of unique peers that have been voted on
    uint256 private _uniqueVotedPeers;
    // Maps peer ID to whether it has been voted on in any round
    mapping(string => bool) private _hasBeenVotedOn;
    // List of bootnode addresses/endpoints
    string[] private _bootnodes;
    // Maps round number and stage to mapping of account address to their submitted reward
    mapping(uint256 => mapping(uint256 => mapping(address => int256))) private _roundStageRewards;
    // Maps round number and stage to mapping of peer ID to whether they have submitted a reward
    mapping(uint256 => mapping(uint256 => mapping(string => bool))) private _hasSubmittedRoundStageReward;
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
    bytes32 public constant STAGE_MANAGER_ROLE = keccak256("STAGE_MANAGER_ROLE");

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

    event StageAdvanced(uint256 indexed roundNumber, uint256 newStage);
    event RoundAdvanced(uint256 indexed newRoundNumber);
    event PeerRegistered(address indexed eoa, string peerId);
    event BootnodesAdded(address indexed manager, uint256 count);
    event BootnodeRemoved(address indexed manager, uint256 index);
    event AllBootnodesCleared(address indexed manager);
    event WinnerSubmitted(address indexed account, string peerId, uint256 indexed roundNumber, string[] winners);
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);
    event RewardSubmitted(
        address indexed account, uint256 indexed roundNumber, uint256 indexed stageNumber, int256 reward, string peerId
    );
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

    error StageOutOfBounds();
    error InvalidBootnodeIndex();
    error InvalidRoundNumber();
    error WinnerAlreadyVoted();
    error PeerIdAlreadyRegistered();
    error InvalidVoterPeerId();
    error OnlyOwner();
    error OnlyBootnodeManager();
    error OnlyStageManager();
    error RewardAlreadySubmitted();
    error InvalidStageNumber();
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

    // Stage manager modifier
    modifier onlyStageManager() {
        require(_roleToAddress[STAGE_MANAGER_ROLE][msg.sender], OnlyStageManager());
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
        _grantRole(STAGE_MANAGER_ROLE, owner_);
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
     * @dev Returns the current stage number within the round
     * @return Current stage number
     */
    function currentStage() public view returns (uint256) {
        return _currentStage;
    }

    /**
     * @dev Returns the total number of stages in a round
     * @return Number of stages
     */
    function stageCount() public pure returns (uint256) {
        return _stageCount;
    }

    /**
     * @dev Updates the current stage and round
     * @return The current round and stage after any updates
     * @notice Only callable by the stage manager
     */
    function updateStageAndRound() external onlyStageManager returns (uint256, uint256) {
        if (_currentStage + 1 >= _stageCount) {
            // If we're at the last stage, advance to the next round
            _currentRound++;
            _currentStage = 0;
            emit RoundAdvanced(_currentRound);
        } else {
            // Otherwise, advance to the next stage
            _currentStage = _currentStage + 1;
        }

        emit StageAdvanced(_currentRound, _currentStage);

        return (_currentRound, _currentStage);
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
        if (_roundVoted[roundNumber][peerId]) revert WinnerAlreadyVoted();
        _roundVoted[roundNumber][peerId] = true;

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

        emit WinnerSubmitted(msg.sender, peerId, roundNumber, winners);
    }

    /**
     * @dev Monkey patch to accept uint256 rewards, temporary solution
     * @param roundNumber The round number for which to submit the reward
     * @param stageNumber The stage number for which to submit the reward
     * @param reward The reward amount to submit (can be positive or negative)
     * @param peerId The peer ID reporting the rewards
     */
    function submitReward(uint256 roundNumber, uint256 stageNumber, uint256 reward, string calldata peerId) external {
        submitReward(roundNumber, stageNumber, int256(reward), peerId);
    }

    /**
     * @dev Submits a reward for a specific round and stage
     * @param roundNumber The round number for which to submit the reward
     * @param stageNumber The stage number for which to submit the reward
     * @param reward The reward amount to submit (can be positive or negative)
     * @param peerId The peer ID reporting the rewards
     */
    function submitReward(uint256 roundNumber, uint256 stageNumber, int256 reward, string calldata peerId) public {
        // Check if round number is valid (must be less than or equal to current round)
        if (roundNumber > _currentRound) revert InvalidRoundNumber();

        // Check if stage number is valid
        if (roundNumber == _currentRound) {
            // If round is current round, stage number must be less than or equal to current stage
            if (stageNumber > _currentStage) revert InvalidStageNumber();
        } else {
            // If round is not current round, stage number must be less than stage count
            if (stageNumber > _stageCount) revert InvalidStageNumber();
        }

        // Check if peer ID has already submitted a reward for this round and stage
        if (_hasSubmittedRoundStageReward[roundNumber][stageNumber][peerId]) revert RewardAlreadySubmitted();

        // Check if the peer ID belongs to the sender
        if (_peerIdToEoa[peerId] != msg.sender) revert InvalidVoterPeerId();

        // Record the reward
        _roundStageRewards[roundNumber][stageNumber][msg.sender] += reward;
        _hasSubmittedRoundStageReward[roundNumber][stageNumber][peerId] = true;

        // Update total rewards per peerId
        _totalRewards[peerId] += reward;

        emit RewardSubmitted(msg.sender, roundNumber, stageNumber, reward, peerId);
        emit CumulativeRewardsUpdated(msg.sender, peerId, _totalRewards[peerId]);
    }

    /**
     * @dev Gets the reward submitted by accounts for a specific round and stage
     * @param roundNumber The round number to query
     * @param stageNumber The stage number to query
     * @param accounts Array of addresses to query
     * @return rewards Array of corresponding reward amounts for each account
     */
    function getRoundStageReward(uint256 roundNumber, uint256 stageNumber, address[] calldata accounts)
        external
        view
        returns (int256[] memory)
    {
        int256[] memory rewards = new int256[](accounts.length);
        for (uint256 i = 0; i < accounts.length; i++) {
            rewards[i] = _roundStageRewards[roundNumber][stageNumber][accounts[i]];
        }
        return rewards;
    }

    /**
     * @dev Checks if a peer ID has submitted a reward for a specific round and stage
     * @param roundNumber The round number to check
     * @param stageNumber The stage number to check
     * @param peerId The peer ID to check
     * @return True if the peer ID has submitted a reward for that round and stage, false otherwise
     */
    function hasSubmittedRoundStageReward(uint256 roundNumber, uint256 stageNumber, string calldata peerId)
        external
        view
        returns (bool)
    {
        return _hasSubmittedRoundStageReward[roundNumber][stageNumber][peerId];
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
