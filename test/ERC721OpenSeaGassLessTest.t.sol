// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "../contracts/extensions/ERC721OpenSeaGassLess.sol"; // Adjust the import path as necessary

contract ERC721Mock is ERC721OpenSeaGassLess {
    constructor(address proxyRegistryAddress_)
        ERC721OpenSeaGassLess(proxyRegistryAddress_)
        ERC721("MockERC721", "M721")
    { }

    function mint(address to, uint256 tokenId) external {
        _mint(to, tokenId);
    }

    function setProxyRegistryAddress(address proxyRegistryAddress_) external {
        _setProxyRegistryAddress(proxyRegistryAddress_);
    }
}

contract OpenSeaProxyRegistryMock is OpenSeaProxyRegistry {
    function setProxy(address owner, OwnableDelegateProxy proxy) external {
        proxies[owner] = proxy;
    }
}

contract ERC721OpenSeaGassLessTest is Test {
    ERC721Mock private erc721Mock;
    OpenSeaProxyRegistryMock private proxyRegistryMock;
    OwnableDelegateProxy private delegateProxy;
    address private owner;
    address private operator;

    function setUp() public {
        proxyRegistryMock = new OpenSeaProxyRegistryMock();
        erc721Mock = new ERC721Mock(address(proxyRegistryMock));
        delegateProxy = new OwnableDelegateProxy();
        owner = address(this);
        operator = address(0x123);

        // Mint a token to the owner
        erc721Mock.mint(owner, 1);
    }

    function testIsApprovedForAllWithoutProxy() public {
        // Without setting the proxy, isApprovedForAll should return false
        bool approved = erc721Mock.isApprovedForAll(owner, operator);
        assertEq(approved, false);
    }

    function testIsApprovedForAllWithProxy() public {
        // Set the proxy for the owner
        proxyRegistryMock.setProxy(owner, delegateProxy);

        // Now isApprovedForAll should return true for the proxy address
        bool approved = erc721Mock.isApprovedForAll(owner, address(delegateProxy));
        assertEq(approved, true);
    }

    function testSetProxyRegistryAddress() public {
        // Test setting a new proxy registry address
        address newProxyRegistry = address(0x456);
        erc721Mock.setProxyRegistryAddress(newProxyRegistry);
        assertEq(erc721Mock._proxyRegistryAddress(), newProxyRegistry);
    }
}
