pragma solidity ^0.4.7;

import "./mainstreet_token.sol";


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
    uint public limitETH;

    mapping (address => bool) public whitelistedAddresses;
    
    address public exitAddress;
    address public creator;

    MainstreetToken public mainstreetToken;

    event MITPurchase(address indexed sender, address indexed recipient, uint ETH, uint MIT);

    modifier saleActive() {
        if (address(mainstreetToken) == 0) {
            throw;
        }
        if (block.timestamp < start || block.timestamp >= end) {
            throw;
        }
        if (totalETH + msg.value > limitETH) {
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

    modifier isCreator() {
        if (msg.sender != creator) {
            throw;
        }
        _;
    }

    modifier tokenContractNotSet() {
        if (address(mainstreetToken) != 0) {
            throw;
        }
        _;
    }

    /**
     * @dev Constructor.
     * @param _start Timestamp of when the crowdsale will start.
     * @param _end Timestamp of when the crowdsale will end.
     * @param _limitETH Maximum amount of ETH that can be sent to the contract in total. Specified in wei.
     * @param _exitAddress Address that all ETH should be forwarded to.
     * @param whitelist1 First address that can send ETH.
     * @param whitelist2 Second address that can send ETH.
     * @param whitelist3 Third address that can send ETH.
     */
    function MainstreetCrowdfund(uint _start, uint _end, uint _limitETH, address _exitAddress, address whitelist1, address whitelist2, address whitelist3) {
        creator = msg.sender;
        start = _start;
        end = _end;
        limitETH = _limitETH;
        
        whitelistedAddresses[whitelist1] = true;
        whitelistedAddresses[whitelist2] = true;
        whitelistedAddresses[whitelist3] = true;
        exitAddress = _exitAddress;
    }
    
    /**
     * @dev Set the address of the token contract. Must be called by creator of this. Can only be set once.
     * @param _mainstreetToken Address of the token contract.
     */
    function setTokenContract(MainstreetToken _mainstreetToken) external isCreator tokenContractNotSet {
        mainstreetToken = _mainstreetToken;
    }

    /**
     * @dev Forward Ether to the exit address. Store all ETH and MIT information in public state and logs.
     * @param recipient Address that tokens should be attributed to.
     * @return MIT Amount of MIT purchased. This does not include the per-recipient quantity bonus.
     */
    function purchaseMIT(address recipient) external senderIsWhitelisted payable saleActive hasValue recipientIsNotThis(recipient) returns (uint increaseMIT) {
        
        // Attempt to send the ETH to the exit address.
        if (!exitAddress.send(msg.value)) {
            throw;
        }
        
        // Update ETH amounts.
        senderETH[msg.sender] += msg.value;
        recipientETH[recipient] += msg.value;
        totalETH += msg.value;

        // Calculate MIT purchased directly in this transaction.
        uint MIT = msg.value * 10;   // $1 / MIT based on $10 / ETH value

        // Calculate time-based bonus.
        if (block.timestamp - start < 1 weeks) {
            MIT += MIT / 10;    // 10% bonus
        }
        else if (block.timestamp - start < 5 weeks) {
            MIT += MIT / 20;    // 5% bonus
        }

        // Record directly-purchased MIT.
        senderMIT[msg.sender] += MIT;
        recipientMIT[recipient] += MIT;

        // Store previous value-based bonus for this address.
        uint oldExtra = recipientExtraMIT[recipient];

        // Calculate new value-based bonus.
        if (recipientETH[recipient] >= 200000 ether) {          // $2,000,000+
            recipientExtraMIT[recipient] = (recipientMIT[recipient] * 8) / 100;      // 8% bonus
        }
        else if (recipientETH[recipient] >= 50000 ether) {      // $500,000+
            recipientExtraMIT[recipient] = (recipientMIT[recipient] * 4) / 100;      // 4% bonus
        }

        // Calculate MIT increase for this address from this transaction.
        increaseMIT = MIT + (recipientExtraMIT[recipient] - oldExtra);

        // Tell the token contract about the increase.
        mainstreetToken.addTokens(recipient, increaseMIT);

        // Log this purchase.
        MITPurchase(msg.sender, recipient, msg.value, increaseMIT);
    }

}
