// SPDX-License-Identifier: MIT

// Layout of Contract:
// version
// imports
// interfaces, libraries, contracts
// errors
// Type declarations
// State variables
// Events
// Modifiers
// Functions

// Layout of Functions:
// constructor
// receive function (if exists)
// fallback function (if exists)
// external
// public
// internal
// private
// view & pure functions

pragma solidity ^0.8.24;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

/*
* @title Merkle Airdrop
* @author Mihai Hanga
* 
* This is the contract that implements a basic functionality ERC20 token, called "Bagel Token".
*/

contract BagelToken is ERC20, Ownable {
    constructor() ERC20("BagelToken", "BT") Ownable(msg.sender) {}

    function mint(address account, uint256 amount) external onlyOwner {
        _mint(account, amount);
    }
}
