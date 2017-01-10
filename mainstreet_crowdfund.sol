pragma solidity ^0.4.7;

/**
 * @title MainstreetCrowdfund
 */
contract MainstreetCrowdfund {
    
    uint public start;
    uint public end;

    mapping (address => uint) public senderETH;
    mapping (address => uint) public senderMIT;
    mapping (address => uint) public recipientETH;
    mapping (address => uint) public recipientMIT;
    mapping (address => uint) public recipientExtraMIT;

    uint public totalETH;
    uint public totalMIT;
    
    uint public limit;

    mapping (address => bool) public whitelistedAddresses;
    
    address public exitAddress;

    event MITPurchase(address indexed sender, address indexed recipient, uint ETH, uint MIT);

    modifier saleActive() {
        if (block.timestamp < start || block.timestamp >= end) {
            throw;
        }
        if (totalETH + msg.value > limit) {
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
    
    modifier recipientIsNotThis(address recipient) {
        if (recipient == address(this)) {
            throw;
        }
        _;
    }

    /**
     * @dev Constructor.
     * @param _start Timestamp of when the crowdsale will start.
     * @param _end Timestamp of when the crowdsale will end.
     * @param _limit Maximum amount of ETH that can be sent to the contract in total. Specified in wei.
     * @param _exitAddress Address that all ETH should be forwarded to.
     * @param whitelist1 First address that can send ETH.
     * @param whitelist2 Second address that can send ETH.
     * @param whitelist3 Third address that can send ETH.
     */
    function MainstreetCrowdfund(uint _start, uint _end, uint _limit, address _exitAddress, address whitelist1, address whitelist2, address whitelist3) {
        start = _start;
        end = _end;
        limit = _limit;
        
        whitelistedAddresses[whitelist1] = true;
        whitelistedAddresses[whitelist2] = true;
        whitelistedAddresses[whitelist3] = true;
        exitAddress = _exitAddress;
    }
    
    /**
     * @dev Forward Ether to the exit address. Store all ETH and MIT information in public state and logs.
     * @param recipient Address that tokens should be attributed to.
     * @return MIT Amount of MIT purchased. This does not include the per-recipient quantity bonus.
     */
    function purchaseMIT(address recipient) external senderIsWhitelisted payable saleActive hasValue recipientIsNotThis(recipient) returns (uint MIT) {
        
        // Attempt to send the ETH to the exit address.
        if (!exitAddress.send(msg.value)) {
            throw;
        }
        
        uint costPerMIT;
        
        if (block.timestamp - start < 1 weeks) {
            costPerMIT = 1125 ether / 10000;    // 0.1125 ETH per MIT (10% discount)
        }
        else if (block.timestamp - start < 5 weeks) {
            costPerMIT = 11875 ether / 100000;  // 0.11875 ETH per MIT (5% discount)
        }
        else {
            costPerMIT = 125 ether / 1000;      // 0.125 ETH per MIT
        }

        MIT = (msg.value * 1 ether) / costPerMIT;
        senderETH[msg.sender] += msg.value;
        senderMIT[msg.sender] += MIT;
        recipientETH[recipient] += msg.value;
        recipientMIT[recipient] += MIT;

        uint oldExtra = recipientExtraMIT[recipient];

        if (recipientETH[recipient] >= 250000 ether) {          // $2,000,000+
            recipientExtraMIT[recipient] = (recipientMIT[recipient] * 1000) / 925 - recipientMIT[recipient];       // 7.5% discount
        }
        else if (recipientETH[recipient] >= 62500 ether) {      // $500,000+
            recipientExtraMIT[recipient] = (recipientMIT[recipient] * 10000) / 9625 - recipientMIT[recipient];     // 3.75% discount
        }

        uint MITIncrease = MIT + (recipientExtraMIT[recipient] - oldExtra);

        totalETH += msg.value;
        totalMIT += MITIncrease;
        MITPurchase(msg.sender, recipient, msg.value, MITIncrease);
    }

    function recipientTotalMIT(address recipient) external constant returns (uint MIT) {
        MIT = recipientMIT[recipient] + recipientExtraMIT[recipient];
    }

}
