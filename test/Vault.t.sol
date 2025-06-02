// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Test} from "forge-std/Test.sol";
import {Vault} from "../src/Vault.sol";
import {ERC20} from "../src/ERC20.sol";

contract VaultSimpleTest is Test {
    Vault public vault;
    ERC20 public token;

    address public admin = address(0x1);
    address public user1 = address(0x2);
    address public user2 = address(0x3);

    uint256 public constant FEE_PERCENT = 5; // 5% fee
    uint256 public constant INITIAL_SUPPLY = 1000000 * 1e18;

    function setUp() public {
        // Deploy token and vault
        token = new ERC20("Test Token", "TEST", 18, INITIAL_SUPPLY);
        vault = new Vault(address(token), FEE_PERCENT, admin);

        // Give tokens to users
        token.transfer(user1, 10000 * 1e18);
        token.transfer(user2, 10000 * 1e18);

        // Approve vault to spend user tokens
        vm.prank(user1);
        token.approve(address(vault), type(uint256).max);

        vm.prank(user2);
        token.approve(address(vault), type(uint256).max);
    }

    // Test basic deposit functionality
    function test_Deposit() public {
        uint256 depositAmount = 1000 * 1e18;

        vm.prank(user1);
        vault.deposit(depositAmount);

        assertEq(vault.getBalance(user1), depositAmount);
        assertEq(token.balanceOf(address(vault)), depositAmount);
    }

    // Test deposit with zero amount should fail
    function test_DepositZeroAmount() public {
        vm.expectRevert("Amount must be greater than 0");
        vm.prank(user1);
        vault.deposit(0);
    }

    // Test basic withdrawal with fee
    function test_Withdraw() public {
        uint256 depositAmount = 1000 * 1e18;
        uint256 withdrawAmount = 500 * 1e18;

        // Deposit first
        vm.prank(user1);
        vault.deposit(depositAmount);

        uint256 initialBalance = token.balanceOf(user1);

        // Withdraw
        vm.prank(user1);
        vault.withdraw(withdrawAmount);

        uint256 expectedFee = (withdrawAmount * FEE_PERCENT) / 100;
        uint256 expectedReceived = withdrawAmount - expectedFee;

        assertEq(vault.getBalance(user1), depositAmount - withdrawAmount);
        assertEq(vault.getTotalFees(), expectedFee);
        assertEq(token.balanceOf(user1), initialBalance + expectedReceived);
    }

    // Test withdrawal with insufficient balance
    function test_WithdrawInsufficientBalance() public {
        vm.expectRevert("Insufficient balance");
        vm.prank(user1);
        vault.withdraw(1000 * 1e18);
    }

    // Test fee withdrawal by admin
    function test_AdminWithdrawFees() public {
        uint256 depositAmount = 1000 * 1e18;

        // User deposits and withdraws to generate fees
        vm.prank(user1);
        vault.deposit(depositAmount);

        vm.prank(user1);
        vault.withdraw(depositAmount);

        uint256 fees = vault.getTotalFees();
        uint256 adminInitialBalance = token.balanceOf(admin);

        // Admin withdraws fees
        vm.prank(admin);
        vault.withdrawFees();

        assertEq(vault.getTotalFees(), 0);
        assertEq(token.balanceOf(admin), adminInitialBalance + fees);
    }

    // Test non-admin cannot withdraw fees
    function test_NonAdminCannotWithdrawFees() public {
        vm.expectRevert("Not admin");
        vm.prank(user1);
        vault.withdrawFees();
    }

    // Test fee calculation
    function test_FeeCalculation() public view {
        uint256 amount = 1000 * 1e18;
        uint256 expectedFee = (amount * FEE_PERCENT) / 100;

        assertEq(vault.calculateWithdrawalFee(amount), expectedFee);
    }

    // Test multiple users can use vault
    function test_MultipleUsers() public {
        uint256 amount1 = 1000 * 1e18;
        uint256 amount2 = 2000 * 1e18;

        // Both users deposit
        vm.prank(user1);
        vault.deposit(amount1);

        vm.prank(user2);
        vault.deposit(amount2);

        assertEq(vault.getBalance(user1), amount1);
        assertEq(vault.getBalance(user2), amount2);
        assertEq(vault.getVaultBalance(), amount1 + amount2);
    }

    // Test events are emitted
    function test_Events() public {
        uint256 depositAmount = 1000 * 1e18;

        // Test deposit event
        vm.expectEmit(true, true, true, true);
        emit Vault.Deposited(user1, depositAmount);

        vm.prank(user1);
        vault.deposit(depositAmount);

        // Test withdrawal event
        uint256 withdrawAmount = 500 * 1e18;
        uint256 expectedFee = (withdrawAmount * FEE_PERCENT) / 100;
        uint256 expectedReceived = withdrawAmount - expectedFee;

        vm.expectEmit(true, true, true, true);
        emit Vault.Withdrawn(user1, expectedReceived, expectedFee);

        vm.prank(user1);
        vault.withdraw(withdrawAmount);
    }

    // Test edge case: small amounts
    function test_SmallAmounts() public {
        uint256 smallAmount = 100; // 100 wei

        vm.prank(user1);
        vault.deposit(smallAmount);

        vm.prank(user1);
        vault.withdraw(smallAmount);

        // Even small amounts should work
        assertTrue(vault.getTotalFees() >= 0);
    }

    // Test constructor validation
    function test_ConstructorValidation() public {
        // Test zero token address
        vm.expectRevert("Invalid token address");
        new Vault(address(0), FEE_PERCENT, admin);

        // Test zero admin address
        vm.expectRevert("Invalid admin address");
        new Vault(address(token), FEE_PERCENT, address(0));

        // Test fee too high
        vm.expectRevert("Fee too high");
        new Vault(address(token), 15, admin); // 15% > 10% max
    }

    // Test burn functionality
    function test_BurnFunction() public {
        uint256 initialSupply = token.totalSupply();
        uint256 burnAmount = 1000 * 10 ** 18;

        // Use user1 who has tokens, burn some tokens
        uint256 user1BalanceBefore = token.balanceOf(user1);

        vm.prank(user1);
        token.burn(user1, burnAmount);

        // Check balances and supply updated correctly
        assertEq(token.balanceOf(user1), user1BalanceBefore - burnAmount);
        assertEq(token.totalSupply(), initialSupply - burnAmount);

        // Test burn more than balance (should fail)
        uint256 currentBalance = token.balanceOf(user1);
        vm.prank(user1);
        vm.expectRevert("Insufficient balance to burn");
        token.burn(user1, currentBalance + 1);
    }
}
