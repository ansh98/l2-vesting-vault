// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";


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

    constructor(IERC20 _token, address _treasury, uint16 _feeBps) {
        if (address(_token) == address(0) || _treasury == address(0)) revert InvalidParams();
        if (_feeBps > 500) revert InvalidParams();

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
    ) external onlyRole(SCHEDULER_ROLE) {
        if (
            beneficiary == address(0) ||
            total == 0 ||
            duration == 0 ||
            cliff > duration
        ) revert InvalidParams();

        uint256 id = scheduleCount[beneficiary]++;

        schedules[beneficiary][id] = Schedule(
            start,
            cliff,
            duration,
            total,
            0,
            revocable,
            false
        );

        emit ScheduleCreated(beneficiary, id, total);
    }

    function previewClaimable(address beneficiary, uint256 id) public view returns (uint256) {
        Schedule memory s = schedules[beneficiary][id];
        if (s.revoked || s.total == 0) return 0;

        if (block.timestamp < s.start + s.cliff) return 0;

        uint256 vested = block.timestamp >= s.start + s.duration
            ? s.total
            : (s.total * (block.timestamp - s.start)) / s.duration;

        return vested > s.released ? vested - s.released : 0;
    }

    function claim(address beneficiary, uint256 id)
        external
        nonReentrant
        whenNotPaused
    {
        uint256 amount = previewClaimable(beneficiary, id);
        if (amount == 0) revert NothingToClaim();

        Schedule storage s = schedules[beneficiary][id];
        s.released += uint128(amount);

        uint256 beforeBal = token.balanceOf(address(this));
        token.transfer(beneficiary, amount);
        uint256 afterBal = token.balanceOf(address(this));

        uint256 actual = beforeBal - afterBal;
        uint256 fee = (actual * feeBps) / 10_000;

        if (fee > 0) token.transfer(treasury, fee);

        emit Claimed(beneficiary, id, actual - fee);
    }

    function revokeSchedule(address beneficiary, uint256 id)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        Schedule storage s = schedules[beneficiary][id];
        if (!s.revocable) revert NotRevocable();
        if (s.revoked) revert AlreadyRevoked();

        uint256 vested = s.released + previewClaimable(beneficiary, id);
        uint256 unvested = s.total - vested;

        s.revoked = true;

        if (unvested > 0) token.transfer(treasury, unvested);

        emit ScheduleRevoked(beneficiary, id, unvested);
    }

    function pause() external onlyRole(PAUSER_ROLE) {
        _pause();
    }

    function unpause() external onlyRole(PAUSER_ROLE) {
        _unpause();
    }
}
