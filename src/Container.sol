// SPDX-License-Identifier: No License
pragma solidity ^0.8.20;

enum Status {
        pending,
        shipped,
        cancelled,
        refund
}

struct Order {
        string shippingAddr;
        uint256 quantity;
        uint256 amount;
        address buyerAddr;
        Status status;
}