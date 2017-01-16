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

    function setUp() {
        start = block.timestamp;
        end = start + 5184000;
        mainstreetCrowdfund = new MainstreetCrowdfund(start, end, 10 ether, exitAddress, this, 0, 0);
        mainstreetToken = new MainstreetToken(mainstreetCrowdfund, intellisys, end);
        mainstreetCrowdfund.setTokenContract(mainstreetToken);
    }

    function testThrowPurchaseNoValue() {
        mainstreetCrowdfund.purchaseMIT(this);
    }

    function testPurchaseMit() {
        address recipient1 = 0x1234;
        address recipient2 = 0x1235;

        uint MIT = mainstreetCrowdfund.purchaseMIT.value(1 ether)(recipient1);
        assertEq(MIT, 11 ether);
        assertEq(exitAddress.balance, 1 ether);
        assertEq(mainstreetCrowdfund.senderETH(this), 1 ether);
        assertEq(mainstreetCrowdfund.senderMIT(this), 11 ether);
        assertEq(mainstreetCrowdfund.recipientETH(recipient1), 1 ether);
        assertEq(mainstreetCrowdfund.recipientMIT(recipient1), 11 ether);
        assertEq(mainstreetCrowdfund.recipientETH(recipient2), 0);
        assertEq(mainstreetCrowdfund.recipientMIT(recipient2), 0);
        assertEq(mainstreetCrowdfund.totalETH(), 1 ether);

        MIT = mainstreetCrowdfund.purchaseMIT.value(2 ether)(recipient1);
        assertEq(MIT, 22 ether);
        assertEq(exitAddress.balance, 3 ether);
        assertEq(mainstreetCrowdfund.senderETH(this), 3 ether);
        assertEq(mainstreetCrowdfund.senderMIT(this), 33 ether);
        assertEq(mainstreetCrowdfund.recipientETH(recipient1), 3 ether);
        assertEq(mainstreetCrowdfund.recipientMIT(recipient1), 33 ether);
        assertEq(mainstreetCrowdfund.recipientETH(recipient2), 0);
        assertEq(mainstreetCrowdfund.recipientMIT(recipient2), 0);
        assertEq(mainstreetCrowdfund.totalETH(), 3 ether);

        MIT = mainstreetCrowdfund.purchaseMIT.value(2 ether)(recipient2);
        assertEq(MIT, 22 ether);
        assertEq(exitAddress.balance, 5 ether);
        assertEq(mainstreetCrowdfund.senderETH(this), 5 ether);
        assertEq(mainstreetCrowdfund.senderMIT(this), 55 ether);
        assertEq(mainstreetCrowdfund.recipientETH(recipient1), 3 ether);
        assertEq(mainstreetCrowdfund.recipientMIT(recipient1), 33 ether);
        assertEq(mainstreetCrowdfund.recipientETH(recipient2), 2 ether);
        assertEq(mainstreetCrowdfund.recipientMIT(recipient2), 22 ether);
        assertEq(mainstreetCrowdfund.totalETH(), 5 ether);
    }

    function testThrowsPurchaseMitLimit() {
        mainstreetCrowdfund.purchaseMIT.value(6 ether)(0);
        mainstreetCrowdfund.purchaseMIT.value(5 ether)(0);
    }

    function testThrowsSenderNotWhitelisted() {
    
        SenderProxy senderProxy = new SenderProxy(mainstreetCrowdfund);
        if (!senderProxy.send(1 ether)) {
            throw;
        }
        senderProxy.purchaseMIT();
    }

}
