// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.20;

import {Test, console} from "forge-std/Test.sol";
import "../src/PenguStore.sol";

contract PenguStoreTest is Test {
    PenguStore public ps;

    address ownerAddr;

    address buyer1;

    uint16 constant STOCK = 300;

    //$35 per cap base on 1 ether = 2650
    uint256 price = 13207547169811320 wei;

    function setUp() public {
        ownerAddr = address(1);
        buyer1 = address(2);

        vm.prank(buyer1);
        ps = new PenguStore(ownerAddr);
        vm.label(ownerAddr, "Owner Address");
       
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

    function testSetPrice() public  {
        vm.prank(ownerAddr);
        ps.setPrice(300);
        assertEq(ps.price(), 300);
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
        ps.setStock(300);
    }
    
    function testPurchase_InvalidQuantity() public {
         uint16 orderStock = 301;
         vm.expectRevert(
            abi.encodeWithSelector(
                PenguStore.InvalidQuantity.selector,
                orderStock
            )
        );
        vm.prank(buyer1);
        ps.purchase(orderStock, "randomAddress");
    }

    function testPurchase_InvalidAmount() public {
         uint8 orderPrice = 1 wei ;
         vm.expectRevert(
            abi.encodeWithSelector(
                PenguStore.InvalidAmount.selector,
                orderPrice
            )
        );

        ps.purchase{value: orderPrice }(2, "randomAddress");
    }

    function testPurchase() public {
        uint8 orderQty = 1;
      
        vm.prank(buyer1);
        vm.deal(buyer1, 1 ether);
        ps.purchase{value: price }(orderQty, 'randomAddress');

        (string memory shippingAddr,
        uint256 quantity,
        uint256 amount,
        address buyerAddr,
        bool isShipped,
        bool cancelAndRefund) = ps.getOrderDetails(ps.orderNo() - 1);

        assertEq(shippingAddr, 'randomAddress');
        assertEq(quantity, orderQty);
        assertEq(amount, price);
        assertEq(buyerAddr, buyer1);
        assertEq(shippingAddr, 'randomAddress');
        assertEq(isShipped, false);
        assertEq(cancelAndRefund, false);

        assertEq(ps.payments(buyer1), price);

        uint256[] memory getOrders = ps.getOrder(buyer1);
        assertEq(getOrders.length, 1);

        assertEq(ps.totalPayment(), price);
        assertEq(ps.totalStock(), STOCK - orderQty);
    }

    function testPurchase_MultipleOrder() public {
        uint8 orderQty = 59;

        uint256 orderAmount = orderQty * price;

        vm.prank(buyer1);
        vm.deal(buyer1, 1 ether);
        ps.purchase{value: orderAmount }(orderQty, 'randomAddress');

        (string memory shippingAddr,
        uint256 quantity,
        uint256 amount,
        address buyerAddr,
        bool isShipped,
        bool cancelAndRefund) = ps.getOrderDetails(ps.orderNo() - 1);

        assertEq(shippingAddr, 'randomAddress');
        assertEq(quantity, orderQty);
        assertEq(amount, orderAmount);
        assertEq(buyerAddr, buyer1);
        assertEq(shippingAddr, 'randomAddress');
        assertEq(isShipped, false);
        assertEq(cancelAndRefund, false);

        assertEq(ps.payments(buyer1), orderAmount);

        uint256[] memory getOrders = ps.getOrder(buyer1);
        assertEq(getOrders.length, 1);

        assertEq(ps.totalPayment(), orderAmount);
        assertEq(ps.totalStock(), STOCK - orderQty);
    }



}

//    error OwnableInvalidOwner(address owner);