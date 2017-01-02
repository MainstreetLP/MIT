pragma solidity ^0.4.7;

/**
 * @title MainstreetCrowdfund
 * @author Jonathan Brown <jbrown@bluedroplet.com>
 */
contract MainstreetCrowdfund {
    
    uint public start;
    uint public end;

    mapping (address => uint) public senderETH;
    mapping (address => uint) public senderMIT;
    mapping (address => uint) public recipientETH;
    mapping (address => uint) public recipientMIT;

    uint public totalETH;
    uint public totalMIT;
    
    uint public limit;

    mapping (address => bool) public whitelistedAddresses;
    
    address exitAddress;

    event MITPurchase(address indexed sender, address indexed recipient, uint ETH, uint MIT);

    modifier saleActive() {
        if (block.timestamp < start || block.timestamp >= end) {
            throw;
        }
        if (totalMIT >= 50000000 ether) {    // ether is just a multiplier
            throw;
        }
        _;
    }

    modifier hasValue() {
        if (msg.value == 0) {
            throw;
        }
        _;
    }
    
    modifier senderIsWhitelisted() {
        if (whitelistedAddresses[msg.sender] != true) {
            throw;
        }
        _;
    }
    
    function MainstreetCrowdfund(uint _start, uint _end, uint _limit, address _exitAddress, address whitelist1, address whitelist2) {
        start = _start;
        end = _end;
        limit = _limit;
        
        whitelistedAddresses[whitelist1] = true;
        whitelistedAddresses[whitelist2] = true;
        exitAddress = _exitAddress;
    }
    
    function purchaseMIT(address recipient) payable saleActive hasValue senderIsWhitelisted returns (uint MIT) {
        
        if (!exitAddress.send(msg.value)) {
            throw;
        }
        
        if (recipient == 0) {
            recipient = msg.sender;
        }
        
        MIT = msg.value * 8;
        uint extra;
        if (msg.value >= 250000 ether) {        // ether is just a multiplier
            extra = (MIT / 1000) * 75;      // 7.5%
        }
        else if (msg.value >= 62500 ether) {    // ether is just a multiplier
            extra = (MIT / 10000) * 375;    // 3.75%
        }
        
        if (block.timestamp - start < 1 weeks) {
            extra += MIT / 10;              // 10%
        }
        else if (block.timestamp - start < 5 weeks) {
            extra += MIT / 20;              // 5%
        }

        MIT += extra;
        senderETH[msg.sender] += msg.value;
        senderMIT[msg.sender] += MIT;
        recipientETH[recipient] += msg.value;
        recipientMIT[recipient] += MIT;
        totalETH += msg.value;
        totalMIT += MIT;
        MITPurchase(msg.sender, recipient, msg.value, MIT);
    }

}
