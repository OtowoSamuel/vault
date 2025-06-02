// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Script, console} from "forge-std/Script.sol";
import {Vault} from "../src/Vault.sol";
import {MockERC20} from "../src/MockERC20.sol";

contract VaultDeployScript is Script {
    function run() public {
        vm.startBroadcast();

        // Deploy a test token
        MockERC20 token = new MockERC20(
            "Test Token",
            "TEST",
            18,
            1000000 * 1e18 // 1 million tokens
        );

        // Deploy vault with 5% withdrawal fee
        Vault vault = new Vault(
            address(token),
            5, // 5% fee
            msg.sender // deployer as admin
        );

        console.log("Token deployed at:", address(token));
        console.log("Vault deployed at:", address(vault));
        console.log("Admin:", vault.admin());
        console.log("Withdrawal fee:", vault.withdrawalFeePercent(), "%");

        vm.stopBroadcast();
    }
}
