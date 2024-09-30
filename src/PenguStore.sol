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

    constructor(address owner) Ownable(owner) {

    }
    
    struct Order {
        string shippingAddr;
        uint256 quantity;
        uint256 amount;
        address buyerAddr;
        bool isShipped;
        bool cancelAndRefund;
    }

    // store buyer orders
    mapping(address => uint256[]) public buyersOrder;

    mapping (uint32 => Order) orders;

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
    function purchase(uint32 quantity, string memory destination) external payable {
        if(quantity == 0 || quantity > totalStock) revert InvalidQuantity(quantity);

        if(msg.value != totalCost(quantity)) revert InvalidAmount(msg.value);

        uint256 amount = msg.value;
        Order storage order = orders[orderNo];
        order.shippingAddr = destination;
        order.quantity = quantity;
        order.amount = amount;
        order.buyerAddr = msg.sender;

        // Record the payment sent by the buyers.
        payments[msg.sender] += amount;
        buyersOrder[msg.sender].push(orderNo);

        totalPayment += msg.value;

        // overflow not possible, quantity <= stock, already checked.
        unchecked {
            totalStock -= quantity;
        }
        
        orderNo++;
    }

    function getOrderDetails(uint32 _orderNum) external view returns (
        string memory shippingAddr,
        uint256 quantity,
        uint256 amount,
        address buyerAddr,
        bool isShipped,
        bool cancelAndRefund
    ){
        Order memory order = orders[_orderNum];

        return (
            order.shippingAddr,
            order.quantity,
            order.amount,
            order.buyerAddr,
            order.isShipped,
            order.cancelAndRefund
        );
    }

    //Need to track the buyer balance
    function processShipment(uint32 _orderNum) external onlyOwner {
        Order storage order = orders[_orderNum];
        require(!order.isShipped, "Already Shipped");
        order.isShipped = true;
        
        amountAfterShipping += order.amount;
    }

    // Need to process multiple payment
    // This is important.
    // Only able to withdraw for shipped items
    function withdraw(address receiver) external onlyOwner {
        uint256 withdrawAmount = amountAfterShipping;

        require(amountAfterShipping > 0, "Insufficient Revenue");

        totalWithdraw += amountAfterShipping;
        amountAfterShipping = 0;

        payable(receiver).transfer(withdrawAmount);
    }

    // set cancel multiple orderNo
    // be aware of loop.+
    function setCancelAndRefund(uint32 _orderNo) external onlyOwner {
        Order storage order = orders[_orderNo];
        require(!order.isShipped, "Already Shipped");
        require(order.amount > 0 && payments[msg.sender] >= order.amount, "Buyers need to pay");
        order.cancelAndRefund = true;
    }

    // for safety reason only 20 loops is allowed
    function setCancelAndRefund(uint32[] calldata _ordersNo) external onlyOwner {
        require(_ordersNo.length <= 20, "Maximum length");
        for(uint8 i=0; i<_ordersNo.length; i++) {
            Order storage order = orders[_ordersNo[i]];
            require(!order.isShipped, "Already Shipped");
            require(order.amount > 0 && payments[msg.sender] >= order.amount, "Buyers need to pay");
            order.cancelAndRefund = true;
        }
    }
    
    // Think something about order Number
    // It needs reentrance guard
    function collectRefund(uint32 _orderNo) external {
        Order memory order = orders[_orderNo];

        // buyer shoule be caller
        require(msg.sender == order.buyerAddr, "Caller should be buyer");
        
        // order should not be shipped
        // orderNumber should be to set to cancelAndRefund
        require(!order.isShipped && order.cancelAndRefund, "Invalid refund");

        // must have valid payment
        // totalPayment is not necessary important here
        require(payments[msg.sender] >= order.amount && totalPayment >= order.amount, "Incorrect payment request");

        uint256 amount = order.amount;
        
        unchecked {
            totalPayment -= order.amount;
            payments[msg.sender] -= order.amount;
        }
        
        order.amount = 0;
        
        //delete order
        delete orders[_orderNo];

        // remove the payment
        payable(msg.sender).transfer(amount);
    }

    // Returns the orde array
    function getOrder(address buyer) external view returns (uint256[] memory) {
        return buyersOrder[buyer];
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
