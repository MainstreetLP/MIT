pragma solidity ^0.4.8;

import "dapple/test.sol";
import "./mainstreet_token.sol";


contract MainstreetTokenNotActiveNotFromCrowdfund is Test {

    MainstreetToken mainstreetToken;

    uint start;

    address crowdfund = 0x5678;
    address intellisys = 0x1234;

    function setUp() {
        start = block.timestamp + 20000;
        mainstreetToken = new MainstreetToken(crowdfund, intellisys, start, false);
    }

    function testInitialState() {
        assertEq(mainstreetToken.start(), start);
        assertEq(mainstreetToken.mainstreetCrowdfund(), crowdfund);
        assertEq(mainstreetToken.intellisys(), intellisys);
    }

    function testThrowsAddTokens() {
        mainstreetToken.addTokens(this, 1 ether);
    }

}


contract MainstreetTokenNotActiveTest is Test {

    MainstreetToken mainstreetToken;

    uint start;

    address intellisys = 0x1234;

    address recipient1 = 0x1111;
    address recipient2 = 0x2222;

    function setUp() {
        start = block.timestamp + 20000;
        mainstreetToken = new MainstreetToken(this, intellisys, start, false);
    }

    function testInitialState() {
        assertEq(mainstreetToken.start(), start);
        assertEq(mainstreetToken.mainstreetCrowdfund(), this);
        assertEq(mainstreetToken.intellisys(), intellisys);
    }

    function testAddTokens() {
        mainstreetToken.addTokens(recipient1, 1 ether);
        assertEq(mainstreetToken.balanceOf(recipient1), 1 ether);
        assertEq(mainstreetToken.balanceOf(recipient2), 0);
        assertEq(mainstreetToken.balanceOf(intellisys), 0.1 ether);
        assertEq(mainstreetToken.totalSupply(), 1.1 ether);

        mainstreetToken.addTokens(recipient2, 5 ether);
        assertEq(mainstreetToken.balanceOf(recipient1), 1 ether);
        assertEq(mainstreetToken.balanceOf(recipient2), 5 ether);
        assertEq(mainstreetToken.balanceOf(intellisys), 0.6 ether);
        assertEq(mainstreetToken.totalSupply(), 6.6 ether);

        mainstreetToken.addTokens(recipient2, 3 ether);
        assertEq(mainstreetToken.balanceOf(recipient1), 1 ether);
        assertEq(mainstreetToken.balanceOf(recipient2), 8 ether);
        assertEq(mainstreetToken.balanceOf(intellisys), 0.9 ether);
        assertEq(mainstreetToken.totalSupply(), 9.9 ether);
    }


    function testThrowsTransfer() {
        mainstreetToken.addTokens(this, 1 ether);
        mainstreetToken.transfer(recipient1, 0.2 ether);
    }

    function testThrowsApprove() {
        mainstreetToken.approve(recipient1, 4 ether);
    }

}


contract MainstreetTokenActiveTest is Test {

    MainstreetToken mainstreetToken;

    uint start;

    address intellisys = 0x1234;

    address recipient1 = 0x1111;
    address recipient2 = 0x2222;

    function setUp() {
        start = block.timestamp;
        mainstreetToken = new MainstreetToken(this, intellisys, start, false);
    }

    function testInitialState() {
        assertEq(mainstreetToken.start(), start);
        assertEq(mainstreetToken.mainstreetCrowdfund(), this);
        assertEq(mainstreetToken.intellisys(), intellisys);
    }

    function testThrowsAddTokens() {
        mainstreetToken.addTokens(recipient1, 1 ether);
    }

}

