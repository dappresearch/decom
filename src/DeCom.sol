// SPDX-License-Identifier: No License
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

import "forge-std/console.sol";

import {PriceFeedV3} from "./PriceFeedV3.sol";


contract DeCom is Ownable, ReentrancyGuard {
    error InvalidQuantity(uint256 quantity);

    error InvalidAmount(uint256 amount);

    error AlreadyShipped(uint32 orderNo);

    error WithdrawAmountUnavailable(uint8 amount);

    error InsufficientBuyerPayment(uint256 amount);

    error AlreadyCancelled(uint32 orderNo);

    error InvalidCollector(address buyer);

    error OrderNotCancelled(uint32 orderNo);

    error AlreadyRefund(uint32 orderNo);

    // No of total stock available for sale
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

    PriceFeedV3 public priceFeed;

    constructor(address owner, address chainLinkOracle) Ownable(owner) {
        priceFeed = new PriceFeedV3(chainLinkOracle);
    }

    struct Order {
        string shippingAddr;
        uint256 quantity;
        uint256 amount;
        address buyerAddr;
        Status status;
    }

    // Store the buyers order
    mapping(address => uint32[]) public buyersOrder;

    // Store the order details with respective order number.
    mapping(uint32 => Order) orders;

    // Record the buyer purchase payments.
    mapping(address => uint256) public payments;

    /**
     * @notice Sets the total stock available for sale.
     * @param newTotalStock Available stock for sale.
     */
    function setStock(uint32 newTotalStock) external onlyOwner {
        totalStock = newTotalStock;
    }

    /**
     * @notice Sets the price of the item.
     * @dev This price will be later converted to Wei using latest ETH/USD Chainlink oracle.
     * @param newPrice Price of the item.
     */
    function setPrice(uint256 newPrice) external onlyOwner {
        price = newPrice;
    }

    /**
     * @notice Set the price of the shipping cost.
     * @dev Shipping cost will be later converted to Wei using latest ETH/USD Chainlink oracle.
     * @param newShippingCost Current shipping cost.
     */
    function setShippingCost(uint256 newShippingCost) external onlyOwner {
        shippingCost = newShippingCost;
    }

    /**
    * @notice Returns the total cost including shipping for the given quantity.
    * @dev Item price and shipping cost is converted to Wei using chainlink ETH/USD price feed.
    * @param quantity The number of items to be shipped.
    * @return The total cost including the price of items and shipping cost.
    */
    function totalCost(uint32 quantity) public view returns (uint256) {
        // Convert item price into current ETH/USD market price in wei.
        uint256 priceInWei = (priceFeed.amountToWei(price)) * quantity;

        // Convert shipping cost into current ETH/USD market price in wei.
        uint256 shippingCostInWei = priceFeed.amountToWei(shippingCost);

        // Total cost in wei.
        return (priceInWei + shippingCostInWei);
    }

    /**
    * @notice Purchase the given product.
    * @dev Buyer address must be encrypted.
    * @param quantity Number of product item to be purchased.
    * @param destination Encrypted destination address of the buyer.
    */
    function purchase(
        uint32 quantity,
        string memory destination
    ) external payable {
        if (quantity == 0 || quantity > totalStock)
            revert InvalidQuantity(quantity);

        uint256 totalCostInWei = totalCost(quantity);

        // Buyer purchase amount should match the item price.
        if (msg.value != totalCostInWei) revert InvalidAmount(msg.value);

        uint256 amount = msg.value;
        Order storage order = orders[orderNo];
        order.shippingAddr = destination;
        order.quantity = quantity;
        order.amount = amount;
        order.buyerAddr = msg.sender;
        order.status = Status.pending;
        
        // Record the payment sent by the buyers.
        payments[msg.sender] += amount;
        
        // Buyer can have multiple orders.
        buyersOrder[msg.sender].push(orderNo);

        // overflow not possible, totalStock > stock, already checked.
        // msg.value <= (totalStock * price) + shippingCost.
        unchecked {
            totalStock -= quantity;
            totalPayment += msg.value;
            orderNo++;
        }
    }

    /** 
    * @notice Update shipping status.
    * @param _orderNo Order number of the given buyer.
    */
    function processShipment(uint32 _orderNo) external onlyOwner {
        Order storage order = orders[_orderNo];

        // Order should not be shipped.
        if (order.status == Status.shipped) revert AlreadyShipped(_orderNo);

        // Buyer should have sufficient balance in the contract.
        if(payments[order.buyerAddr] < order.amount) revert InsufficientBuyerPayment(_orderNo);

        order.status = Status.shipped;

        unchecked {
            amountAfterShipping += order.amount;
        }
    }

    /**
    * @notice Able to withdraw contract balance by the owner.
    * @dev Owner can only withdraw if shipping order has been fulfilled.
    */
    function withdraw() external onlyOwner {
        uint256 withdrawAmount = amountAfterShipping;

        if (amountAfterShipping == 0) revert WithdrawAmountUnavailable(0);

        unchecked {
            totalWithdraw += amountAfterShipping;
        }

        amountAfterShipping = 0;

        payable(owner()).transfer(withdrawAmount);
    }

    /**
    * @notice Refund money to the buyer.
    * @param _orderNo Order Number of the buyer.
    */
    function setCancelAndRefund(uint32 _orderNo) external onlyOwner {
        Order storage order = orders[_orderNo];

        if (order.status == Status.shipped) revert AlreadyShipped(_orderNo);

        if(order.status == Status.refund) revert AlreadyRefund(_orderNo);

        if (order.status == Status.cancelled) revert AlreadyCancelled(_orderNo);

        if (order.amount == 0 || payments[order.buyerAddr] > order.amount)
            revert InsufficientBuyerPayment(_orderNo);

        order.status = Status.cancelled;
    }

    /**
    * @notice Refund money to the multiple buyers.
    * @param _orderNo Array of Order Number of the buyers.
    */
    function setCancelAndRefund(
        uint32[20] calldata _orderNo
    ) external onlyOwner {
        for (uint8 i = 0; i < _orderNo.length; i++) {
            Order storage order = orders[_orderNo[i]];
                if (order.status == Status.shipped) revert AlreadyShipped(i);
                if(order.status == Status.refund) revert AlreadyRefund(i);
                if (order.status == Status.cancelled) revert AlreadyCancelled(i);

            if (order.amount == 0 || payments[order.buyerAddr] > order.amount)
                revert InsufficientBuyerPayment(i);
                order.status = Status.cancelled;
        }
    }

    /**
    * @notice Collect refund buy the buyer.
    * @param _orderNo Order Number of the buyer.
    */
    function collectRefund(uint32 _orderNo) external nonReentrant {
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

    /**
    * @notice Retreive order number of the buyer.
    * @param buyer buyer address.
    */
    function getOrder(address buyer) external view returns (uint32[] memory) {
        return buyersOrder[buyer];
    }

    /**
    * @notice Retreive order details.
    * @param _orderNo Order Number of the buyer.
    */
    function getOrderDetails(
        uint32 _orderNo
    )
        external
        view
        returns (Order memory)
    {
        Order memory order = orders[_orderNo];
        return order;
    }
}


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
