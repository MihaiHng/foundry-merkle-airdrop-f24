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

import {IERC20, SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {MerkleProof} from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import {MessageHashUtils} from "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";
import {EIP712} from "@openzeppelin/contracts/utils/cryptography/EIP712.sol";
import {SignatureChecker} from "@openzeppelin/contracts/utils/cryptography/SignatureChecker.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

/*
* @title DecentralizedStableCoin
* @author Mihai Hanga
* 
* This is the contract that conatins all the logic for airdropping the "Bagel Token".
*/

contract MerkleAirdrop is EIP712 {
    using SafeERC20 for IERC20;

    /*//////////////////////////////////////////////////////////////
                               Errors
    //////////////////////////////////////////////////////////////*/

    error MerkleAirdrop__InvalidProof();
    error MerkleAirdrop__AlreadyClaimed();
    error MerkleAirdrop__InvalidSignature();

    /*//////////////////////////////////////////////////////////////
                               State variables
    //////////////////////////////////////////////////////////////*/

    address[] claimers;

    IERC20 private immutable i_airdropToken;
    bytes32 private immutable i_merkleRoot;

    mapping(address claimer => bool) private s_hasClaimed;

    struct AirdropClaim {
        address account;
        uint256 amount;
    }

    bytes32 private constant MESSAGE_TYPEHASH = keccak256("AirdropClaim(address account,uint256 amount)");

    /*//////////////////////////////////////////////////////////////
                               EVENTS
    //////////////////////////////////////////////////////////////*/

    event Claimed(address account, uint256 amount);

    /*//////////////////////////////////////////////////////////////
                               FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    constructor(bytes32 merkleRoot, IERC20 airdropToken) EIP712("Airdrop", "1") {
        i_merkleRoot = merkleRoot;
        i_airdropToken = airdropToken;
    }

    function claim(address account, uint256 amount, bytes32[] calldata merkleProof, uint8 v, bytes32 r, bytes32 s)
        external
    {
        // calculate the leaf by using the account, the amount and the hash
        if (s_hasClaimed[account]) {
            revert MerkleAirdrop__AlreadyClaimed();
        }

        // check the signature
        if (_isValidSignature(account, getMessageHash(account, amount), v, r, s)) {
            revert MerkleAirdrop__InvalidSignature();
        }
        bytes32 leaf = keccak256(bytes.concat(keccak256(abi.encode(account, amount))));
        if (!MerkleProof.verify(merkleProof, i_merkleRoot, leaf)) {
            revert MerkleAirdrop__InvalidProof();
        }
        s_hasClaimed[account] = true; // prevent users claiming more than once and draining the contract
        emit Claimed(account, amount);
        i_airdropToken.safeTransfer(account, amount);
    }

    /*//////////////////////////////////////////////////////////////
                        VIEW AND PURE FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    function getMessageHash(address account, uint256 amount) public view returns (bytes32) {
        return
            _hashTypedDataV4(keccak256(abi.encode(MESSAGE_TYPEHASH, AirdropClaim({account: account, amount: amount}))));
    }

    function _isValidSignature(address signer, bytes32 digest, uint8 v, bytes32 r, bytes32 s)
        internal
        pure
        returns (bool)
    {
        (address actualSigner,,) = ECDSA.tryRecover(digest, v, r, s);
        return (actualSigner == signer);
    }

    function getMerkleRoot() external view returns (bytes32) {
        return i_merkleRoot;
    }

    function getAirdropToken() external view returns (IERC20) {
        return i_airdropToken;
    }
}
