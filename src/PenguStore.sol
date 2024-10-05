// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "forge-std/console.sol";

// Need to figure out what to sell
// This is important

// Shippin cost for the cap

// When to use calldata vs memory
contract PenguStore is Ownable {
    error InvalidQuantity(uint256 quantity);

    error InvalidAmount(uint256 amount);

    error AlreadyShipped(uint32 orderNo);

    error WithdrawAmountUnavailable(uint8 amount);

    error InsufficientBuyerPayment(uint256 amount);

    error AlreadyCancelled(uint32 orderNo);

    error InvalidCollector(address buyer);

    error OrderNotCancelled(uint32 orderNo);

    error AlreadyRefund(uint32 orderNo);

    // no of stock availale for sale
    uint32 public totalStock;

    // track number of orders
    uint32 public orderNo;

    uint256 public shippingCost;

    // single price
    uint256 public price;

    uint256 public totalPayment;

    uint256 public totalWithdraw;

    // revenue generted after fulfilling shipping
    uint256 public amountAfterShipping;

    enum Status {
        pending,
        shipped,
        cancelled,
        refund
    }

    constructor(address owner) Ownable(owner) {}

    struct Order {
        string shippingAddr;
        uint256 quantity;
        uint256 amount;
        address buyerAddr;
        Status status;
    }

    // store buyer orders
    mapping(address => uint32[]) public buyersOrder;

    mapping(uint32 => Order) orders;

    mapping(address => uint256) public payments;

    function setStock(uint32 newTotalStock) external onlyOwner {
        totalStock = newTotalStock;
    }

    function setPrice(uint256 newPrice) external onlyOwner {
        price = newPrice;
    }

    function setShippingCost(uint256 newShippingCost) external onlyOwner {
        shippingCost = newShippingCost;
    }

    // need to properly calculate shipping cost
    function totalCost(uint32 quantity) public view returns (uint256) {
        return ((price * quantity) + shippingCost);
    }

    // Need to figure out accurate cost of the shipping
    function purchase(
        uint32 quantity,
        string memory destination
    ) external payable {
        if (quantity == 0 || quantity > totalStock)
            revert InvalidQuantity(quantity);

        if (msg.value != totalCost(quantity)) revert InvalidAmount(msg.value);

        uint256 amount = msg.value;
        Order storage order = orders[orderNo];
        order.shippingAddr = destination;
        order.quantity = quantity;
        order.amount = amount;
        order.buyerAddr = msg.sender;
        order.status = Status.pending;

        // Record the payment sent by the buyers.
        payments[msg.sender] += amount;
        buyersOrder[msg.sender].push(orderNo);

        // overflow not possible, totalStock > stock, already checked.
        // msg.value <= (totalStock * price) + shippingCost.
        unchecked {
            totalStock -= quantity;
            totalPayment += msg.value;
            orderNo++;
        }
    }

    //Need to track the buyer balance
    function processShipment(uint32 _orderNo) external onlyOwner {
        Order storage order = orders[_orderNo];

        if (order.status == Status.shipped) revert AlreadyShipped(_orderNo);

        order.status = Status.shipped;

        unchecked {
            amountAfterShipping += order.amount;
        }
    }

    // Need to process multiple payment
    // This is important.
    // Only able to withdraw for shipped items
    function withdraw() external onlyOwner {
        uint256 withdrawAmount = amountAfterShipping;

        if (amountAfterShipping == 0) revert WithdrawAmountUnavailable(0);

        unchecked {
            totalWithdraw += amountAfterShipping;
        }

        amountAfterShipping = 0;

        // (bool success, ) = payable(getOwner).call{value: withdrawAmount}("");
        payable(owner()).transfer(withdrawAmount);
    }

    // set cancel multiple orderNo
    // be aware of loop.+
    // Cannot return once the item has been shipped.
    function setCancelAndRefund(uint32 _orderNo) external onlyOwner {
        Order storage order = orders[_orderNo];

        if (order.status == Status.shipped) revert AlreadyShipped(_orderNo);

        if(order.status == Status.refund) revert AlreadyRefund(_orderNo);

        if (order.status == Status.cancelled) revert AlreadyCancelled(_orderNo);

        if (order.amount == 0 || payments[order.buyerAddr] > order.amount)
            revert InsufficientBuyerPayment(_orderNo);

        order.status = Status.cancelled;
    }

    // for safety reason only 20 loops is allowed
    function setCancelAndRefund(
        uint32[20] calldata _ordersNo
    ) external onlyOwner {
        for (uint8 i = 0; i < _ordersNo.length; i++) {
            Order storage order = orders[_ordersNo[i]];
                if (order.status == Status.shipped) revert AlreadyShipped(i);
                if(order.status == Status.refund) revert AlreadyRefund(i);
                if (order.status == Status.cancelled) revert AlreadyCancelled(i);

            if (order.amount == 0 || payments[order.buyerAddr] > order.amount)
                revert InsufficientBuyerPayment(i);
                order.status = Status.cancelled;
        }
    }

    // Think something about order Number
    // It needs reentrance guard
    function collectRefund(uint32 _orderNo) external {
        Order storage order = orders[_orderNo];

        if(msg.sender != order.buyerAddr) revert InvalidCollector(msg.sender);

        if (order.amount == 0 || payments[order.buyerAddr] > order.amount)
            revert InsufficientBuyerPayment(_orderNo);
            
        if (order.status == Status.shipped) revert AlreadyShipped(_orderNo);

        if(order.status != Status.cancelled) revert OrderNotCancelled(_orderNo);

        uint256 refundAmount = order.amount;

        unchecked {
            totalPayment -= order.amount;
            payments[msg.sender] -= order.amount;
        }

        order.amount = 0;
        order.status = Status.refund;
        
        payable(msg.sender).transfer(refundAmount);
    }

    // Returns the orde array
    function getOrder(address buyer) external view returns (uint32[] memory) {
        return buyersOrder[buyer];
    }

    function getOrderDetails(
        uint32 _orderNum
    )
        external
        view
        returns (Order memory)
    {
        Order memory order = orders[_orderNum];
        return order;
    }
}

// How to contact a buyer if there is a shipping problem?
// function uri(uint256 tokenId) override public view returns (string memory) {
//     return string(
//     abi.encodePacked(
//         LINK,
//         Strings.toString(tokenId),
//         ".json"
//     )
//     );
// }

// string LINK = "https://bafybeiaium7ra2ho4zsdf6ix3t6waynpv2yuhmetd4ndeksd7xr5cqgezy.ipfs.nftstorage.link/";
