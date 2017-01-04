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
        if (totalETH >= limit) {    // ether is just a multiplier
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
    
    /**
     * @dev Constructor.
     * @param _start Timestamp of when the crowdsale will start.
     * @param _end Timestamp of when the crowdsale will end.
     * @param _limit Maximum amount of ETH that can be sent to the contract in total. Specified in wei.
     * @param _exitAddress Address that all ETH should be forwarded to.
     * @param whitelist1 First address that can send ETH.
     * @param whitelist2 Second address that can send ETH.
     */
    function MainstreetCrowdfund(uint _start, uint _end, uint _limit, address _exitAddress, address whitelist1, address whitelist2) {
        start = _start;
        end = _end;
        limit = _limit;
        
        whitelistedAddresses[whitelist1] = true;
        whitelistedAddresses[whitelist2] = true;
        exitAddress = _exitAddress;
    }
    
    /**
     * @dev Forward Ether to the exit address. Store all ETH and MIT information in public state and logs.
     * @param recipient Address that tokens should ultimately be attributed to or 0 to attribute to sender.
     * @return MIT Amount of MIT purchased.
     */
    function purchaseMIT(address recipient) senderIsWhitelisted payable saleActive hasValue returns (uint MIT) {
        
        if (!exitAddress.send(msg.value)) {
            throw;
        }
        
        if (recipient == 0) {
            recipient = msg.sender;
        }
        
        MIT = msg.value * 8;
        uint extra;
        if (msg.value >= 250000 ether) {        // ether is just a multiplier
            extra = (MIT * 75) / 1000;      // 7.5%
        }
        else if (msg.value >= 62500 ether) {    // ether is just a multiplier
            extra = (MIT * 375) / 10000;    // 3.75%
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
