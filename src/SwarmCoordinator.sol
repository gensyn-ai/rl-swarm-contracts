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
    uint256 _stageCount = 0;
    // Maps EOA addresses to their corresponding peer IDs
    mapping(address => string[]) _eoaToPeerId;
    // Maps peer IDs to their corresponding EOA addresses
    mapping(string => address) _peerIdToEoa;

    // Winner management state
    // Maps peer ID to total number of wins
    mapping(string => uint256) private _totalWins;
    // Maps round number to mapping of voter address to their voted peer IDs
    mapping(uint256 => mapping(address => string[])) private _roundVotes;
    // Maps round number to mapping of peer ID to number of votes received
    mapping(uint256 => mapping(string => uint256)) private _roundVoteCounts;
    // Maps voter address to number of times they have voted
    mapping(address => uint256) private _voterVoteCounts;
    // Number of unique voters who have participated
    uint256 private _uniqueVoters;
    // Number of unique peers that have been voted on
    uint256 private _uniqueVotedPeers;
    // Maps peer ID to whether it has been voted on in any round
    mapping(string => bool) private _hasBeenVotedOn;
    // List of bootnode addresses/endpoints
    string[] private _bootnodes;

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
    event WinnerSubmitted(address indexed voter, uint256 indexed roundNumber, string[] winners);
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

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
    error InvalidPeerId();
    error OnlyOwner();
    error OnlyBootnodeManager();
    error OnlyStageManager();

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
    // |  ░░░░░░░░░   ░░░░░░  ░░░░ ░░░░░ ░░░░░░     ░░░░░  ░░░░░       ░░░░░░░░  ░░░░░░     ░░░░░   ░░░░░░  ░░░░░     |
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
     * @dev Sets the total number of stages in a round
     * @param stageCount_ New total number of stages
     */
    function setStageCount(uint256 stageCount_) public onlyOwner {
        _stageCount = stageCount_;
    }

    /**
     * @dev Returns the total number of stages in a round
     * @return Number of stages
     */
    function stageCount() public view returns (uint256) {
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

    // .---------------------------------------------------------------------------.
    // | █████   ███   █████  ███                                                  |
    // |░░███   ░███  ░░███  ░░░                                                   |
    // | ░███   ░███   ░███  ████  ████████   ████████    ██████  ████████   █████ |
    // | ░███   ░███   ░███ ░░███ ░░███░░███ ░░███░░███  ███░░███░░███░░███ ███░░  |
    // | ░░███  █████  ███   ░███  ░███ ░███  ░███ ░███ ░███████  ░███ ░░░ ░░█████ |
    // |  ░░░█████░█████░    ░███  ░███ ░███  ░███ ░███ ░███░░░   ░███      ░░░░███|
    // |    ░░███ ░░███      █████ ████ █████ ████ █████░░██████  █████     ██████ |
    // |     ░░░   ░░░      ░░░░░ ░░░░ ░░░░░ ░░░░ ░░░░░  ░░░░░░  ░░░░░     ░░░░░░  |
    // '---------------------------------------------------------------------------'

    /**
     * @dev Submits a list of winners for a specific round
     * @param roundNumber The round number for which to submit the winners
     * @param winners The list of peer IDs that should win
     */
    function submitWinners(uint256 roundNumber, string[] memory winners) external {
        // Check if round number is valid (must be less than or equal to current round)
        if (roundNumber > _currentRound) revert InvalidRoundNumber();

        // Check if sender has already voted
        if (_roundVotes[roundNumber][msg.sender].length > 0) revert WinnerAlreadyVoted();

        // If this is the first time this address has voted, increment unique voters
        if (_voterVoteCounts[msg.sender] == 0) {
            _uniqueVoters++;
        }

        // Record the vote
        _roundVotes[roundNumber][msg.sender] = winners;

        // Update vote counts and track unique voted peers
        for (uint256 i = 0; i < winners.length; i++) {
            _roundVoteCounts[roundNumber][winners[i]]++;

            // If this peer has never been voted on before, increment unique voted peers
            if (!_hasBeenVotedOn[winners[i]]) {
                _hasBeenVotedOn[winners[i]] = true;
                _uniqueVotedPeers++;
            }
        }

        // Update how many times each voter has voted
        _voterVoteCounts[msg.sender]++;

        // Update total wins
        for (uint256 i = 0; i < winners.length; i++) {
            _totalWins[winners[i]]++;
        }

        emit WinnerSubmitted(msg.sender, roundNumber, winners);
    }

    /**
     * @dev Gets the number of times a voter has voted
     * @param voter The address of the voter
     * @return The number of times the voter has voted
     */
    function getVoterVoteCount(address voter) external view returns (uint256) {
        return _voterVoteCounts[voter];
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
     * @dev Gets the votes for a specific round from a specific voter
     * @param roundNumber The round number to query
     * @param voter The address of the voter
     * @return Array of peer IDs that the voter voted for
     */
    function getVoterVotes(uint256 roundNumber, address voter) external view returns (string[] memory) {
        return _roundVotes[roundNumber][voter];
    }

    /**
     * @dev Gets the vote count for a specific peer ID in a round
     * @param roundNumber The round number to query
     * @param peerId The peer ID to query
     * @return The number of votes received by the peer ID in that round
     */
    function getPeerVoteCount(uint256 roundNumber, string calldata peerId) external view returns (uint256) {
        return _roundVoteCounts[roundNumber][peerId];
    }

    /**
     * @dev Gets the total number of unique voters who have participated
     * @return The number of unique voters
     */
    function uniqueVoters() external view returns (uint256) {
        return _uniqueVoters;
    }

    /**
     * @dev Gets the total number of unique peers that have been voted on
     * @return The number of unique peers that have received votes
     */
    function uniqueVotedPeers() external view returns (uint256) {
        return _uniqueVotedPeers;
    }
}
