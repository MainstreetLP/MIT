pragma solidity ^0.4.8;

import "dapple/test.sol";
import "./mainstreet_crowdfund.sol";
import "./mainstreet_token.sol";


contract SenderProxy {

    MainstreetCrowdfund mainstreetCrowdfund;

    function SenderProxy(MainstreetCrowdfund _mainstreetCrowdfund) {
        mainstreetCrowdfund = _mainstreetCrowdfund;
    }
    
    function() payable {
    }
    
    function purchaseMIT() {
        mainstreetCrowdfund.purchaseMIT.value(1 ether)(0);
    }
}

/**
 * @title MainstreetCrowdfundTest
 */
contract MainstreetCrowdfundTest is Test {

    MainstreetCrowdfund mainstreetCrowdfund;
    MainstreetToken mainstreetToken;

    uint start;
    uint end;
    
    address intellisys = 0x1234;
    address exitAddress = 0x5678;

    address whitelist2 = 0x9abc;
    address whitelist3 = 0xdef0;

    address recipient1 = 0x1111;
    address recipient2 = 0x2222;

    function setUp() {
        start = block.timestamp;
        end = start + 5184000;
        mainstreetCrowdfund = new MainstreetCrowdfund(start, end, 10 ether, 4 ether, 5 ether, exitAddress, this, whitelist2, whitelist3);
        mainstreetToken = new MainstreetToken(mainstreetCrowdfund, intellisys, end);
        mainstreetCrowdfund.setTokenContract(mainstreetToken);
    }

    function testInitialState() {
        assertEq(mainstreetCrowdfund.creator(), this);
        assertEq(mainstreetCrowdfund.start(), start);
        assertEq(mainstreetCrowdfund.end(), start + 5184000);
        assertEq(mainstreetCrowdfund.limitETH(), 10 ether);
        assertEq(mainstreetCrowdfund.bonus1StartETH(), 4 ether);
        assertEq(mainstreetCrowdfund.bonus2StartETH(), 5 ether);
        assertEq(mainstreetCrowdfund.whitelistedAddresses(this), true);
        assertEq(mainstreetCrowdfund.whitelistedAddresses(whitelist2), true);
        assertEq(mainstreetCrowdfund.whitelistedAddresses(whitelist3), true);
        assertEq(mainstreetCrowdfund.exitAddress(), exitAddress);
        assertEq(mainstreetCrowdfund.mainstreetToken(), mainstreetToken);

        assertEq(mainstreetToken.start(), start + 5184000);
        assertEq(mainstreetToken.mainstreetCrowdfund(), mainstreetCrowdfund);
        assertEq(mainstreetToken.intellisys(), intellisys);
    }

    function testThrowsSenderNotWhitelisted1() {
        mainstreetCrowdfund.purchaseMIT.value(1 ether)(mainstreetCrowdfund);
    }

    function testThrowsSenderNotWhitelisted2() {
        SenderProxy senderProxy = new SenderProxy(mainstreetCrowdfund);
        if (!senderProxy.send(1 ether)) {
            throw;
        }
        senderProxy.purchaseMIT();
    }

    function testThrowsPurchaseMitLimit() {
        mainstreetCrowdfund.purchaseMIT.value(9 ether)(0x1234);
        mainstreetCrowdfund.purchaseMIT.value(2 ether)(0x1234);
    }

    function testThrowPurchaseNoValue() {
        mainstreetCrowdfund.purchaseMIT(this);
    }

    function testPurchaseMit() {
        uint MIT = mainstreetCrowdfund.purchaseMIT.value(1 ether)(recipient1);
        assertEq(MIT, 11 ether);
        assertEq(exitAddress.balance, 1 ether);
        assertEq(mainstreetCrowdfund.senderETH(this), 1 ether);
        assertEq(mainstreetCrowdfund.senderMIT(this), 11 ether);
        assertEq(mainstreetCrowdfund.recipientETH(recipient1), 1 ether);
        assertEq(mainstreetCrowdfund.recipientMIT(recipient1), 11 ether);
        assertEq(mainstreetCrowdfund.recipientETH(recipient2), 0);
        assertEq(mainstreetCrowdfund.recipientMIT(recipient2), 0);
        assertEq(mainstreetCrowdfund.recipientExtraMIT(recipient1), 0);
        assertEq(mainstreetCrowdfund.recipientExtraMIT(recipient2), 0);
        assertEq(mainstreetCrowdfund.totalETH(), 1 ether);
        assertEq(mainstreetToken.balanceOf(recipient1), 11 ether);
        assertEq(mainstreetToken.balanceOf(recipient2), 0 ether);
        assertEq(mainstreetToken.balanceOf(intellisys), 1.1 ether);
        assertEq(mainstreetToken.totalSupply(), 12.1 ether);

        MIT = mainstreetCrowdfund.purchaseMIT.value(2 ether)(recipient1);
        assertEq(MIT, 22 ether);
        assertEq(exitAddress.balance, 3 ether);
        assertEq(mainstreetCrowdfund.senderETH(this), 3 ether);
        assertEq(mainstreetCrowdfund.senderMIT(this), 33 ether);
        assertEq(mainstreetCrowdfund.recipientETH(recipient1), 3 ether);
        assertEq(mainstreetCrowdfund.recipientMIT(recipient1), 33 ether);
        assertEq(mainstreetCrowdfund.recipientETH(recipient2), 0);
        assertEq(mainstreetCrowdfund.recipientMIT(recipient2), 0);
        assertEq(mainstreetCrowdfund.recipientExtraMIT(recipient1), 0);
        assertEq(mainstreetCrowdfund.recipientExtraMIT(recipient2), 0);
        assertEq(mainstreetCrowdfund.totalETH(), 3 ether);
        assertEq(mainstreetToken.balanceOf(recipient1), 33 ether);
        assertEq(mainstreetToken.balanceOf(recipient2), 0 ether);
        assertEq(mainstreetToken.balanceOf(intellisys), 3.3 ether);
        assertEq(mainstreetToken.totalSupply(), 36.3 ether);

        MIT = mainstreetCrowdfund.purchaseMIT.value(2 ether)(recipient2);
        assertEq(MIT, 22 ether);
        assertEq(exitAddress.balance, 5 ether);
        assertEq(mainstreetCrowdfund.senderETH(this), 5 ether);
        assertEq(mainstreetCrowdfund.senderMIT(this), 55 ether);
        assertEq(mainstreetCrowdfund.recipientETH(recipient1), 3 ether);
        assertEq(mainstreetCrowdfund.recipientMIT(recipient1), 33 ether);
        assertEq(mainstreetCrowdfund.recipientETH(recipient2), 2 ether);
        assertEq(mainstreetCrowdfund.recipientMIT(recipient2), 22 ether);
        assertEq(mainstreetCrowdfund.recipientExtraMIT(recipient1), 0);
        assertEq(mainstreetCrowdfund.recipientExtraMIT(recipient2), 0);
        assertEq(mainstreetCrowdfund.totalETH(), 5 ether);
        assertEq(mainstreetToken.balanceOf(recipient1), 33 ether);
        assertEq(mainstreetToken.balanceOf(recipient2), 22 ether);
        assertEq(mainstreetToken.balanceOf(intellisys), 5.5 ether);
        assertEq(mainstreetToken.totalSupply(), 60.5 ether);

        MIT = mainstreetCrowdfund.purchaseMIT.value(2 ether)(recipient2);
        assertEq(MIT, 23.76 ether);
        assertEq(exitAddress.balance, 7 ether);
        assertEq(mainstreetCrowdfund.senderETH(this), 7 ether);
        assertEq(mainstreetCrowdfund.senderMIT(this), 77 ether);
        assertEq(mainstreetCrowdfund.recipientETH(recipient1), 3 ether);
        assertEq(mainstreetCrowdfund.recipientMIT(recipient1), 33 ether);
        assertEq(mainstreetCrowdfund.recipientETH(recipient2), 4 ether);
        assertEq(mainstreetCrowdfund.recipientMIT(recipient2), 44 ether);
        assertEq(mainstreetCrowdfund.recipientExtraMIT(recipient1), 0);
        assertEq(mainstreetCrowdfund.recipientExtraMIT(recipient2), 1.76 ether);
        assertEq(mainstreetCrowdfund.totalETH(), 7 ether);
        assertEq(mainstreetToken.balanceOf(recipient1), 33 ether);
        assertEq(mainstreetToken.balanceOf(recipient2), 45.76 ether);
        assertEq(mainstreetToken.balanceOf(intellisys), 7.876 ether);
        assertEq(mainstreetToken.totalSupply(), 86.636 ether);

        MIT = mainstreetCrowdfund.purchaseMIT.value(2 ether)(recipient2);
        assertEq(MIT, 25.52 ether);
        assertEq(exitAddress.balance, 9 ether);
        assertEq(mainstreetCrowdfund.senderETH(this), 9 ether);
        assertEq(mainstreetCrowdfund.senderMIT(this), 99 ether);
        assertEq(mainstreetCrowdfund.recipientETH(recipient1), 3 ether);
        assertEq(mainstreetCrowdfund.recipientMIT(recipient1), 33 ether);
        assertEq(mainstreetCrowdfund.recipientETH(recipient2), 6 ether);
        assertEq(mainstreetCrowdfund.recipientMIT(recipient2), 66 ether);
        assertEq(mainstreetCrowdfund.recipientExtraMIT(recipient1), 0);
        assertEq(mainstreetCrowdfund.recipientExtraMIT(recipient2), 5.28 ether);
        assertEq(mainstreetCrowdfund.totalETH(), 9 ether);
        assertEq(mainstreetToken.balanceOf(recipient1), 33 ether);
        assertEq(mainstreetToken.balanceOf(recipient2), 71.28 ether);
        assertEq(mainstreetToken.balanceOf(intellisys), 10.428 ether);
        assertEq(mainstreetToken.totalSupply(), 114.708 ether);
    }

}

