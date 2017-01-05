pragma solidity ^0.4.7;

import "dapple/test.sol";
import "./mainstreet_crowdfund.sol";


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

    uint start;
    uint end;
    
    address exitAddress = 0x5678;

    function setUp() {
        start = block.timestamp;
        end = start + 5184000;
        mainstreetCrowdfund = new MainstreetCrowdfund(start, end, 10 ether, exitAddress, this, 0, 0);
    }

    function testThrowPurchaseNoValue() {
        mainstreetCrowdfund.purchaseMIT(this);
    }

    function testPurchaseMit() {
        address recipient1 = 0x1234;
        address recipient2 = 0x1235;

        uint MIT = mainstreetCrowdfund.purchaseMIT.value(1 ether)(recipient1);
        assertEq(MIT, 8888888888888888888);
        assertEq(exitAddress.balance, 1 ether);
        assertEq(mainstreetCrowdfund.senderETH(this), 1 ether);
        assertEq(mainstreetCrowdfund.senderMIT(this), 8888888888888888888);
        assertEq(mainstreetCrowdfund.recipientETH(recipient1), 1 ether);
        assertEq(mainstreetCrowdfund.recipientMIT(recipient1), 8888888888888888888);
        assertEq(mainstreetCrowdfund.recipientETH(recipient2), 0);
        assertEq(mainstreetCrowdfund.recipientMIT(recipient2), 0);
        assertEq(mainstreetCrowdfund.totalETH(), 1 ether);
        assertEq(mainstreetCrowdfund.totalMIT(), 8888888888888888888);

        MIT = mainstreetCrowdfund.purchaseMIT.value(2 ether)(recipient1);
        assertEq(MIT, 17777777777777777777);
        assertEq(exitAddress.balance, 3 ether);
        assertEq(mainstreetCrowdfund.senderETH(this), 3 ether);
        assertEq(mainstreetCrowdfund.senderMIT(this), 26666666666666666665);
        assertEq(mainstreetCrowdfund.recipientETH(recipient1), 3 ether);
        assertEq(mainstreetCrowdfund.recipientMIT(recipient1), 26666666666666666665);
        assertEq(mainstreetCrowdfund.recipientETH(recipient2), 0);
        assertEq(mainstreetCrowdfund.recipientMIT(recipient2), 0);
        assertEq(mainstreetCrowdfund.totalETH(), 3 ether);
        assertEq(mainstreetCrowdfund.totalMIT(), 26666666666666666665);

        MIT = mainstreetCrowdfund.purchaseMIT.value(2 ether)(recipient2);
        assertEq(MIT, 17777777777777777777);
        assertEq(exitAddress.balance, 5 ether);
        assertEq(mainstreetCrowdfund.senderETH(this), 5 ether);
        assertEq(mainstreetCrowdfund.senderMIT(this), 44444444444444444442);
        assertEq(mainstreetCrowdfund.recipientETH(recipient1), 3 ether);
        assertEq(mainstreetCrowdfund.recipientMIT(recipient1), 26666666666666666665);
        assertEq(mainstreetCrowdfund.recipientETH(recipient2), 2 ether);
        assertEq(mainstreetCrowdfund.recipientMIT(recipient2), 17777777777777777777);
        assertEq(mainstreetCrowdfund.totalETH(), 5 ether);
        assertEq(mainstreetCrowdfund.totalMIT(), 44444444444444444442);
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
