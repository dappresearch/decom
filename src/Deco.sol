// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";

contract Deco is Ownable {

    uint32 public totalStock;

    // track number of orders
    uint32 public orderNo;

    uint256 public shippingCost;

    // single price
    uint256 public price;

    // revenue generted after fulfilling shipping
    uint256 revenueAfterShipping;

    constructor(address owner) Ownable(owner) {

    }

    struct Order {
        string trackingNo;
        string shippingAddr;
        uint256 quantity;
        uint256 amount;
        address buyerAddr;
        bool isShipped;
        bool cancelAndRefund;
    }

    // store buyer orders
    mapping(address => uint256[]) buyersOrder;

    mapping(address => uint256) payments;

    mapping (uint32 => Order) orders;

    uint256 totalPayment;

    function setStock(uint32 newTotalStock) external onlyOwner {
        totalStock = newTotalStock;
    }

    function setPrice(uint256 newPrice) external onlyOwner {
        price = newPrice;
    }

    function setShippingCost(uint256 newShippingCost) external onlyOwner {
        shippingCost = newShippingCost;
    }

    function purchase(uint8 quantity, string memory destination) external payable {
        require(quantity > 0 && quantity <= totalStock, "Invalid quantity");
        require(msg.value == price * quantity, "Incorrect payment amount");

        uint256 amount = msg.value;
        Order storage order = orders[orderNo++];
        order.shippingAddr = destination;
        order.quantity = quantity;
        order.amount = amount;
        order.buyerAddr = msg.sender;

        // record the amount of payment by the buyer
        payments[msg.sender] += amount;
        buyersOrder[msg.sender].push(orderNo);

        // overflow not possible, quantity <= stock, already checked.
        unchecked {
            totalStock -= quantity;
        }
    }
    
    function processShipment(uint32 _orderNum, string memory trackingNo) external onlyOwner {
        Order storage order = orders[_orderNum];
        require(!order.isShipped, "Already Shipped");
        require(bytes(order.trackingNo).length == 0, "Tracking Number already set");

        order.isShipped = true;
        //  check the tracking number from the system.
        order.trackingNo = trackingNo;
        revenueAfterShipping += order.amount;
    }

    // Update tracking number incase of problem
    function updateTrackingNo(uint32 _orderNo, string memory trackingNo) external onlyOwner {
        Order storage order = orders[_orderNo];
        require(order.isShipped, "Use UpdateShipMent method");
        order.trackingNo = trackingNo;
    }

    // Only able to withdraw for shipped items.
    function withdraw(address receiver) external onlyOwner {
        require(revenueAfterShipping > 0, "Insufficient Revenue");
        payable(receiver).transfer(revenueAfterShipping);
        revenueAfterShipping = 0;
    }

    // set cancel multiple orderNo
    // be aware of loop.
    function setCancelAndRefund(uint32 _orderNo) external onlyOwner {
        Order storage order = orders[_orderNo];
        require(!order.isShipped, "Already Shipped");
        require(order.amount > 0, "Buyers need to pay");
        order.cancelAndRefund = true;
    }

    // for safety reason only 20 loops is allowed
    function setCancelAndRefund(uint32[] calldata _ordersNo) external onlyOwner {
        require(_ordersNo.length <= 20, "Maximum length");
        for(uint8 i=0; i<_ordersNo.length; i++) {
            Order storage order = orders[_ordersNo[i]];
            require(!order.isShipped, "Already Shipped");
            require(order.amount > 0, "Buyers need to pay");
            order.cancelAndRefund = true;
        }
    }
    
    // Think something about order Number
    // It needs reentrance guard
    function collectRefund(uint32 _orderNo) external {
        Order memory order = orders[_orderNo];
        require(!order.isShipped && order.cancelAndRefund, "Invalid refund");
        require(msg.sender == order.buyerAddr);
        totalPayment -= order.amount;
        uint256 amount = order.amount;
        order.amount = 0;
        payable(msg.sender).transfer(amount);
    }
    
}


    // Need reentrant guard.
    // Do not make too much complex.
    // function refund(uint32 _orderNum) external onlyOwner {
    //     Order memory order = orders[_orderNum];
        
    //     address currentBuyer = order.buyerAddr;

    //     uint256 buyerPayment = payments[currentBuyer];

    //     require(!order.isShipped && !order.cancelAndRefund, "Invalid refund");

    //     require(buyerPayment > 0 && buyerPayment >= order.quantity * price, "Insufficent buyers amount");

    //     payments[currentBuyer] -= 
    //     // Function to transfer Ether from this contract to address from input
    //     //(bool success,) = _to.call{value: _amount}("");
    // }


    // // orders => address mapping
    // // addre
    // // Basically good idea to group the orders and link that.
    // function purchase(uint8 quantity, string memory destination) external payable {
    //     require(quantity > 0 && quantity <= stock, "Invalid quantity");

    //     uint256 amount = msg.value;

    //     require(amount == price * quantity, "Incorrect payment amount");

    //     // overflow not possible, quantity <= stock, already checked.
    //     unchecked {
    //         stock -= quantity;
    //     }

    //     // record the amount of payment by the buyer
    //     paid[msg.sender] += amount;
    // }

    // // Set tracking number from the email address.
    // function updateShipment(uint256 tokenId, string memory trackingNo) external onlyOwner {
    //         ShipDetails storage sd = shipping[tokenId];

    //         require(!sd.isShipped, "Already Shipped");

    //         sd.isShipped = true;
    //         //  check the tracking number from the system.
    //         sd.trackingNo = trackingNo;
    // }

    // function setPrice(uint256 amount) external onlyOwner {
    //     price = amount;
    // }

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
