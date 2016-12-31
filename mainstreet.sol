pragma solidity ^0.4.7;

import "./erc20.sol";

/**
 * @title Mainstreet
 * @author Jonathan Brown <jbrown@bluedroplet.com>
 */
contract Mainstreet is ERC20 {
    
    mapping (address => uint) public tokens;
    uint totalTokens;
    
    uint public start;
    uint public end;
    
    mapping (address => bool) public whitelistedAddresses;
    address[] public keyholders;
    
    struct SendOperation {
        address to;
        uint value;
    }
    
    mapping (bytes32 => address[]) public operationApprovals;
    mapping (bytes32 => SendOperation) public sendOperations;
    mapping (bytes32 => address) public addKeyholderOperations;
    mapping (bytes32 => address) public removeKeyholderOperations;
    mapping (bytes32 => address) public addWhitelistedAddressOperations;
    mapping (bytes32 => address) public removeWhitelistedAddressOperations;

    event MITPurchase(address indexed recipient, uint ETH, uint MIT);
    event OperationAuthorization(bytes32 indexed operationId, address indexed keyholder);
    event SendOperationCreated(bytes32 indexed operationId, address indexed to, uint value);
    event SendOperationCancelled(bytes32 indexed operationId, address indexed to, uint value);
    event SendOperationExecuted(bytes32 indexed operationId, address indexed to, uint value);
    event AddKeyholderOperationCreated(bytes32 indexed operationId, address indexed newKeyholder);
    event AddKeyholderOperationCancelled(bytes32 indexed operationId, address indexed newKeyholder);
    event AddKeyholderOperationExecuted(bytes32 indexed operationId, address indexed newKeyholder);
    event RemoveKeyholderOperationCreated(bytes32 indexed operationId, address indexed keyholder);
    event RemoveKeyholderOperationCancelled(bytes32 indexed operationId, address indexed keyholder);
    event RemoveKeyholderOperationExecuted(bytes32 indexed operationId, address indexed keyholder);
    event AddWhitelistedAddressOperationCreated(bytes32 indexed operationId, address indexed newWhitelistedAddress);
    event AddWhitelistedAddressOperationCancelled(bytes32 indexed operationId, address indexed newWhitelistedAddress);
    event AddWhitelistedAddressOperationExecuted(bytes32 indexed operationId, address indexed newWhitelistedAddress);
    event RemoveWhitelistedAddressOperationCreated(bytes32 indexed operationId, address indexed whitelistedAddress);
    event RemoveWhitelistedAddressOperationCancelled(bytes32 indexed operationId, address indexed whitelistedAddress);
    event RemoveWhitelistedAddressOperationExecuted(bytes32 indexed operationId, address indexed whitelistedAddress);
    
    modifier saleActive() {
        if (block.timestamp < start || block.timestamp >= end) {
            throw;
        }
        _;
    }

    modifier capIsNotReached() {
        if (totalTokens >= 50000000 ether) {    // ether is just a multiplier
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
    
    modifier isKeyholder() {
        for (uint i = 0; i < keyholders.length; i++) {
            if (keyholders[i] == msg.sender) {
                _;
            }
        }
        throw;
    }
    
    modifier hasNotApproved(bytes32 operationId) {
        for (uint i = 0; i < operationApprovals[operationId].length; i++) {
            if (operationApprovals[operationId][i] == msg.sender) {
                throw;
            }
        }
        _;
    }
    
    modifier isSendOperation(bytes32 operationId) {
        if (sendOperations[operationId].to == 0) {
            throw;
        }
        _;
    }
    
    modifier isAddKeyholderOperation(bytes32 operationId) {
        if (addKeyholderOperations[operationId] == 0) {
            throw;
        }
        _;
    }
    
    modifier isRemoveKeyholderOperation(bytes32 operationId) {
        if (removeKeyholderOperations[operationId] == 0) {
            throw;
        }
        _;
    }
    
    modifier isAddWhitelistedAddressOperation(bytes32 operationId) {
        if (addWhitelistedAddressOperations[operationId] == 0) {
            throw;
        }
        _;
    }
    
    modifier isRemoveWhitelistedAddressOperation(bytes32 operationId) {
        if (removeWhitelistedAddressOperations[operationId] == 0) {
            throw;
        }
        _;
    }
    
    modifier operationApproved(bytes32 operationId) {
        if (operationApprovals[operationId].length < 3) {
            throw;
        }
        _;
    }
    
    modifier enoughKeyHoldersToRemoveOne() {
        if (keyholders.length <= 3) {
            throw;
        }
        _;
    }
    
    function Mainstreet(uint _start, uint _end) {
        if (_start == 0 || _end == 0) {
            throw;
        }
        start = _start;
        end = _end;
    }
    
    function buyMIT() external payable saleActive capIsNotReached senderIsWhitelisted {
        uint tokensPurchased = msg.value * 8;
        uint extra;
        if (msg.value >= 250000 ether) {        // ether is just a multiplier
            extra = (tokensPurchased / 1000) * 75;      // 7.5%
        }
        else if (msg.value >= 62500 ether) {    // ether is just a multiplier
            extra = (tokensPurchased / 10000) * 375;    // 3.75%
        }
        
        if (block.timestamp - start < 1 weeks) {
            extra += tokensPurchased / 10;              // 10%
        }
        else if (block.timestamp - start < 5 weeks) {
            extra += tokensPurchased / 20;              // 5%
        }
        tokensPurchased += extra;
        tokens[msg.sender] += tokensPurchased;
        totalTokens += tokensPurchased;
        MITPurchase(msg.sender, msg.value, tokensPurchased);
    }
    
    function totalSupply() constant returns (uint256 totalSupply) {
        totalSupply = totalTokens;
    }

    function balanceOf(address _owner) constant returns (uint256 balance) {
        balance = tokens[_owner];
    }

    function transfer(address _to, uint256 _value) returns (bool success) {
        if (tokens[msg.sender] < _value) {
            return false;
        }
        tokens[msg.sender] -= _value;
        tokens[_to] += _value;
        Transfer(msg.sender, _to, _value);
        return true;
    }
    
    function getOperationId() internal returns (bytes32 operationId) {
        operationId = keccak256(block.number, msg.data);
    }
    
    function authorizeOperation(bytes32 operationId) external isKeyholder hasNotApproved(operationId) {
        operationApprovals[operationId].push(msg.sender);
        OperationAuthorization(operationId, msg.sender);
    }
    
    function createSendOperation(address to, uint value) external isKeyholder returns (bytes32 operationId) {
        operationId = getOperationId();
        
        sendOperations[operationId] = SendOperation({
            to: to,
            value: value,
        });
        SendOperationCreated(operationId, to, value);
    }
    
    function cancelSendOperation(bytes32 operationId) external isKeyholder {
        SendOperation sendOperation = sendOperations[operationId];
        SendOperationCancelled(operationId, sendOperation.to, sendOperation.value);
        delete operationApprovals[operationId];
        delete sendOperations[operationId];
    }
    
    function executeSendOperation(bytes32 operationId) external isKeyholder isSendOperation(operationId) operationApproved(operationId) {
        SendOperation sendOperation = sendOperations[operationId];
        if (!sendOperation.to.send(sendOperation.value)) {
            throw;
        }
        SendOperationExecuted(operationId, sendOperation.to, sendOperation.value);
        delete operationApprovals[operationId];
        delete sendOperations[operationId];
    }

    function createAddKeyHolderOperation(address newKeyholder) external isKeyholder returns (bytes32 operationId) {
        operationId = getOperationId();
        addKeyholderOperations[operationId] = newKeyholder;
        AddKeyholderOperationCreated(operationId, newKeyholder);
    }

    function cancelAddKeyholderOperation(bytes32 operationId) external isKeyholder {
        AddKeyholderOperationCancelled(operationId, addKeyholderOperations[operationId]);
        delete operationApprovals[operationId];
        delete addKeyholderOperations[operationId];
    }
    
    function executeAddKeyHolderOperation(bytes32 operationId) external isKeyholder isAddKeyholderOperation(operationId) operationApproved(operationId) {
        keyholders.push(addKeyholderOperations[operationId]);
        AddKeyholderOperationExecuted(operationId, addKeyholderOperations[operationId]);
        delete operationApprovals[operationId];
        delete addKeyholderOperations[operationId];
    }

    function createRemoveKeyHolderOperation(address newKeyholder) external isKeyholder returns (bytes32 operationId) {
        operationId = getOperationId();
        removeKeyholderOperations[operationId] = newKeyholder;
        RemoveKeyholderOperationCreated(operationId, newKeyholder);
    }

    function cancelRemoveKeyholderOperation(bytes32 operationId) external isKeyholder {
        RemoveKeyholderOperationCancelled(operationId, removeKeyholderOperations[operationId]);
        delete operationApprovals[operationId];
        delete removeKeyholderOperations[operationId];
    }
    
    function executeRemoveKeyHolderOperation(bytes32 operationId) external isKeyholder isRemoveKeyholderOperation(operationId) operationApproved(operationId) enoughKeyHoldersToRemoveOne {
        for (uint i = 0; i < keyholders.length; i++) {
            if (keyholders[i] == removeKeyholderOperations[operationId]) {
                keyholders[i] = keyholders[keyholders.length - 1];
                delete keyholders[keyholders.length - 1];   // does this line save gas?
                keyholders.length--;
            }
        }
        RemoveKeyholderOperationExecuted(operationId, removeKeyholderOperations[operationId]);
        delete operationApprovals[operationId];
        delete removeKeyholderOperations[operationId];
    }

    function createAddWhitelistedAddressOperation(address addressToWhitelist) external isKeyholder returns (bytes32 operationId) {
        operationId = getOperationId();
        addWhitelistedAddressOperations[operationId] = addressToWhitelist;
        AddWhitelistedAddressOperationCreated(operationId, addressToWhitelist);
    }

    function cancelAddWhitelistedAddressOperation(bytes32 operationId) external isKeyholder {
        AddWhitelistedAddressOperationCancelled(operationId, addWhitelistedAddressOperations[operationId]);
        delete operationApprovals[operationId];
        delete addWhitelistedAddressOperations[operationId];
    }
    
    function executeAddWhitelistedAddressOperation(bytes32 operationId) external isKeyholder isAddWhitelistedAddressOperation(operationId) operationApproved(operationId) {
        whitelistedAddresses[addWhitelistedAddressOperations[operationId]] = true;
        AddWhitelistedAddressOperationExecuted(operationId, addWhitelistedAddressOperations[operationId]);
        delete operationApprovals[operationId];
        delete addWhitelistedAddressOperations[operationId];
    }

    function createRemoveWhitelistedAddressOperation(address addressToUnwhitelist) external isKeyholder returns (bytes32 operationId) {
        operationId = getOperationId();
        removeWhitelistedAddressOperations[operationId] = addressToUnwhitelist;
        RemoveWhitelistedAddressOperationCreated(operationId, addressToUnwhitelist);
    }

    function cancelRemoveWhitelistedAddressOperation(bytes32 operationId) external isKeyholder {
        RemoveWhitelistedAddressOperationCancelled(operationId, removeWhitelistedAddressOperations[operationId]);
        delete operationApprovals[operationId];
        delete removeWhitelistedAddressOperations[operationId];
    }
    
    function executeRemoveWhitelistedAddressOperation(bytes32 operationId) external isKeyholder isRemoveWhitelistedAddressOperation(operationId) operationApproved(operationId) {
        whitelistedAddresses[removeWhitelistedAddressOperations[operationId]] = false;
        RemoveWhitelistedAddressOperationExecuted(operationId, removeWhitelistedAddressOperations[operationId]);
        delete operationApprovals[operationId];
        delete removeWhitelistedAddressOperations[operationId];
    }

    function getKeyholderCount() constant external returns (uint keyholderCount) {
        keyholderCount = keyholders.length;
    }

    function getKeyholders() constant external returns (address[] _keyholders) {
        _keyholders = keyholders;
    }

    /**
     * Unimplemented methods
     */

    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {
        throw;
    }

    function approve(address _spender, uint256 _value) returns (bool success) {
        throw;
    }

    function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
        throw;
    }

}
