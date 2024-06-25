// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "../contracts/extensions/ERC721Batch.sol";

contract ERC721BatchTest is Test {
    ERC721Mock private erc721Mock;
    address private owner;
    address private recipient;

    function setUp() public {
        erc721Mock = new ERC721Mock();
        owner = address(this);
        recipient = address(0x123);

        // Mint some tokens to the owner
        erc721Mock.mint(owner, 1);
        erc721Mock.mint(owner, 2);
        erc721Mock.mint(owner, 3);
    }

    function testBatchTransferFrom() public {
        uint256[] memory tokenIds = new uint256[](3);
        tokenIds[0] = 1;
        tokenIds[1] = 2;
        tokenIds[2] = 3;

        // Approve the contract to transfer tokens on behalf of the owner
        for (uint256 i = 0; i < tokenIds.length; i++) {
            erc721Mock.approve(address(this), tokenIds[i]);
        }

        // Perform the batch transfer
        erc721Mock.batchTransferFrom(owner, recipient, tokenIds);

        // Check ownership of the tokens
        for (uint256 i = 0; i < tokenIds.length; i++) {
            assertEq(erc721Mock.ownerOf(tokenIds[i]), recipient);
        }
    }

    function testBatchSafeTransferFrom() public {
        uint256[] memory tokenIds = new uint256[](3);
        tokenIds[0] = 1;
        tokenIds[1] = 2;
        tokenIds[2] = 3;

        // Approve the contract to transfer tokens on behalf of the owner
        for (uint256 i = 0; i < tokenIds.length; i++) {
            erc721Mock.approve(address(this), tokenIds[i]);
        }

        // Perform the batch safe transfer
        erc721Mock.batchSafeTransferFrom(owner, recipient, tokenIds, "");

        // Check ownership of the tokens
        for (uint256 i = 0; i < tokenIds.length; i++) {
            assertEq(erc721Mock.ownerOf(tokenIds[i]), recipient);
        }
    }
}

contract ERC721Mock is ERC721Batch {
    constructor() ERC721("MockERC721", "M721") {}

    function mint(address to, uint256 tokenId) external {
        _mint(to, tokenId);
    }
}
