// SPDX-License-Identifier: No License
pragma solidity ^0.8.20;
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

import "forge-std/console.sol";

import "./PriceFeedV3.sol";
import "./IError.sol";
import "./IDeCom.sol";
import "./Container.sol";
import "./ItemNFT.sol";

contract DeCom is IDeCom, IDeComEvents, IError, ItemNFT, ReentrancyGuard {
    uint32 public totalStock;

    // Track number of orders.
    uint32 public orderNo;

    uint16 public shippingCost;

    uint16 public price;

    uint256 public totalPayment;

    uint256 public totalWithdraw;

    // Revenue generted after fulfilling shipping.
    uint256 public amountAfterShipping;

    PriceFeedV3 public immutable priceFeed;

    constructor(
        address owner, 
        address chainLinkOracle, 
        uint16 _price,
        uint16 _shippingCost, 
        uint32 _totalStock)
        Ownable(owner)
    {
        if(_price == 0) revert InValidPrice(0);

        if(_shippingCost == 0) revert InValidShippingCost(0);

        if(_totalStock == 0) revert InValidQuantity(0);

        priceFeed = new PriceFeedV3(chainLinkOracle);
        price = _price;
        shippingCost = _shippingCost;
        totalStock = _totalStock;
    }

    // Store the buyers order
    mapping(address => uint32[]) public buyersOrder;

    // Store the order details with respective order number.
    mapping(uint32 => Order) public orders;

    // Record the buyer purchase payments.
    mapping(address => uint256) public payments;

    /**
     * @notice Sets the total stock available for sale.
     * @param newTotalStock Available stock for sale.
     */
    function setStock(uint32 newTotalStock) external onlyOwner {
        totalStock = newTotalStock;
        emit StockUpdated(newTotalStock);
    }

    /**
     * @notice Sets the price of the item.
     * @dev This price will be later converted to Wei using latest ETH/USD Chainlink oracle.
     * @param newPrice Price of the item.
     */
    function setPrice(uint16 newPrice) external onlyOwner {
        price = newPrice;
        emit PriceUpdated(newPrice);
    }

    /**
     * @notice Set the price of the shipping cost.
     * @dev Shipping cost will be later converted to Wei using latest ETH/USD Chainlink oracle.
     * @param newShippingCost Current shipping cost.
     */
    function setShippingCost(uint16 newShippingCost) external onlyOwner {
        shippingCost = newShippingCost;
        emit ShippingCostUpdated(newShippingCost);
    }

    /**
    * @notice Returns the total cost including shipping for the given quantity.
    * @dev Item price and shipping cost is converted to Wei using chainlink ETH/USD price feed.
    *      While calculating amountToWei, there is some percision loss, could be improved.
    * @param quantity The number of items to be shipped.
    * @return The total cost including the price of items and shipping cost.
    */
    function totalCost(uint32 quantity) public view returns (uint256) {
        // Convert item price into current ETH/USD market price in wei.
        uint256 priceInWei = priceFeed.amountToWei(price * quantity);

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
        string calldata destination
    ) external payable {
        if (quantity == 0 || quantity > totalStock)
            revert InValidQuantity(quantity);

        uint256 totalCostInWei = totalCost(quantity);

        // Buyer purchase amount should match the item price.
        if (msg.value != totalCostInWei) revert InValidAmount(msg.value);

        uint256 amount = msg.value;

        Order storage order = orders[orderNo];
        order.shippingAddr = destination;
        order.quantity = quantity;
        order.amount = amount;
        order.buyerAddr = msg.sender;
        order.status = Status.pending;
        
        // Buyer can have multiple orders.
        buyersOrder[msg.sender].push(orderNo);

        unchecked {
            // Record the payment sent by the buyers.
            payments[msg.sender] += amount;

           // Overflow not possible, totalStock > quantity, already checked.
            totalStock -= quantity;

            totalPayment += msg.value;
            orderNo++;
        }

         // Mint NFT
        _mintItemNFT(msg.sender);

        emit PurchaseOrder(orderNo - 1, msg.sender, quantity, msg.value, destination);
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
        
        emit OrderShipped(_orderNo, order.buyerAddr);
    }

    /**
    * @notice Able to withdraw contract balance by the owner.
    * @dev Owner can only withdraw if shipping order has been fulfilled.
    */
    function withdraw() external onlyOwner {
        uint256 withdrawAmount = amountAfterShipping;

        if (amountAfterShipping == 0 || 
            address(this).balance < withdrawAmount
        ) revert WithdrawAmountUnavailable(0);

        unchecked {
            totalWithdraw += amountAfterShipping;
            amountAfterShipping = 0;
        }

        payable(owner()).transfer(withdrawAmount);

        emit Withdrawn(withdrawAmount, owner());
    }

    /**
    * @dev Internal function to check if order is shipped and buyer has sufficient balance.
    * @param order Struct Order.
    * @param _orderNo Order number of the buyer.
    */
    function _checkShippedAndBuyerPayment(Order memory order, uint32 _orderNo) internal view {
        if (order.amount == 0 || payments[order.buyerAddr] < order.amount)
            revert InsufficientBuyerPayment(_orderNo);

        if (order.status == Status.shipped) revert AlreadyShipped(_orderNo); 

        if(order.status == Status.refund) revert AlreadyRefund(_orderNo);
    }

    /**
    * @dev Private function to update the status of an order.
    * @param _orderNo Order number of the buyer.
    */
    function _updateOrderStatus(uint32 _orderNo) private {
        Order storage order = orders[_orderNo];

        _checkShippedAndBuyerPayment(order, _orderNo);

        if (order.status == Status.cancelled) revert AlreadyCancelled(_orderNo);

        order.status = Status.cancelled;

        emit OrderCancelled(_orderNo, order.buyerAddr);
    }
    /**
    * @notice Refund money to the buyer.
    * @param _orderNo Order number of the buyer.
    */
    function setCancelAndRefund(uint32 _orderNo) external onlyOwner {
        _updateOrderStatus(_orderNo);
    }

    /**
    * @notice Refund money to the multiple buyers.
    * @param _orderNo Array of Order Number of the buyers.
    */
    function setCancelAndRefund(
        uint32[20] calldata _orderNo
    ) external onlyOwner {
        for (uint8 i = 0; i < _orderNo.length; i++) {
            _updateOrderStatus(_orderNo[i]);
        }
    }

    /**
    * @notice Collect refund buy the buyer.
    * @param _orderNo Order Number of the buyer.
    */
    function collectRefund(uint32 _orderNo) external nonReentrant {
        Order storage order = orders[_orderNo];

        _checkShippedAndBuyerPayment(order, _orderNo);

        if(msg.sender != order.buyerAddr) revert InValidCollector(msg.sender);

        if(order.status != Status.cancelled) revert OrderNotCancelled(_orderNo);

        uint256 refundAmount = order.amount;
        
        unchecked {
            // Underflow not possible, payments[order.buyerAddr] < order.amount already checked.
            payments[msg.sender] -= order.amount;
            
            // Underflow not possible, order.amount is always less that totalPayment.
            totalPayment -= order.amount;
        }

        order.amount = 0;
        order.status = Status.refund;
        
        payable(msg.sender).transfer(refundAmount);

        emit RefundCollected(_orderNo, msg.sender, refundAmount);
    }

    /**
    * @notice Retreive order number of the buyer.
    * @param buyer Buyer address.
    */
    function getOrder(address buyer) external view returns (uint32[] memory) {
        return buyersOrder[buyer];
    }

    /**
    * @notice Retreive order details.
    * @param _orderNo Order Number of the buyer.
    */
    function getOrderDetails(uint32 _orderNo) external view returns (Order memory) {
        Order memory order = orders[_orderNo];
        return order;
    }
}

