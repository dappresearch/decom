// SPDX-License-Identifier: No License
pragma solidity ^0.8.20;

interface IError {
    error InvalidQuantity(uint256 quantity);

    error InvalidAmount(uint256 amount);

    error AlreadyShipped(uint32 orderNo);

    error WithdrawAmountUnavailable(uint8 amount);

    error InsufficientBuyerPayment(uint256 amount);

    error AlreadyCancelled(uint32 orderNo);

    error InvalidCollector(address buyer);

    error OrderNotCancelled(uint32 orderNo);

    error AlreadyRefund(uint32 orderNo);

    error InValidOrderLength(uint256 orderNo);
}