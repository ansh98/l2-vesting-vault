// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

contract VestingVault is AccessControl, ReentrancyGuard, Pausable {
    bytes32 public constant SCHEDULER_ROLE = keccak256("SCHEDULER_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");

    IERC20 public immutable token;
    address public treasury;
    uint16 public feeBps;

    struct Schedule {
        uint64 start;
        uint64 cliff;
        uint64 duration;
        uint128 total;
        uint128 released;
        bool revocable;
        bool revoked;
    }

    mapping(address => mapping(uint256 => Schedule)) public schedules;
    mapping(address => uint256) public scheduleCount;

    event ScheduleCreated(address indexed beneficiary, uint256 indexed id, uint256 total);
    event Claimed(address indexed beneficiary, uint256 indexed id, uint256 amount);
    event ScheduleRevoked(address indexed beneficiary, uint256 indexed id, uint256 refunded);

    error InvalidParams();
    error NothingToClaim();
    error NotRevocable();
    error AlreadyRevoked();
    error FeeTooHigh();

    constructor(IERC20 _token, address _treasury, uint16 _feeBps) {
        if (address(_token) == address(0) || _treasury == address(0)) revert InvalidParams();
        if (_feeBps > 500) revert FeeTooHigh();

        token = _token;
        treasury = _treasury;
        feeBps = _feeBps;

        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(SCHEDULER_ROLE, msg.sender);
        _grantRole(PAUSER_ROLE, msg.sender);
    }

    function createSchedule(
        address beneficiary,
        uint64 start,
        uint64 cliff,
        uint64 duration,
        uint128 total,
        bool revocable
    ) external onlyRole(SCHEDULER_ROL_

