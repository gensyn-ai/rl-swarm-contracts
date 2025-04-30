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
    // Maps round number to mapping of voter address to whether they have voted
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
    mapping(uint256 => mapping(uint256 => mapping(address => uint256))) private _roundStageRewards;
    // Maps round number and stage to mapping of account address to whether they have submitted a reward
    mapping(uint256 => mapping(uint256 => mapping(address => bool))) private _hasSubmittedRoundStageReward;
    // Maps peer ID to their total rewards across all rounds
    mapping(string => uint256) private _totalRewards;

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
        address indexed account, uint256 indexed roundNumber, uint256 indexed stageNumber, uint256 reward, string peerId
    );
    event CumulativeRewardsUpdated(address indexed account, string peerId, uint256 totalRewards);

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

        // If this is the first time this peer has voted, increment unique voters
        if (_voterVoteCounts[peerId] == 0) {
            _uniqueVoters++;
        }

        // Record the vote
        _roundVoted[roundNumber][peerId] = true;

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
        _voterVoteCounts[peerId]++;
        _updateTopVoters(peerId);

        // Update total wins and top winners
        for (uint256 i = 0; i < winners.length; i++) {
            _totalWins[winners[i]]++;
            _updateTopWinners(winners[i]);
        }

        emit WinnerSubmitted(msg.sender, peerId, roundNumber, winners);
    }

    /**
     * @dev Updates the top voters list when a voter's score changes
     * @param voter The peer ID whose score has changed
     */
    function _updateTopVoters(string memory voter) internal {
        uint256 voterVotes = _voterVoteCounts[voter];

        // Find if voter is already in the list
        uint256 currentIndex = type(uint256).max;
        uint256 topVotersLength = _topVoters.length;
        for (uint256 i = 0; i < topVotersLength; i++) {
            if (keccak256(bytes(_topVoters[i])) == keccak256(bytes(voter))) {
                currentIndex = i;
                break;
            }
        }

        if (currentIndex == type(uint256).max) {
            // Voter is not in the list
            if (topVotersLength < MAX_TOP_WINNERS) {
                // List is not full, add to end
                _topVoters.push(voter);
                topVotersLength++;
                currentIndex = topVotersLength - 1;
            } else {
                // List is full, check if voter should be added
                if (_voterVoteCounts[_topVoters[topVotersLength - 1]] < voterVotes) {
                    // Replace last place
                    _topVoters[topVotersLength - 1] = voter;
                    currentIndex = topVotersLength - 1;
                } else {
                    // Voter doesn't qualify for top list
                    return;
                }
            }
        }

        // Find our how far we need to move the voter up in the list
        uint256 initialIndex = currentIndex;
        while (currentIndex > 0 && _voterVoteCounts[_topVoters[currentIndex - 1]] < voterVotes) {
            currentIndex--;
        }

        // Swap if voter moved up in the list
        if (currentIndex != initialIndex) {
            string memory temp = _topVoters[currentIndex];
            _topVoters[currentIndex] = _topVoters[initialIndex];
            _topVoters[initialIndex] = temp;
        }
    }

    /**
     * @dev Updates the top winners list when a winner's score changes
     * @param winner The peer ID whose score has changed
     */
    function _updateTopWinners(string memory winner) internal {
        uint256 winnerWins = _totalWins[winner];

        // Find if winner is already in the list
        uint256 currentIndex = type(uint256).max;
        uint256 topWinnersLength = _topWinners.length;
        for (uint256 i = 0; i < topWinnersLength; i++) {
            if (keccak256(bytes(_topWinners[i])) == keccak256(bytes(winner))) {
                currentIndex = i;
                break;
            }
        }

        if (currentIndex == type(uint256).max) {
            // Winner is not in the list
            if (topWinnersLength < MAX_TOP_WINNERS) {
                // List is not full, add to end
                _topWinners.push(winner);
                topWinnersLength++;
                currentIndex = topWinnersLength - 1;
            } else {
                // List is full, check if winner should be added
                if (_totalWins[_topWinners[topWinnersLength - 1]] < winnerWins) {
                    // Replace last place
                    _topWinners[topWinnersLength - 1] = winner;
                    currentIndex = topWinnersLength - 1;
                } else {
                    // Winner doesn't qualify for top list
                    return;
                }
            }
        }

        // Find our how far we need to move the voter up in the list
        uint256 initialIndex = currentIndex;
        while (currentIndex > 0 && _totalWins[_topWinners[currentIndex - 1]] < winnerWins) {
            currentIndex--;
        }

        // Swap if winner moved up in the list
        if (currentIndex != initialIndex) {
            string memory temp = _topWinners[currentIndex];
            _topWinners[currentIndex] = _topWinners[initialIndex];
            _topWinners[initialIndex] = temp;
        }
    }

    /**
     * @dev Gets the number of times a voter has voted
     * @param peerId The peer ID of the voter
     * @return The number of times the voter has voted
     */
    function getVoterVoteCount(string calldata peerId) external view returns (uint256) {
        return _voterVoteCounts[peerId];
    }

    /**
     * @dev Gets a slice of the voter leaderboard
     * @param start The starting index (inclusive)
     * @param end The ending index (exclusive)
     * @return peerIds Array of peer IDs sorted by number of votes (descending)
     * @return voteCounts Array of corresponding vote counts
     */
    function voterLeaderboard(uint256 start, uint256 end)
        external
        view
        returns (string[] memory peerIds, uint256[] memory voteCounts)
    {
        // Ensure start is not greater than end
        require(start <= end, "Start index must be less than or equal to end index");

        // Ensure end is not greater than the length of the list
        if (end > _topVoters.length) {
            end = _topVoters.length;
        }

        // Ensure start is not greater than the length of the list
        if (start > _topVoters.length) {
            start = _topVoters.length;
        }

        // Create result arrays with the correct size
        uint256 length = end - start;
        peerIds = new string[](length);
        voteCounts = new uint256[](length);

        // Fill the arrays
        for (uint256 i = start; i < end; i++) {
            uint256 index = i - start;

            // Cache the top voter
            string memory topVoter = _topVoters[i];

            peerIds[index] = topVoter;
            voteCounts[index] = _voterVoteCounts[topVoter];
        }

        return (peerIds, voteCounts);
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
     * @dev Gets the vote count for a specific peer ID in a round
     * @param roundNumber The round number to query
     * @param peerId The peer ID to query
     * @return The number of votes received by the peer ID in that round
     */
    function getPeerVoteCount(uint256 roundNumber, string calldata peerId) external view returns (uint256) {
        return _roundVoteCounts[roundNumber][peerId];
    }

    /**
     * @dev Gets a slice of the leaderboard
     * @param start The starting index (inclusive)
     * @param end The ending index (exclusive)
     * @return peerIds Array of peer IDs sorted by number of wins (descending)
     * @return wins Array of corresponding win counts
     */
    function winnerLeaderboard(uint256 start, uint256 end)
        external
        view
        returns (string[] memory peerIds, uint256[] memory wins)
    {
        // Ensure start is not greater than end
        require(start <= end, "Start index must be less than or equal to end index");

        // Ensure end is not greater than the length of the list
        if (end > _topWinners.length) {
            end = _topWinners.length;
        }

        // Ensure start is not greater than the length of the list
        if (start > _topWinners.length) {
            start = _topWinners.length;
        }

        // Create result arrays with the correct size
        uint256 length = end - start;
        peerIds = new string[](length);
        wins = new uint256[](length);

        // Fill the arrays
        for (uint256 i = start; i < end; i++) {
            uint256 index = i - start;

            // Cache the top winner
            string memory topWinner = _topWinners[i];

            peerIds[index] = topWinner;
            wins[index] = _totalWins[topWinner];
        }

        return (peerIds, wins);
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

    /**
     * @dev Submits a reward for a specific round and stage
     * @param roundNumber The round number for which to submit the reward
     * @param stageNumber The stage number for which to submit the reward
     * @param reward The reward amount to submit
     * @param peerId The peer ID reporting the rewards
     */
    function submitReward(uint256 roundNumber, uint256 stageNumber, uint256 reward, string calldata peerId) external {
        // Check if round number is valid (must be less than or equal to current round)
        if (roundNumber > _currentRound) revert InvalidRoundNumber();

        // Check if stage number is valid (must be less than stage count)
        if (stageNumber >= _stageCount) revert InvalidStageNumber();

        // Check if sender has already submitted a reward for this round and stage
        if (_hasSubmittedRoundStageReward[roundNumber][stageNumber][msg.sender]) revert RewardAlreadySubmitted();

        // Check if the peer ID belongs to the sender
        if (_peerIdToEoa[peerId] != msg.sender) revert InvalidVoterPeerId();

        // Record the reward
        _roundStageRewards[roundNumber][stageNumber][msg.sender] = reward;
        _hasSubmittedRoundStageReward[roundNumber][stageNumber][msg.sender] = true;

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
        returns (uint256[] memory)
    {
        uint256[] memory rewards = new uint256[](accounts.length);
        for (uint256 i = 0; i < accounts.length; i++) {
            rewards[i] = _roundStageRewards[roundNumber][stageNumber][accounts[i]];
        }
        return rewards;
    }

    /**
     * @dev Checks if an account has submitted a reward for a specific round and stage
     * @param roundNumber The round number to check
     * @param stageNumber The stage number to check
     * @param account The address of the account
     * @return True if the account has submitted a reward for that round and stage, false otherwise
     */
    function hasSubmittedRoundStageReward(uint256 roundNumber, uint256 stageNumber, address account)
        external
        view
        returns (bool)
    {
        return _hasSubmittedRoundStageReward[roundNumber][stageNumber][account];
    }

    /**
     * @dev Gets the total rewards earned by accounts across all rounds
     * @param peerIds Array of peer IDs to query
     * @return rewards Array of corresponding total rewards for each peer ID
     */
    function getTotalRewards(string[] calldata peerIds) external view returns (uint256[] memory) {
        uint256[] memory rewards = new uint256[](peerIds.length);
        for (uint256 i = 0; i < peerIds.length; i++) {
            rewards[i] = _totalRewards[peerIds[i]];
        }
        return rewards;
    }
}
