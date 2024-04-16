// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Script.sol";
import "../src/MetaDog.sol";

contract PublicSaleScript is Script {
    function run() public {
        vm.startBroadcast(); // Begin broadcasting transactions

        address tokenAddress = vm.envAddress("TOKEN_ADDRESS");
        string memory revealTokenURI = vm.envString("REVEAL_TOKEN_URI");

        MetaDog token = MetaDog(tokenAddress); // Use the provided token address

        token.setBaseURI(string(abi.encodePacked("ipfs://", revealTokenURI, "/")));

        console.log("baseURI set: ", "ipfs://", revealTokenURI);

        // Check if the token is frozen
        if (!token.frozen()) {
            console.log("Token is not frozen, freezing now...");
            token.freeze();
        } else {
            console.log("Token is already frozen.");
        }

        // Freeze all tokens with specified gas limit
        console.log("Freezing all tokens...");
        token.freezeAllTokens{ gas: 400_000 }();

        vm.stopBroadcast(); // End broadcasting transactions
    }
}
