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
pragma solidity ^0.8.17;

import { ERC721 } from "@openzeppelin/contracts/token/ERC721/ERC721.sol";

abstract contract ERC721MintPausable is ERC721 {
    bool private _mintingPaused;

    event MintPaused(address account);
    event MintUnpaused(address account);

    modifier whenMintNotPaused() {
        require(!mintPaused(), "ERC721MintPausable: Mint paused");
        _;
    }

    modifier whenMintPaused() {
        require(mintPaused(), "ERC721MintPausable: Mint not paused");
        _;
    }

    constructor() {
        _mintingPaused = false;
    }

    function mintPaused() public view returns (bool) {
        return _mintingPaused;
    }

    function _pauseMint() internal virtual whenMintNotPaused {
        _mintingPaused = true;
    }

    function _unpauseMint() internal virtual whenMintPaused {
        _mintingPaused = false;
    }

    function _update(address to, uint256 tokenId, address auth) internal virtual override(ERC721) returns (address) {
        address from = super._update(to, tokenId, auth);
        require((!mintPaused() || from != address(0)), "ERC721MintPausable: Minting is disabled");
        return from;
    }
}
