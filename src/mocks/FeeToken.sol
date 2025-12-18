// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract FeeToken is ERC20 {
    uint256 public constant FEE_BPS = 200; // 2%

    constructor() ERC20("FeeToken", "FEE") {
        _mint(msg.sender, 1_000_000 ether);
    }

    function _update(
        address from,
        address to,
        uint256 amount
    ) internal override {
        if (from != address(0) && to != address(0)) {
            uint256 fee = (amount * FEE_BPS) / 10_000;
            uint256 net = amount - fee;

            super._update(from, to, net);
            super._update(from, address(0xdead), fee);
        } else {
            super._update(from, to, amount);
        }
    }
}