/**
 * @title MainstreetCrowdfundOverTest
 */
contract MainstreetCrowdfundNoTokenTest is Test {

    MainstreetCrowdfund mainstreetCrowdfund;

    uint start;
    uint end;
    
    address intellisys = 0x1234;
    address exitAddress = 0x5678;

    address whitelist2 = 0x9abc;
    address whitelist3 = 0xdef0;

    address recipient1 = 0x1111;
    address recipient2 = 0x2222;

    function setUp() {
        start = block.timestamp;
        end = start + 5184000;
        mainstreetCrowdfund = new MainstreetCrowdfund(start, end, 10 ether, 4 ether, 5 ether, exitAddress, this, whitelist2, whitelist3);
    }

    function testInitialState() {
        assertEq(mainstreetCrowdfund.creator(), this);
        assertEq(mainstreetCrowdfund.start(), start);
        assertEq(mainstreetCrowdfund.end(), start + 5184000);
        assertEq(mainstreetCrowdfund.limitETH(), 10 ether);
        assertEq(mainstreetCrowdfund.bonus1StartETH(), 4 ether);
        assertEq(mainstreetCrowdfund.bonus2StartETH(), 5 ether);
        assertEq(mainstreetCrowdfund.whitelistedAddresses(this), true);
        assertEq(mainstreetCrowdfund.whitelistedAddresses(whitelist2), true);
        assertEq(mainstreetCrowdfund.whitelistedAddresses(whitelist3), true);
        assertEq(mainstreetCrowdfund.exitAddress(), exitAddress);
    }

    function testThrowsNoToken() {
        uint MIT = mainstreetCrowdfund.purchaseMIT.value(1 ether)(recipient1);
    }

}

