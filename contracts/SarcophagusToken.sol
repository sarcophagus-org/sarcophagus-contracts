// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

import "./token/ERC20/ERC20.sol";

contract SarcophagusToken is ERC20 {
    constructor(
        uint256 initialBalance,
        string memory name,
        string memory symbol
    ) public ERC20(name, symbol) {
        _mint(msg.sender, initialBalance);
    }
}