contract MainstreetTokenTestingModeTest is Test {

    MainstreetToken mainstreetToken;

    uint start;

    address intellisys = 0x1234;

    address recipient1 = 0x1111;
    address recipient2 = 0x2222;

    function setUp() {
        start = block.timestamp;
        mainstreetToken = new MainstreetToken(this, intellisys, start, true);
    }

    function testInitialState() {
        assertEq(mainstreetToken.start(), start);
        assertEq(mainstreetToken.mainstreetCrowdfund(), this);
        assertEq(mainstreetToken.intellisys(), intellisys);
    }

    function testTransfer() {
        mainstreetToken.addTokens(this, 1 ether);
        assertEq(mainstreetToken.balanceOf(this), 1 ether);
        assertEq(mainstreetToken.balanceOf(recipient1), 0);
        assertEq(mainstreetToken.balanceOf(intellisys), 0.1 ether);
        assertEq(mainstreetToken.totalSupply(), 1.1 ether);

        mainstreetToken.transfer(recipient1, 0.2 ether);
        assertEq(mainstreetToken.balanceOf(this), 0.8 ether);
        assertEq(mainstreetToken.balanceOf(recipient1), 0.2 ether);
        assertEq(mainstreetToken.balanceOf(intellisys), 0.1 ether);
        assertEq(mainstreetToken.totalSupply(), 1.1 ether);
    }

    function testThrowsTransferRecipientIsZero() {
        mainstreetToken.addTokens(this, 1 ether);
        mainstreetToken.transfer(0, 0.2 ether);
    }

    function testThrowsTransferRecipientIsTokenContract() {
        mainstreetToken.addTokens(this, 1 ether);
        mainstreetToken.transfer(mainstreetToken, 0.2 ether);
    }

    function testApprove() {
        mainstreetToken.approve(recipient1, 4 ether);
        assertEq(mainstreetToken.allowance(this, recipient1), 4 ether);
        assertEq(mainstreetToken.allowance(this, recipient2), 0 ether);
        mainstreetToken.approve(recipient2, 3 ether);
        assertEq(mainstreetToken.allowance(this, recipient1), 4 ether);
        assertEq(mainstreetToken.allowance(this, recipient2), 3 ether);
        mainstreetToken.approve(recipient1, 0 ether);
        assertEq(mainstreetToken.allowance(this, recipient1), 0 ether);
        assertEq(mainstreetToken.allowance(this, recipient2), 3 ether);
        mainstreetToken.approve(recipient1, 5 ether);
        assertEq(mainstreetToken.allowance(this, recipient1), 5 ether);
        assertEq(mainstreetToken.allowance(this, recipient2), 3 ether);
    }

    function testThrowsApproveAllowanceNotZero() {
        mainstreetToken.approve(recipient1, 4 ether);
        mainstreetToken.approve(recipient1, 5 ether);
    }

    function testTransferFrom() {
        mainstreetToken.addTokens(this, 1 ether);
        assertEq(mainstreetToken.balanceOf(this), 1 ether);
        assertEq(mainstreetToken.balanceOf(recipient1), 0);
        mainstreetToken.approve(this, 1 ether);
        mainstreetToken.transferFrom(this, recipient1, 1 ether);
        assertEq(mainstreetToken.balanceOf(this), 0);
        assertEq(mainstreetToken.balanceOf(recipient1), 1 ether);
    }

    function testThrowsTransferFromRecipientIsZero() {
        mainstreetToken.addTokens(this, 1 ether);
        mainstreetToken.approve(this, 1 ether);
        mainstreetToken.transferFrom(this, 0, 1 ether);
    }

    function testThrowsTransferFromRecipientIsTokenContract() {
        mainstreetToken.addTokens(this, 1 ether);
        mainstreetToken.approve(this, 1 ether);
        mainstreetToken.transferFrom(this, mainstreetToken, 1 ether);
    }

    function testThrowsTransferFromNotEnough() {
        mainstreetToken.addTokens(this, 1 ether);
        mainstreetToken.approve(this, 2 ether);
        mainstreetToken.transferFrom(this, recipient1, 2 ether);
    }

    function testThrowsTransferFromNotEnoughApproved() {
        mainstreetToken.addTokens(this, 2 ether);
        mainstreetToken.approve(this, 1 ether);
        mainstreetToken.transferFrom(this, recipient1, 2 ether);
    }

}
