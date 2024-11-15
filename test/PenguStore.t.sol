// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {Test, console} from "forge-std/Test.sol";
import {PenguStore} from "../src/PenguStore.sol";
import {MockAggregratorV3Interface} from "../src/MockAggregratorV3Interface.sol";

contract PenguStoreTest is Test {
    PenguStore public ps;

    MockAggregratorV3Interface public mockOracle;

    address ownerAddr;

    address buyer1;
    address buyer2;
    address buyer3;

    address randomGuy;

    uint16 constant STOCK = 300;

    uint256 price = 15;

    function setUp() public {
        ownerAddr = address(3);
        buyer1 = address(2);
        buyer2 = address(4);
        buyer3 = address(5);

        vm.prank(buyer1);

        mockOracle = new MockAggregratorV3Interface();

        ps = new PenguStore(ownerAddr, address(mockOracle));
        
        vm.label(ownerAddr, "Owner Address");

        vm.deal(buyer1, 1 ether);
        vm.deal(buyer2, 1 ether);
        vm.deal(buyer3, 1 ether);

        vm.startPrank(ownerAddr);
        ps.setStock(STOCK);
        ps.setPrice(price);
        vm.stopPrank();
    }
    
    function testSetStock() public  {
        vm.prank(ownerAddr);
        ps.setStock(300);
        assertEq(ps.totalStock(), 300);
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
        ps.setStock(300);
    }

    // function testSetPrice() public  {
    //     vm.prank(ownerAddr);
    //     ps.setPrice(300);
    //     assertEq(ps.price(), 300);
    // }

    // function testSetPrice_Fail_onlyOwner() public {
    //      // Ownable contract is from openzeppelin
    //      vm.expectRevert(
    //         abi.encodeWithSelector(
    //             Ownable.OwnableUnauthorizedAccount.selector,
    //             buyer1
    //         )
    //     );
    //     vm.prank(buyer1);
    //     ps.setStock(300);
    // }

    // function testPurchase() public {
        // uint8 orderQty = 1;
        // vm.prank(buyer1);

        // console.log(mpf.amountToWei(1));

        // uint totalCostData = ps.totalCost(orderQty);

        // assertEq(totalCostData, 1000000);

        // ps.purchase{value: price }(orderQty, 'randomAddress');

        // PenguStore.Order memory order = ps.getOrderDetails(ps.orderNo() - 1);

        // assertEq(order.shippingAddr, 'randomAddress');
        // assertEq(order.quantity, orderQty);
        // assertEq(order.amount, price);
        // assertEq(order.buyerAddr, buyer1);
        // assertEq(order.shippingAddr, 'randomAddress');
        // assertEq(
        //     uint256(order.status),
        //     uint256(PenguStore.Status.pending)
        // );
        
        // assertEq(ps.payments(buyer1), price);

        // uint32[] memory getOrders = ps.getOrder(buyer1);
        // assertEq(getOrders.length, 1);

        // assertEq(ps.totalPayment(), price);
        // assertEq(ps.totalStock(), STOCK - orderQty);
        // assertEq(ps.orderNo(), 1);
    // }

    // function testPurchase_MultipleOrder() public {
    //     uint8 orderQty = 59;

    //     uint256 orderAmount = orderQty * price;

    //     vm.prank(buyer1);
    //     ps.purchase{value: orderAmount }(orderQty, 'randomAddress');

    //     PenguStore.Order memory order = ps.getOrderDetails(ps.orderNo() - 1);

    //     assertEq(order.shippingAddr, 'randomAddress');
    //     assertEq(order.quantity, orderQty);
    //     assertEq(order.amount, orderAmount);
    //     assertEq(order.buyerAddr, buyer1);
    //     assertEq(order.shippingAddr, 'randomAddress');

    //     assertEq(
    //         uint256(order.status),
    //         uint256(PenguStore.Status.pending)
    //     );
        
    //     assertEq(ps.payments(buyer1), orderAmount);

    //     uint32[] memory getOrders = ps.getOrder(buyer1);
    //     assertEq(getOrders.length, 1);

    //     assertEq(ps.totalPayment(), orderAmount);
    //     assertEq(ps.totalStock(), STOCK - orderQty);
    //     assertEq(ps.orderNo(), 1);
    // }
    
    // function testPurchase_InvalidQuantity() public {
    //      uint16 orderStock = 301;
    //      vm.expectRevert(
    //         abi.encodeWithSelector(
    //             PenguStore.InvalidQuantity.selector,
    //             orderStock
    //         )
    //     );
    //     vm.prank(buyer1);
    //     ps.purchase(orderStock, "randomAddress");
    // }

    // function testPurchase_InvalidAmount() public {
    //      uint8 orderPrice = 1 wei ;
    //      vm.expectRevert(
    //         abi.encodeWithSelector(
    //             PenguStore.InvalidAmount.selector,
    //             orderPrice
    //         )
    //     );

    //     ps.purchase{value: orderPrice }(2, "randomAddress");
    // }

    // function testProcessShipment() public {
    //     vm.prank(buyer1);
    //     ps.purchase{value: price }(1, 'randomAddress');

    //     vm.prank(ownerAddr);
    //     ps.processShipment(0);

    //     PenguStore.Order memory order = ps.getOrderDetails(0);
    //     assertEq(
    //         uint256(order.status),
    //         uint256(PenguStore.Status.shipped)
    //     );
        
    //     assertEq(ps.amountAfterShipping(), price);
    // }
    
    // function testProcessShipmentFail_AlreadyShipped() public {
    //     vm.prank(buyer1);
    //     ps.purchase{value: price }(1, 'randomAddress');

    //     vm.prank(ownerAddr);
    //     ps.processShipment(0);

    //     vm.expectRevert(
    //         abi.encodeWithSelector(
    //             PenguStore.AlreadyShipped.selector,
    //             0
    //         )
    //     );
    //     vm.prank(ownerAddr);
    //     ps.processShipment(0);
    // }

    //  function testProcessShipmentFail_OnlyOwner() public {
    //     vm.prank(buyer1);
    //     ps.purchase{value: price }(1, 'randomAddress');

    //     vm.expectRevert(
    //         abi.encodeWithSelector(
    //             Ownable.OwnableUnauthorizedAccount.selector,
    //             buyer1
    //         )
    //     );
    //     vm.prank(buyer1);
    //     ps.processShipment(0);
    // }

    // function testWithdraw() public {
    //     vm.prank(address(2));
    //     ps.purchase{value: price }(1, 'randomAddress');

    //     vm.prank(ownerAddr);
    //     ps.processShipment(0);
        
    //     vm.prank(ownerAddr);
    //     ps.withdraw();

    //     assertEq(ps.amountAfterShipping(), 0);
    // }

    // function testWithdraw_OnlyOwner() public {
    //     address mockOwner = address(4);
        
    //     vm.prank(address(2));
    //     ps.purchase{value: price }(1, 'randomAddress');

    //     vm.prank(ownerAddr);
    //     ps.processShipment(0);
        
    //     vm.expectRevert(
    //         abi.encodeWithSelector(
    //             Ownable.OwnableUnauthorizedAccount.selector,
    //             mockOwner
    //         )
    //     );
    //     vm.prank(mockOwner);
    //     ps.withdraw();
    // }

    // function testWithdraw_WithdrawAmountUnavailable() public {
    //     vm.prank(address(2));
    //     ps.purchase{value: price }(1, 'randomAddress');

    //     vm.expectRevert(
    //         abi.encodeWithSelector(
    //             PenguStore.WithdrawAmountUnavailable.selector,
    //             0
    //         )
    //     );

    //     vm.prank(ownerAddr);
    //     ps.withdraw();

    //     assertEq(ps.amountAfterShipping(), 0);
    // }

    // function testSetCancelAndRefund() public {
    //     vm.prank(buyer1);
    //     ps.purchase{value: price }(1, 'randomAddress');
        
    //     uint32 orderNo = ps.buyersOrder(address(2), 0);
        
    //     vm.prank(ownerAddr);
    //     ps.setCancelAndRefund(orderNo);
    // }

    // function testSetCancelAndRefundFail_AlreadyCancelled() public {
    //     vm.prank(buyer1);
    //     ps.purchase{value: price }(1, 'randomAddress');
        
    //     uint32 orderNo = ps.buyersOrder(address(2), 0);

    //     vm.prank(ownerAddr);
    //     ps.setCancelAndRefund(orderNo);

    //     vm.expectRevert(
    //         abi.encodeWithSelector(
    //             PenguStore.AlreadyCancelled.selector, orderNo)
    //     );
    //     vm.prank(ownerAddr);
    //     ps.setCancelAndRefund(orderNo);
    // }

    //  function testSetCancelAndRefundFail_AlreadyShipped() public {
    //     vm.prank(buyer1);
    //     ps.purchase{value: price }(1, 'randomAddress');
        
    //     uint32 orderNo = ps.buyersOrder(address(2), 0);

    //     vm.prank(ownerAddr);
    //     ps.processShipment(orderNo);
        
    //     vm.expectRevert(
    //         abi.encodeWithSelector(
    //             PenguStore.AlreadyShipped.selector, orderNo)
    //     );
    //     vm.prank(ownerAddr);
    //     ps.setCancelAndRefund(orderNo);
    // }

    // function testSetCancelAndRefund_Loop() public {
    //     vm.prank(buyer1);
    //     ps.purchase{value: price }(1, 'randomAddress');

    //     vm.prank(address(4));
    //     ps.purchase{value: price }(1, 'randomAddress');

    //     vm.prank(address(5));
    //     ps.purchase{value: price }(1, 'randomAddress');

    //     uint32[] memory orders = new uint32[](3);
    //     orders[0] = 0;
    //     orders[1] = 1;
    //     orders[2] = 2;
       
    //     for(uint8 i=0; i<3; i++) {
    //         vm.prank(ownerAddr);
    //         ps.setCancelAndRefund(i);
    //         PenguStore.Order memory order = ps.getOrderDetails(i);
    //         assertEq(
    //         uint256(order.status),
    //         uint256(PenguStore.Status.cancelled)
    //     );
    //     }
    // }

    // function testCollectRefund() public {
    //     vm.prank(buyer1);
    //     ps.purchase{value: price * 30 }(30, 'randomAddress');

    //     uint32 orderNo = ps.buyersOrder(buyer1, 0);

    //     vm.prank(ownerAddr);
    //     ps.setCancelAndRefund(orderNo);

    //     vm.prank(buyer1);
    //     ps.collectRefund(orderNo);

    //     console.log("OrderNo: %s", orderNo);

    //     PenguStore.Order memory order = ps.getOrderDetails(orderNo);

    //     assertEq(ps.payments(buyer1), 0);
    //     assertEq(order.amount, 0); 
    //     assertEq(ps.totalPayment(), 0); 
    //     assertEq(
    //         uint256(order.status),
    //         uint256(PenguStore.Status.refund)
    //     );
    // }

    // function testCollectRefund_invalidCollector() public {
    //     vm.prank(buyer1);
    //     ps.purchase{value: price *  9 }(9, 'randomAddress');

    //     uint32 orderNo = ps.buyersOrder(buyer1, 0);

    //     vm.prank(ownerAddr);
    //     ps.setCancelAndRefund(orderNo);

    //     vm.expectRevert(
    //         abi.encodeWithSelector(
    //             PenguStore.InvalidCollector.selector, buyer3)
    //     );
    //     vm.prank(buyer3);
    //     ps.collectRefund(orderNo);
    // }

    // function testCollectRefund_InsufficientBuyerPayment() public {
    //     vm.prank(buyer1);
    //     ps.purchase{value: price *  6 }(6, 'randomAddress');

    //     uint32 orderNo = ps.buyersOrder(buyer1, 0);

    //     vm.prank(ownerAddr);
    //     ps.setCancelAndRefund(orderNo);

    //     vm.prank(buyer1);
    //     ps.collectRefund(orderNo);
        
    //     vm.expectRevert(
    //         abi.encodeWithSelector(
    //             PenguStore.InsufficientBuyerPayment.selector, orderNo)
    //     );
    //     vm.prank(buyer1);
    //     ps.collectRefund(orderNo);
    // }

    // function testCollectRefund_AlreadyShipped() public {
    //     vm.prank(buyer1);
    //     ps.purchase{value: price *  9 }(9, 'randomAddress');

    //     uint32 orderNo = ps.buyersOrder(buyer1, 0);

    //     vm.prank(ownerAddr);
    //     ps.processShipment(orderNo);

    //     vm.expectRevert(
    //         abi.encodeWithSelector(
    //             PenguStore.AlreadyShipped.selector, orderNo)
    //     );
    //     vm.prank(buyer1);
    //     ps.collectRefund(orderNo);
    // }

    // function testCollectRefund_OrderedNotCancelled() public {
    //     vm.prank(buyer1);
    //     ps.purchase{value: price *  9 }(9, 'randomAddress');

    //     uint32 orderNo = ps.buyersOrder(buyer1, 0);

    //     vm.expectRevert(
    //         abi.encodeWithSelector(
    //             PenguStore.OrderNotCancelled.selector, orderNo)
    //     );
    //     vm.prank(buyer1);
    //     ps.collectRefund(orderNo);
    // }
}

//    error OwnableInvalidOwner(address owner);
