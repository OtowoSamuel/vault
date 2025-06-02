// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {ERC20} from "./ERC20.sol";

contract Vault {
    ERC20 public token;
    address public admin;
    uint256 public withdrawalFeePercent; // Fee percentage (5%)

    mapping(address => uint256) public userBalances;
    uint256 public totalFees;

    event Deposited(address user, uint256 amount);
    event Withdrawn(address user, uint256 amount, uint256 fee);
    event FeesWithdrawn(uint256 amount);

    constructor(address _token, uint256 _feePercent, address _admin) {
        require(_token != address(0), "Invalid token address");
        require(_admin != address(0), "Invalid admin address");
        require(_feePercent <= 10, "Fee too high"); // Max 10%

        token = ERC20(_token);
        withdrawalFeePercent = _feePercent;
        admin = _admin;
    }

    modifier onlyAdmin() {
        require(msg.sender == admin, "Not admin");
        _;
    }

    // Deposit tokens into the vault
    function deposit(uint256 amount) external {
        require(amount > 0, "Amount must be greater than 0");
        require(token.transferFrom(msg.sender, address(this), amount), "Transfer failed");

        userBalances[msg.sender] += amount;
        emit Deposited(msg.sender, amount);
    }

    // Withdraw tokens with fee deduction
    function withdraw(uint256 amount) external {
        require(amount > 0, "Amount must be greater than 0");
        require(userBalances[msg.sender] >= amount, "Insufficient balance");

        uint256 fee = (amount * withdrawalFeePercent) / 100;
        uint256 amountAfterFee = amount - fee;

        userBalances[msg.sender] -= amount;
        totalFees += fee;

        require(token.transfer(msg.sender, amountAfterFee), "Transfer failed");
        emit Withdrawn(msg.sender, amountAfterFee, fee);
    }

    // Admin function to withdraw accumulated fees
    function withdrawFees() external onlyAdmin {
        require(totalFees > 0, "No fees to withdraw");

        uint256 fees = totalFees;
        totalFees = 0;

        require(token.transfer(admin, fees), "Transfer failed");
        emit FeesWithdrawn(fees);
    }

    // View functions for transparency
    function getBalance(address user) external view returns (uint256) {
        return userBalances[user];
    }

    function getTotalFees() external view returns (uint256) {
        return totalFees;
    }

    function calculateWithdrawalFee(uint256 amount) external view returns (uint256) {
        return (amount * withdrawalFeePercent) / 100;
    }

    function getVaultBalance() external view returns (uint256) {
        return token.balanceOf(address(this));
    }
}
