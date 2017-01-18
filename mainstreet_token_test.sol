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

}
