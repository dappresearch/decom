// SPDX-License-Identifier: No License
pragma solidity ^0.8.20;

enum Status {
        none,
        pending,
        shipped,
        cancelled,
        refund
}

struct Order {
        string shippingAddr;
        uint32 quantity;
        uint256 amount;
        address buyerAddr;
        Status status;
}