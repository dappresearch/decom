// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.20;

import {Test, console} from "forge-std/Test.sol";

import "../src/PenguStore.sol";

contract PenguStoreTest is Test {
    PenguStore public ps;

    address ownerAddr;
    
    uint256 price = 13207547169811320 wei;

    function setUp() public {
        ownerAddr = address(1);
        ps = new PenguStore(ownerAddr);
        vm.label(ownerAddr, "Owner Address");
        vm.startPrank(ownerAddr);
        ps.setStock(300);
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
                address(2)
            )
        );
        vm.prank(address(2));
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
                address(2)
            )
        );
        vm.prank(address(2));
        ps.setStock(300);
    }
    
    function testPurchase_InvalidQauntity() public {
         uint16 orderStock = 301;
         vm.expectRevert(
            abi.encodeWithSelector(
                PenguStore.InvalidQuantity.selector,
                orderStock
            )
        );
        vm.prank(address(2));
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

    function purchase() public {

    }


    // function purchase_test() public {
    // }
}

//    error OwnableInvalidOwner(address owner);
