// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "forge-std/Test.sol";
import "../contracts/MetaDog.sol";
import "forge-std/console.sol";

contract MetaDogTest is Test {
    MetaDog exampleERC721;
    address owner = address(1);
    address other = address(2);
    address proxyRegistryAddress = address(0);
    address payable wallet = payable(address(3));

    string baseURLPlaceholder =
        "ipfs://bafybeifc23vyo52i6dtlba7u7kmbcpc5oxfcwjaz3oisagq3kq7i2dbo6q/";
    string baseTokenURI =
        "ipfs://bafybeifc23vyo52i6dtlba7u7kmbcpc5oxfcwjaz3oisagq3kq7i2dbo6q/1.json";
    string baseURLRevealed =
        "ipfs://bafybeihxsckb6gl6yzyn4sjwyspf2lldlhmxo7usqebkdvol2l6uehryei/";
    string revealedTokenURI =
        "ipfs://bafybeihxsckb6gl6yzyn4sjwyspf2lldlhmxo7usqebkdvol2l6uehryei/1.json";

    function setUp() public {
        vm.startPrank(owner);
        exampleERC721 = new MetaDog(
            "Example Token",
            "EXT",
            baseURLPlaceholder,
            proxyRegistryAddress,
            wallet
        );
        vm.stopPrank();
    }

    function testDeployment() public {
        assertEq(exampleERC721.name(), "Example Token");
        assertEq(exampleERC721.symbol(), "EXT");
        assertEq(exampleERC721.wallet(), wallet);
        assertEq(exampleERC721.owner(), owner);
    }

    function testCollectReserves() public {
        vm.prank(owner);
        exampleERC721.collectReserves();

        for (uint256 i = 1; i <= exampleERC721.RESERVES(); i++) {
            assertEq(exampleERC721.ownerOf(i), wallet);
        }
    }

    function testGift() public {
        vm.startPrank(owner);
        exampleERC721.collectReserves();
        address[] memory giftedAddress = new address[](1);
        giftedAddress[0] = 0x15d34AAf54267DB7D7c367839AAf71A00a2C6A65;
        exampleERC721.gift(giftedAddress);
        assertEq(
            exampleERC721.balanceOf(0x15d34AAf54267DB7D7c367839AAf71A00a2C6A65),
            1
        );
    }

    function testWhitelistMint() public {
        vm.prank(owner);
        exampleERC721.collectReserves();

        vm.prank(owner);
        exampleERC721.setWhitelistMerkleRoot(
            0xbc56477505b21fd7409dbc693cf9a006e29ec44e460308c25437bb647c3effb3
        );
        bytes32[] memory proofOne = new bytes32[](1);
        proofOne[
            0
        ] = 0xf2e82b3a90979175611bdde3e3ad666497bf331847d930e33a91a3602a44875b;
        uint256 count = 2;
        uint256 allowance = 2;
        vm.deal(
            0x15d34AAf54267DB7D7c367839AAf71A00a2C6A65,
            exampleERC721.PRICE_IN_WEI_WHITELIST() * count
        );
        vm.startPrank(0x15d34AAf54267DB7D7c367839AAf71A00a2C6A65);
        exampleERC721.whitelistMint{
            value: exampleERC721.PRICE_IN_WEI_WHITELIST() * count
        }(count, allowance, proofOne);

        assertEq(
            exampleERC721.balanceOf(0x15d34AAf54267DB7D7c367839AAf71A00a2C6A65),
            count
        );
        vm.stopPrank();
    }

    function testWhitelistMintFailsWithInvalidProof() public {
        vm.prank(owner);
        exampleERC721.collectReserves();

        vm.prank(owner);
        exampleERC721.setWhitelistMerkleRoot(
            0xbc56477505b21fd7409dbc693cf9a006e29ec44e460308c25437bb647c3effb3
        );
        bytes32[] memory invalidProof = new bytes32[](1); // Use an invalid proof here
        invalidProof[
            0
        ] = 0xf2e82b3a90979175611bdde3e3ad666497bf331847d930e33a91a3602a44875b;
        uint256 count = 1;
        uint256 allowance = 2;
        vm.deal(
            0x9965507D1a55bcC2695C58ba16FB37d819B0A4dc,
            exampleERC721.PRICE_IN_WEI_WHITELIST() * count
        );
        vm.expectRevert("Invalid Merkle Tree proof supplied");
        vm.prank(0x9965507D1a55bcC2695C58ba16FB37d819B0A4dc);
        exampleERC721.whitelistMint(count, allowance, invalidProof);
    }

    function testPublicSale() public {
        vm.startPrank(owner);
        exampleERC721.collectReserves();
        exampleERC721.startPublicSale();
        vm.stopPrank();
        address buyer = address(1);
        vm.deal(buyer, exampleERC721.PRICE_IN_WEI_PUBLIC());
        vm.startPrank(buyer);
        exampleERC721.publicMint{value: exampleERC721.PRICE_IN_WEI_PUBLIC()}(1);
        assertEq(exampleERC721.balanceOf(buyer), 1);
        vm.stopPrank();
    }

    function testWithdrawFunds() public {
        vm.startPrank(owner);
        exampleERC721.collectReserves();
        exampleERC721.startPublicSale();
        vm.stopPrank();
        address buyer = address(1);
        vm.deal(buyer, exampleERC721.PRICE_IN_WEI_PUBLIC());
        vm.startPrank(buyer);
        exampleERC721.publicMint{value: exampleERC721.PRICE_IN_WEI_PUBLIC()}(1);
        assertEq(exampleERC721.balanceOf(buyer), 1);
        vm.stopPrank();
        uint256 contractBalance = address(exampleERC721).balance;
        uint256 walletBalanceBefore = wallet.balance;
        exampleERC721.withdraw();
        uint256 walletBalanceAfter = wallet.balance;
        assertEq(walletBalanceAfter, walletBalanceBefore + contractBalance);
    }

    function testReveal() public {
        vm.startPrank(owner);
        exampleERC721.collectReserves();
        exampleERC721.startPublicSale();
        assertEq(exampleERC721.tokenURI(1), baseTokenURI);
        exampleERC721.setBaseURI(baseURLRevealed);
        assertEq(exampleERC721.tokenURI(1), revealedTokenURI);
        vm.stopPrank();
    }

    function testBurn() public {
        vm.startPrank(owner);
        exampleERC721.collectReserves();
        exampleERC721.startPublicSale();
        vm.stopPrank();
        address buyer = address(1);
        vm.deal(buyer, exampleERC721.PRICE_IN_WEI_PUBLIC());
        vm.startPrank(buyer);
        exampleERC721.publicMint{value: exampleERC721.PRICE_IN_WEI_PUBLIC()}(1);
        assertEq(exampleERC721.balanceOf(buyer), 1);
        exampleERC721.burn(6); // burning 6 since 5 tokens are reserved
        assertEq(exampleERC721.balanceOf(buyer), 0);
        vm.stopPrank();
    }
}
