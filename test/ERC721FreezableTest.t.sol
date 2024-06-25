// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "../contracts/extensions/ERC721Freezable.sol";

contract ERC721FreezableTest is Test {
    ERC721FreezableMock freezable;

    address owner = address(1);
    address user = address(2);

    event PermanentURI(string _value, uint256 indexed _id);

    function setUp() public {
        vm.startPrank(owner);
        freezable = new ERC721FreezableMock();
        vm.stopPrank();
    }

    function testInitialFrozenState() public {
        assertFalse(freezable.frozen(), "Initial state should not be frozen");
    }

    function testFreezeURI() public {
        vm.startPrank(owner);
        freezable.freeze();
        assertTrue(
            freezable.frozen(),
            "URI should be frozen after calling freeze"
        );
        vm.stopPrank();
    }

    function testUpdateEmitsPermanentURIWhenFrozen() public {
        vm.startPrank(owner);
        freezable.mint(user, 1);
        freezable.freeze();
        vm.expectEmit(true, true, true, true);
        emit PermanentURI(freezable.tokenURI(1), 1);
        vm.stopPrank();
        vm.prank(user);
        freezable.update(user, 1, address(0));
    }

    function testFreezeToken() public {
        vm.startPrank(owner);
        freezable.mint(user, 1);
        freezable.freeze();
        vm.expectEmit(true, true, true, true);
        emit PermanentURI(freezable.tokenURI(1), 1);
        freezable.freezeToken(1);
        vm.stopPrank();
    }

    function testFreezeAllTokens() public {
        vm.startPrank(owner);
        freezable.mint(user, 1);
        freezable.mint(user, 2);
        freezable.freeze();
        vm.expectEmit(true, true, true, true);
        emit PermanentURI(freezable.tokenURI(1), 1);
        emit PermanentURI(freezable.tokenURI(2), 2);
        freezable.freezeAllTokens();
        vm.stopPrank();
    }
}

// Mock contract for testing
contract ERC721FreezableMock is ERC721Freezable {
    uint256 private _tokenId;
    string private _baseTokenURI;

    constructor() ERC721("Freezable Token", "FTK") {}

    function mint(address to, uint256 tokenId) public {
        _mint(to, tokenId);
    }

    function freeze() public {
        _freeze();
    }

    function setBaseURI(string memory baseTokenURI_) public {
        _baseTokenURI = baseTokenURI_;
    }

    function _baseURI() internal view override returns (string memory) {
        return _baseTokenURI;
    }

    function tokenURI(
        uint256 tokenId
    ) public view override returns (string memory) {
        string memory baseURI = _baseURI();
        return
            bytes(baseURI).length > 0
                ? string(abi.encodePacked(baseURI, "/", tokenId))
                : "";
    }

    function update(
        address to,
        uint256 tokenId,
        address auth
    ) public returns (address) {
        return _update(to, tokenId, auth);
    }
}
