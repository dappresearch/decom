// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {Test, console} from "forge-std/Test.sol";
import {IDeComEvents} from "../src/IDeCom.sol";
import {MockAggregratorV3Interface} from "../src/mocks/MockAggregratorV3Interface.sol";

import  "../src/DeCom.sol";

contract PenguStoreTest is Test, IDeComEvents {
    DeCom public decom;

    MockAggregratorV3Interface public mockOracle;

    PriceFeedV3 public priceFeed;

    IDeCom idecom;

    uint32 orderQty;
    uint256 purchaseAmount;

    address ownerAddr;
    address buyer1;
    address buyer2;
    address buyer3;

    address randomGuy;

    uint32 constant STOCK = 300;

    // Single item price.
    uint16 constant PRICE = 15;

    uint16 constant SHIPPINGCOST = 11;

    // (Price + Shipping cost) for quanity 1, convert into wei
    // $15 + $11 = $26, calculated at the eth price of $3200
    // see method `totalStock` and contract `MockAggregratorV3Interface`.
    uint256 totalPrice = 8125000000000000;
        
    function setUp() public {
        ownerAddr = address(3);
        buyer1 = address(2);
        buyer2 = address(4);
        buyer3 = address(5);

        vm.prank(buyer1);

        mockOracle = new MockAggregratorV3Interface();
        
        priceFeed = new PriceFeedV3(address(mockOracle));

        decom = new DeCom(ownerAddr, address(mockOracle), PRICE, SHIPPINGCOST, STOCK);
        
        vm.label(ownerAddr, "Owner Address");

        vm.deal(buyer1, 5 ether);
        vm.deal(buyer2, 5 ether);
        vm.deal(buyer3, 5 ether);

    }

    function testTotalCost() public view {
        uint256 totalCostInWei = 8125000000000000;
        uint256 totalCost = decom.totalCost(1);
        assertEq(totalCost, totalCostInWei);

        totalCostInWei = 26875000000000000;
        totalCost = decom.totalCost(5);
        assertEq(totalCost, totalCostInWei);
    }
    
    function testSetStock() public  {
        uint32 qty = 300;

        vm.prank(ownerAddr);

        vm.expectEmit(true, false, false, false);
        emit StockUpdated(qty);
        decom.setStock(qty);

        assertEq(decom.totalStock(), qty, "Incorrect total stock");
    }

    function testSetStock_Fail_onlyOwner() public {
         vm.expectRevert(
            abi.encodeWithSelector(
                Ownable.OwnableUnauthorizedAccount.selector,
                buyer1
            )
        );
        vm.prank(buyer1);
        decom.setStock(300);
    }

    function testSetPrice() public  {
        uint16 newPrice = 300;

        vm.prank(ownerAddr);

        vm.expectEmit(true, false, false, false);
        emit PriceUpdated(newPrice);
        decom.setPrice(newPrice);

        assertEq(decom.price(), newPrice, "Incorrect price");
    }

    function testSetPrice_Fail_onlyOwner() public {
         // Ownable contract is from openzeppelin
         vm.expectRevert(
            abi.encodeWithSelector(
                Ownable.OwnableUnauthorizedAccount.selector,
                buyer1
            )
        );
        vm.prank(buyer1);
        decom.setStock(300);
    }

    function testSetShippingCost() public  {
        uint8 newShippingCost = 15;
        vm.prank(ownerAddr);

        vm.expectEmit(true, false, false, false);
        emit ShippingCostUpdated(newShippingCost);
        decom.setShippingCost(newShippingCost);

        assertEq(decom.shippingCost(), newShippingCost, "Incorrect shipping cost");
    }

    function testShippingCost_Fail_onlyOwner() public {
         // Ownable contract is from openzeppelin
         vm.expectRevert(
            abi.encodeWithSelector(
                Ownable.OwnableUnauthorizedAccount.selector,
                buyer1
            )
        );
        vm.prank(buyer1);
        decom.setShippingCost(300);
    }

    function testPriceFeedV3_amountToWei() public view {
        uint256 expectedWeiValue1 = 10937500000000000;
        uint256 expectedWeiValue2 = 3437500000000000;

        assertEq(expectedWeiValue1, priceFeed.amountToWei(35));
        assertEq(expectedWeiValue2, priceFeed.amountToWei(11));
    }
       
    function testPurchase() public {
        orderQty = 1;
        // Get the purchase amount in Wei.
       purchaseAmount = decom.totalCost(orderQty);

        vm.prank(buyer1);
        decom.purchase{value: totalPrice }(orderQty, 'randomAddress');

        Order memory order = decom.getOrderDetails(decom.orderNo() - 1);

        assertEq(order.shippingAddr, 'randomAddress', 'Incorrect shipping address');
        assertEq(order.quantity, orderQty, 'Incorrect order quantity');
        assertEq(order.amount, purchaseAmount, 'Incorrect order amount');
        assertEq(order.buyerAddr, buyer1, 'Incorrect buyer address');
        assertEq(order.shippingAddr, 'randomAddress', 'Incorrect shipping address');
        assertEq(
            uint256(order.status),
            uint256(Status.pending),
            'Incorrect order status'
        );
        assertEq(decom.payments(buyer1), purchaseAmount, 'Incorrect payment');

        uint32[] memory getOrders = decom.getOrder(buyer1);
        assertEq(getOrders.length, 1, 'Incorrect order length');

        assertEq(decom.totalPayment(), purchaseAmount, 'Incorrect total payment');
        assertEq(decom.totalStock(), STOCK - orderQty, 'Incorrect total stock');
        assertEq(decom.orderNo(), 1, 'Incorret order No');

        //Mint NFT test
        assertEq(decom.balanceOf(buyer1), 1, 'Incorrect NFT buyer balance');
        assertEq(decom.ownerOf(0), buyer1, 'Incorrect NFT address');
    }

    function testPurchase_InValidQuantity() public {
         uint16 orderStock = 301;
         vm.expectRevert(
            abi.encodeWithSelector(
                IError.InValidQuantity.selector,
                orderStock
            )
        );
        vm.prank(buyer1);
        decom.purchase(orderStock, "randomAddress");
    }

    function testPurchase_InvalidAmount() public {
         uint8 orderPrice = 1 wei ;
         vm.expectRevert(
            abi.encodeWithSelector(
                IError.InValidAmount.selector,
                orderPrice
            )
        );

        decom.purchase{value: orderPrice }(2, "randomAddress");
    }

    function testProcessShipment() public {
        orderQty = 199;
       
        // Get the purchase amount in Wei.
       purchaseAmount = decom.totalCost(orderQty);

        vm.prank(buyer1);
        decom.purchase{value: purchaseAmount }(orderQty, 'randomAddress');
    
        // Process shipment after receiving the order.
        vm.prank(ownerAddr);
        decom.processShipment(0);

        // Check order status.
        Order memory order = decom.getOrderDetails(0);
        assertEq(
            uint256(order.status),
            uint256(Status.shipped),
            'Invalid order status'
        );
        
        assertEq(decom.amountAfterShipping(), purchaseAmount, 'Invalid amount after shipping');
    }
    
    function testProcessShipmentFail_AlreadyShipped() public {
        orderQty = 52;
        // Get the purchase amount in Wei.
       purchaseAmount = decom.totalCost(orderQty);

        vm.prank(buyer1);
        decom.purchase{value: purchaseAmount }(orderQty, 'randomAddress');

        vm.prank(ownerAddr);
        decom.processShipment(0);

        vm.expectRevert(
            abi.encodeWithSelector(
                IError.AlreadyShipped.selector,
                0
            )
        );
        vm.prank(ownerAddr);
        decom.processShipment(0);
    }

     function testProcessShipmentFail_OnlyOwner() public {
        orderQty = 63;
        // Get the purchase amount in Wei.
       purchaseAmount = decom.totalCost(orderQty);

        vm.prank(buyer1);
        decom.purchase{value: purchaseAmount }(orderQty, 'randomAddress');
       
        vm.expectRevert(
            abi.encodeWithSelector(
                Ownable.OwnableUnauthorizedAccount.selector,
                buyer1
            )
        );
        vm.prank(buyer1);
        decom.processShipment(0);
    }

    function testWithdraw() public {
        orderQty = 163;
        // Get the purchase amount in Wei.
       purchaseAmount = decom.totalCost(orderQty);

        vm.prank(buyer2);
        decom.purchase{value: purchaseAmount }(orderQty, 'randomAddress');

        vm.prank(ownerAddr);
        decom.processShipment(0);
        
        vm.prank(ownerAddr);
        decom.withdraw();

        assertEq(decom.amountAfterShipping(), 0);
    }

    function testWithdraw_OnlyOwner() public {
        address mockOwner = address(4);

        vm.prank(buyer2);
        decom.purchase{value: totalPrice }(1, 'randomAddress');

        vm.prank(ownerAddr);
        decom.processShipment(0);
        
        vm.expectRevert(
            abi.encodeWithSelector(
                Ownable.OwnableUnauthorizedAccount.selector,
                mockOwner
            )
        );
        vm.prank(mockOwner);
        decom.withdraw();
    }

    function testWithdraw_WithdrawAmountUnavailable() public {
        vm.prank(address(2));
        decom.purchase{value: totalPrice }(1, 'randomAddress');
       
        vm.expectRevert(
            abi.encodeWithSelector(
                IError.WithdrawAmountUnavailable.selector,
                0
            )
        );
        vm.prank(ownerAddr);
        decom.withdraw();

        assertEq(decom.amountAfterShipping(), 0);
    }

    function testSetCancelAndRefund() public {
        orderQty = 206;
        // Get the purchase amount in Wei.
       purchaseAmount = decom.totalCost(orderQty);

        vm.prank(buyer1);
        decom.purchase{value: purchaseAmount }(orderQty, 'randomAddress');
        
        uint32 orderNo = decom.buyersOrder(buyer1, 0);
        
        vm.prank(ownerAddr);
        decom.setCancelAndRefund(orderNo);

        Order memory order = decom.getOrderDetails(0);
        
        assertEq(
            uint256(order.status),
            uint256(Status.cancelled),
            "InValid Status");
        
        // If order is cancelled, the ordered stock should again 
        // add back to total stock available for sale.
        assertEq(decom.totalStock(), STOCK, "InValid Stock");
    }

    function testSetCancelAndRefundFail_AlreadyCancelled() public {
        orderQty = 103;
        // Get the purchase amount in Wei.
       purchaseAmount = decom.totalCost(orderQty);

        vm.prank(buyer1);
        decom.purchase{value: purchaseAmount }(orderQty, 'randomAddress');
        
        uint32 orderNo = decom.buyersOrder(buyer1, 0);

        vm.prank(ownerAddr);
        decom.setCancelAndRefund(orderNo);

        vm.expectRevert(
            abi.encodeWithSelector(
                IError.AlreadyCancelled.selector, orderNo)
        );
        vm.prank(ownerAddr);
        decom.setCancelAndRefund(orderNo);
    }

     function testSetCancelAndRefundFail_AlreadyShipped() public {
         orderQty = 111;
        // Get the purchase amount in Wei.
       purchaseAmount = decom.totalCost(orderQty);

        vm.prank(buyer1);
        decom.purchase{value: purchaseAmount }(orderQty, 'randomAddress');

        uint32 orderNo = decom.buyersOrder(buyer1, 0);

        vm.prank(ownerAddr);
        decom.processShipment(orderNo);
        
        vm.expectRevert(
            abi.encodeWithSelector(
                IError.AlreadyShipped.selector, orderNo)
        );
        vm.prank(ownerAddr);
        decom.setCancelAndRefund(orderNo);
    }

    function testSetCancelAndRefund_Loop() public {
        orderQty = 112;
       purchaseAmount = decom.totalCost(orderQty);
        vm.prank(buyer2);
        decom.purchase{value: purchaseAmount }(orderQty, 'randomAddress');

        orderQty = 1;
        purchaseAmount = decom.totalCost(orderQty);
        vm.prank(buyer1);
        decom.purchase{value: purchaseAmount }(orderQty, 'randomAddress');

        orderQty = 99;
        purchaseAmount = decom.totalCost(orderQty);
        vm.prank(buyer3);
        decom.purchase{value: purchaseAmount }(orderQty, 'randomAddress');

        uint32[] memory orders = new uint32[](3);
        orders[0] = 0;
        orders[1] = 1;
        orders[2] = 2;
       
        for(uint8 i=0; i<3; i++) {
            vm.prank(ownerAddr);
            decom.setCancelAndRefund(i);
            Order memory order = decom.getOrderDetails(i);
            assertEq(
            uint256(order.status),
            uint256(Status.cancelled)
        );
        }
        // If order is cancelled, the ordered stock should again 
        // add back to total stock available for sale.
        assertEq(decom.totalStock(), STOCK, "InValid Stock");
    }

    function testCollectRefund() public { 
        orderQty = 112;
       purchaseAmount = decom.totalCost(orderQty);
        vm.prank(buyer1);
        decom.purchase{value: purchaseAmount }(orderQty, 'randomAddress');

        uint32 orderNo = decom.buyersOrder(buyer1, 0);

        vm.prank(ownerAddr);
        decom.setCancelAndRefund(orderNo);

        vm.prank(buyer1);
        decom.collectRefund(orderNo);

        Order memory order = decom.getOrderDetails(orderNo);

        assertEq(decom.payments(buyer1), 0);
        assertEq(order.amount, 0); 
        assertEq(decom.totalPayment(), 0); 
        assertEq(
            uint256(order.status),
            uint256(Status.refund)
        );
    }

    function testCollectRefund_invalidCollector() public {
        orderQty = 213;
       purchaseAmount = decom.totalCost(orderQty);
        vm.prank(buyer1);
        decom.purchase{value: purchaseAmount }(orderQty, 'randomAddress');

        uint32 orderNo = decom.buyersOrder(buyer1, 0);

        vm.prank(ownerAddr);
        decom.setCancelAndRefund(orderNo);

        vm.expectRevert(
            abi.encodeWithSelector(
                IError.InValidCollector.selector, buyer3)
        );
        vm.prank(buyer3);
        decom.collectRefund(orderNo);
    }

    function testCollectRefund_InsufficientBuyerPayment() public {
        orderQty = 112;
       purchaseAmount = decom.totalCost(orderQty);

        vm.prank(buyer1);
        decom.purchase{value: purchaseAmount }(orderQty, 'randomAddress');
        uint32 orderNo = decom.buyersOrder(buyer1, 0);

        vm.prank(ownerAddr);
        decom.setCancelAndRefund(orderNo);

        vm.prank(buyer1);
        decom.collectRefund(orderNo);
        
        vm.expectRevert(
            abi.encodeWithSelector(
                IError.InsufficientBuyerPayment.selector, orderNo)
        );
        vm.prank(buyer1);
        decom.collectRefund(orderNo);
    }

    function testCollectRefund_AlreadyShipped() public {
        orderQty = 100;
       purchaseAmount = decom.totalCost(orderQty);
        vm.prank(buyer1);
        decom.purchase{value: purchaseAmount }(orderQty, 'randomAddress');

        uint32 orderNo = decom.buyersOrder(buyer1, 0);

        vm.prank(ownerAddr);
        decom.processShipment(orderNo);

        vm.expectRevert(
            abi.encodeWithSelector(
                IError.AlreadyShipped.selector, orderNo)
        );
        vm.prank(buyer1);
        decom.collectRefund(orderNo);
    }

    function testCollectRefund_OrderedNotCancelled() public {
        orderQty = 114;
       purchaseAmount = decom.totalCost(orderQty);
        vm.prank(buyer1);
        decom.purchase{value: purchaseAmount }(orderQty, 'randomAddress');

        uint32 orderNo = decom.buyersOrder(buyer1, 0);

        vm.expectRevert(
            abi.encodeWithSelector(
                IError.OrderNotCancelled.selector, orderNo)
        );
        vm.prank(buyer1);
        decom.collectRefund(orderNo);
    }
}