/**
 * @title MainstreetCrowdfundOverTest
 */
contract MainstreetCrowdfundOverTest is Test {

    MainstreetCrowdfund mainstreetCrowdfund;
    MainstreetToken mainstreetToken;

    uint start;
    uint end;

    address intellisys = 0x1234;
    address exitAddress = 0x5678;

    address whitelist2 = 0x9abc;
    address whitelist3 = 0xdef0;

    address recipient1 = 0x1111;
    address recipient2 = 0x2222;

    function setUp() {
        start = block.timestamp - 200;
        end = start + 100;
        mainstreetCrowdfund = new MainstreetCrowdfund(start, end, 10 ether, 2 ether, 5 ether, exitAddress, this, whitelist2, whitelist3);
        mainstreetToken = new MainstreetToken(mainstreetCrowdfund, intellisys, end);
        mainstreetCrowdfund.setTokenContract(mainstreetToken);
    }

    function testInitialState() {
        assertEq(mainstreetCrowdfund.creator(), this);
        assertEq(mainstreetCrowdfund.start(), start);
        assertEq(mainstreetCrowdfund.end(), start + 100);
        assertEq(mainstreetCrowdfund.limitETH(), 10 ether);
        assertEq(mainstreetCrowdfund.bonus1StartETH(), 2 ether);
        assertEq(mainstreetCrowdfund.bonus2StartETH(), 5 ether);
        assertEq(mainstreetCrowdfund.whitelistedAddresses(this), true);
        assertEq(mainstreetCrowdfund.whitelistedAddresses(whitelist2), true);
        assertEq(mainstreetCrowdfund.whitelistedAddresses(whitelist3), true);
        assertEq(mainstreetCrowdfund.exitAddress(), exitAddress);
        assertEq(mainstreetCrowdfund.mainstreetToken(), mainstreetToken);

        assertEq(mainstreetToken.start(), start + 100);
        assertEq(mainstreetToken.mainstreetCrowdfund(), mainstreetCrowdfund);
        assertEq(mainstreetToken.intellisys(), intellisys);
    }

    function testThrowsSaleIsOver() {
        uint MIT = mainstreetCrowdfund.purchaseMIT.value(1 ether)(recipient1);
    }

}
