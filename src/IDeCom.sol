// SPDX-License-Identifier: No License
pragma solidity ^0.8.20;

import "./Container.sol";

interface IDeCom {
     function setStock(uint32 newTotalStock) external;
     function setPrice(uint16 newPrice) external;
     function setShippingCost(uint16 newShippingCost) external;
     function totalCost(uint32 quantity) external view returns (uint256);
     function purchase(uint32 quantity, string memory destination) external payable;
     function processShipment(uint32 _orderNo) external;
     function withdraw() external;
     function setCancelAndRefund(uint32 _orderNo) external;
     function setCancelAndRefund(uint32[20] calldata _orderNo) external;
     function collectRefund(uint32 _orderNo) external;
     function getOrder(address buyer) external view returns (uint32[] memory);
     function getOrderDetails(uint32 _orderNo) external view returns(Order memory);
}

/**
 * @dev Events declared seperate to use with foundry test.
 */
interface IDeComEvents {
     event StockUpdated(uint32 indexed newTotalStock);
     event PriceUpdated(uint256 indexed newPrice);
     event ShippingCostUpdated(uint256 indexed newShippingCost);
     event PurchaseOrder(uint32 indexed orderNo, address indexed buyer, uint32 indexed quantity, uint256 amount, string destination);
     event OrderShipped(uint32 indexed orderNo, address indexed buyer);
     event Withdraw(uint256 indexed amount, address indexed owner);
     event OrderCancelled(uint32 indexed orderNo, address indexed buyer);
     event RefundCollected(uint32 indexed orderNo, address indexed buyer, uint256 indexed amount);
}




