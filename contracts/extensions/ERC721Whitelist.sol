/**
 * Copyright (C) SettleMint NV - All Rights Reserved
 *
 * Use of this file is strictly prohibited without an active subscription.
 * Distribution of this file, via any medium, is strictly prohibited.
 *
 * For license inquiries, contact hello@settlemint.com
 *
 * SPDX-License-Identifier: UNLICENSED
 */
pragma solidity ^0.8.24;

import {Context} from "@openzeppelin/contracts/utils/Context.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import {MerkleProof} from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

abstract contract ERC721Whitelist is Context {
    bytes32 public _whitelistMerkleRoot;

    function _setWhitelistMerkleRoot(bytes32 whitelistMerkleRoot_) internal {
        _whitelistMerkleRoot = whitelistMerkleRoot_;
    }

   function _leaf(
    address account,
    string memory allowance
) internal pure returns (bytes32) {
    return keccak256(abi.encode(account, allowance));
}

function _validateWhitelistMerkleProof(
    uint256 allowance,
    bytes32[] calldata proof
) internal view returns (bool) {
    bytes32 leaf = _leaf(_msgSender(), Strings.toString(allowance));
    return MerkleProof.verify(proof, _whitelistMerkleRoot, leaf);
}

    function _verify(
        bytes32 leaf,
        bytes32[] memory proof
    ) internal view returns (bool) {
        require(_whitelistMerkleRoot != 0, "Whitelist merkle root not set");
        return MerkleProof.verify(proof, _whitelistMerkleRoot, leaf);
    }

    function getAllowance(
        string memory allowance,
        bytes32[] calldata proof
    ) public view returns (string memory) {
        require(
            _verify(_leaf(msg.sender, allowance), proof),
            "Invalid Merkle Tree proof supplied."
        );
        return allowance;
    }


    function _disableWhitelistMerkleRoot() internal {
        delete _whitelistMerkleRoot;
    }
}
