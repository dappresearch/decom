// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {Test, console} from "forge-std/Test.sol";
import {DeCom, Ownable, PriceFeedV3} from "../src/DeCom.sol";
import {MockAggregratorV3Interface} from "../src/MockAggregratorV3Interface.sol";

contract PenguStoreTest is Test {
    DeCom public decom;

    MockAggregratorV3Interface public mockOracle;

    PriceFeedV3 public priceFeed;

    address ownerAddr;

    address buyer1;
    address buyer2;
    address buyer3;

    address randomGuy;

    uint16 constant STOCK = 300;

    // Single item price.
    uint8 price = 15;

    uint8 shippingCost = 11;

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

        decom = new DeCom(ownerAddr, address(mockOracle));
        
        vm.label(ownerAddr, "Owner Address");

        vm.deal(buyer1, 1 ether);
        vm.deal(buyer2, 1 ether);
        vm.deal(buyer3, 1 ether);

        vm.startPrank(ownerAddr);
        decom.setStock(STOCK);
        decom.setPrice(price);
        decom.setShippingCost(shippingCost);
        vm.stopPrank();
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
        vm.prank(ownerAddr);
        decom.setStock(300);
        assertEq(decom.totalStock(), 300);
    }

    function testSetStock_Fail_onlyOwner() public {
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

    function testSetPrice() public  {
        vm.prank(ownerAddr);
        decom.setPrice(300);
        assertEq(decom.price(), 300);
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
        decom.setShippingCost(newShippingCost);
        assertEq(decom.shippingCost(), newShippingCost);
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
        uint8 orderQty = 1;
        // Get the purchase amount in Wei.
        uint purchaseAmount = decom.totalCost(orderQty);

        vm.prank(buyer1);
        decom.purchase{value: purchaseAmount }(orderQty, 'randomAddress');

        DeCom.Order memory order = decom.getOrderDetails(decom.orderNo() - 1);

        assertEq(order.shippingAddr, 'randomAddress', 'Incorrect shipping address');
        assertEq(order.quantity, orderQty, 'Incorrect order quantity');
        assertEq(order.amount, purchaseAmount, 'Incorrect order amount');
        assertEq(order.buyerAddr, buyer1, 'Incorrect buyer address');
        assertEq(order.shippingAddr, 'randomAddress', 'Incorrect shipping address');
        assertEq(
            uint256(order.status),
            uint256(DeCom.Status.pending),
            'Incorrect order status'
        );
        assertEq(decom.payments(buyer1), purchaseAmount, 'Incorrect payment');

        uint32[] memory getOrders = decom.getOrder(buyer1);
        assertEq(getOrders.length, 1, 'Incorrect order length');

        assertEq(decom.totalPayment(), purchaseAmount, 'Incorrect total payment');
        assertEq(decom.totalStock(), STOCK - orderQty, 'Incorrect total stock');
        assertEq(decom.orderNo(), 1, 'Incorret order No');
    }

    function testPurchase_InvalidQuantity() public {
         uint16 orderStock = 301;
         vm.expectRevert(
            abi.encodeWithSelector(
                DeCom.InvalidQuantity.selector,
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
                DeCom.InvalidAmount.selector,
                orderPrice
            )
        );

        decom.purchase{value: orderPrice }(2, "randomAddress");
    }

    function testProcessShipment() public {
        // Purchase
        vm.prank(buyer1);
        decom.purchase{value: totalPrice }(1, 'randomAddress');

        // Process shipment after receiving the order.
        vm.prank(ownerAddr);
        decom.processShipment(0);

        // Check order status.
        DeCom.Order memory order = decom.getOrderDetails(0);
        assertEq(
            uint256(order.status),
            uint256(DeCom.Status.shipped),
            'Invalid order status'
        );
        
        assertEq(decom.amountAfterShipping(), totalPrice, 'Invalid amount after shipping');
    }
    
    function testProcessShipmentFail_AlreadyShipped() public {
        vm.prank(buyer1);
        decom.purchase{value: totalPrice}(1, 'randomAddress');

        vm.prank(ownerAddr);
        decom.processShipment(0);

        vm.expectRevert(
            abi.encodeWithSelector(
                DeCom.AlreadyShipped.selector,
                0
            )
        );
        vm.prank(ownerAddr);
        decom.processShipment(0);
    }

     function testProcessShipmentFail_OnlyOwner() public {
        vm.prank(buyer1);
        decom.purchase{value: totalPrice }(1, 'randomAddress');

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
        vm.prank(address(2));
        decom.purchase{value: totalPrice }(1, 'randomAddress');

        vm.prank(ownerAddr);
        decom.processShipment(0);
        
        vm.prank(ownerAddr);
        decom.withdraw();

        assertEq(decom.amountAfterShipping(), 0);
    }

    function testWithdraw_OnlyOwner() public {
        address mockOwner = address(4);
        
        vm.prank(address(2));
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
                DeCom.WithdrawAmountUnavailable.selector,
                0
            )
        );

        vm.prank(ownerAddr);
        decom.withdraw();

        assertEq(decom.amountAfterShipping(), 0);
    }

    function testSetCancelAndRefund() public {
        vm.prank(buyer1);
        decom.purchase{value: totalPrice }(1, 'randomAddress');
        
        uint32 orderNo = decom.buyersOrder(address(2), 0);
        
        vm.prank(ownerAddr);
        decom.setCancelAndRefund(orderNo);
    }

    function testSetCancelAndRefundFail_AlreadyCancelled() public {
        vm.prank(buyer1);
        decom.purchase{value: totalPrice }(1, 'randomAddress');
        
        uint32 orderNo = decom.buyersOrder(address(2), 0);

        vm.prank(ownerAddr);
        decom.setCancelAndRefund(orderNo);

        vm.expectRevert(
            abi.encodeWithSelector(
                DeCom.AlreadyCancelled.selector, orderNo)
        );
        vm.prank(ownerAddr);
        decom.setCancelAndRefund(orderNo);
    }

     function testSetCancelAndRefundFail_AlreadyShipped() public {
        vm.prank(buyer1);
        decom.purchase{value: totalPrice }(1, 'randomAddress');
        
        uint32 orderNo = decom.buyersOrder(address(2), 0);

        vm.prank(ownerAddr);
        decom.processShipment(orderNo);
        
        vm.expectRevert(
            abi.encodeWithSelector(
                DeCom.AlreadyShipped.selector, orderNo)
        );
        vm.prank(ownerAddr);
        decom.setCancelAndRefund(orderNo);
    }

    function testSetCancelAndRefund_Loop() public {
        vm.prank(buyer1);
        decom.purchase{value: totalPrice }(1, 'randomAddress');

        vm.prank(address(4));
        decom.purchase{value: totalPrice }(1, 'randomAddress');

        vm.prank(address(5));
        decom.purchase{value: totalPrice }(1, 'randomAddress');

        uint32[] memory orders = new uint32[](3);
        orders[0] = 0;
        orders[1] = 1;
        orders[2] = 2;
       
        for(uint8 i=0; i<3; i++) {
            vm.prank(ownerAddr);
            decom.setCancelAndRefund(i);
            DeCom.Order memory order = decom.getOrderDetails(i);
            assertEq(
            uint256(order.status),
            uint256(DeCom.Status.cancelled)
        );
        }
    }

    function testCollectRefund() public {
        vm.prank(buyer1);
        decom.purchase{value: totalPrice }(1, 'randomAddress');

        uint32 orderNo = decom.buyersOrder(buyer1, 0);

        vm.prank(ownerAddr);
        decom.setCancelAndRefund(orderNo);

        vm.prank(buyer1);
        decom.collectRefund(orderNo);

        DeCom.Order memory order = decom.getOrderDetails(orderNo);

        assertEq(decom.payments(buyer1), 0);
        assertEq(order.amount, 0); 
        assertEq(decom.totalPayment(), 0); 
        assertEq(
            uint256(order.status),
            uint256(DeCom.Status.refund)
        );
    }

    function testCollectRefund_invalidCollector() public {
        vm.prank(buyer1);
        decom.purchase{value: totalPrice}(1, 'randomAddress');

        uint32 orderNo = decom.buyersOrder(buyer1, 0);

        vm.prank(ownerAddr);
        decom.setCancelAndRefund(orderNo);

        vm.expectRevert(
            abi.encodeWithSelector(
                DeCom.InvalidCollector.selector, buyer3)
        );
        vm.prank(buyer3);
        decom.collectRefund(orderNo);
    }

    function testCollectRefund_InsufficientBuyerPayment() public {
        vm.prank(buyer1);
        decom.purchase{value: totalPrice}(1, 'randomAddress');

        uint32 orderNo = decom.buyersOrder(buyer1, 0);

        vm.prank(ownerAddr);
        decom.setCancelAndRefund(orderNo);

        vm.prank(buyer1);
        decom.collectRefund(orderNo);
        
        vm.expectRevert(
            abi.encodeWithSelector(
                DeCom.InsufficientBuyerPayment.selector, orderNo)
        );
        vm.prank(buyer1);
        decom.collectRefund(orderNo);
    }

    function testCollectRefund_AlreadyShipped() public {
        vm.prank(buyer1);
        decom.purchase{value: totalPrice }(1, 'randomAddress');

        uint32 orderNo = decom.buyersOrder(buyer1, 0);

        vm.prank(ownerAddr);
        decom.processShipment(orderNo);

        vm.expectRevert(
            abi.encodeWithSelector(
                DeCom.AlreadyShipped.selector, orderNo)
        );
        vm.prank(buyer1);
        decom.collectRefund(orderNo);
    }

    function testCollectRefund_OrderedNotCancelled() public {
        vm.prank(buyer1);
        decom.purchase{value: totalPrice }(1, 'randomAddress');

        uint32 orderNo = decom.buyersOrder(buyer1, 0);

        vm.expectRevert(
            abi.encodeWithSelector(
                DeCom.OrderNotCancelled.selector, orderNo)
        );
        vm.prank(buyer1);
        decom.collectRefund(orderNo);
    }
}
