pragma solidity ^0.4.9;

contract ERC20 {
    function totalSupply() constant returns (uint256 totalSupply);
    function balanceOf(address _owner) constant returns (uint256 balance);
    function transfer(address _to, uint256 _value) returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success);
    function approve(address _spender, uint256 _value) returns (bool success);
    function allowance(address _owner, address _spender) constant returns (uint256 remaining);

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

/**
 * @title MainstreetToken
 */
contract MainstreetToken is ERC20 {
    string public name = 'Mainstreet Token';             //The Token's name: e.g. DigixDAO Tokens
    uint8 public decimals = 18;             // 1Token ¨= 1$ (1ETH ¨= 10$)
    string public symbol = 'MIT';           //An identifier: e.g. REP
    string public version = 'MIT_0.1';

    mapping (address => uint) ownerMIT;
    mapping (address => mapping (address => uint)) allowed;
    uint public totalMIT;
    uint public start;

    address public mainstreetCrowdfund;

    address public intellisys;

    bool public testing;

    modifier fromCrowdfund() {
        if (msg.sender != mainstreetCrowdfund) {
            throw;
        }
        _;
    }

    modifier isActive() {
        if (block.timestamp < start) {
            throw;
        }
        _;
    }

    modifier isNotActive() {
        if (!testing && block.timestamp >= start) {
            throw;
        }
        _;
    }

    modifier recipientIsValid(address recipient) {
        if (recipient == 0 || recipient == address(this)) {
            throw;
        }
        _;
    }

    modifier allowanceIsZero(address spender, uint value) {
        // To change the approve amount you first have to reduce the addresses´
        // allowance to zero by calling `approve(_spender,0)` if it is not
        // already 0 to mitigate the race condition described here:
        // https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
        if ((value != 0) && (allowed[msg.sender][spender] != 0)) {
            throw;
        }
        _;
    }

    /**
     * @dev Constructor.
     * @param _mainstreetCrowdfund Address of crowdfund contract.
     * @param _intellisys Address to receive intellisys' tokens.
     * @param _start Timestamp when the token becomes active.
     */
    function MainstreetToken(address _mainstreetCrowdfund, address _intellisys, uint _start, bool _testing) {
        mainstreetCrowdfund = _mainstreetCrowdfund;
        intellisys = _intellisys;
        start = _start;
        testing = _testing;
    }

    /**
     * @dev Add to token balance on address. Must be from crowdfund.
     * @param recipient Address to add tokens to.
     * @return MIT Amount of MIT to add.
     */
    function addTokens(address recipient, uint MIT) external isNotActive fromCrowdfund {
        ownerMIT[recipient] += MIT;
        uint intellisysMIT = MIT / 10;
        ownerMIT[intellisys] += intellisysMIT;
        totalMIT += MIT + intellisysMIT;
        Transfer(0x0, recipient, MIT);
        Transfer(0x0, intellisys, intellisysMIT);
    }

    /**
     * @dev Implements ERC20 totalSupply()
     */
    function totalSupply() constant returns (uint256 totalSupply) {
        totalSupply = totalMIT;
    }

    /**
     * @dev Implements ERC20 balanceOf()
     */
    function balanceOf(address _owner) constant returns (uint256 balance) {
        balance = ownerMIT[_owner];
    }

    /**
     * @dev Implements ERC20 transfer()
     */
    function transfer(address _to, uint256 _value) isActive recipientIsValid(_to) returns (bool success) {
        if (ownerMIT[msg.sender] >= _value) {
            ownerMIT[msg.sender] -= _value;
            ownerMIT[_to] += _value;
            Transfer(msg.sender, _to, _value);
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Implements ERC20 transferFrom()
     */
    function transferFrom(address _from, address _to, uint256 _value) isActive recipientIsValid(_to) returns (bool success) {
        if (allowed[_from][msg.sender] >= _value && ownerMIT[_from] >= _value) {
            ownerMIT[_to] += _value;
            ownerMIT[_from] -= _value;
            allowed[_from][msg.sender] -= _value;
            Transfer(_from, _to, _value);
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Implements ERC20 approve()
     */
    function approve(address _spender, uint256 _value) isActive allowanceIsZero(_spender, _value) returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

    /**
     * @dev Implements ERC20 allowance()
     */
    function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
        remaining = allowed[_owner][_spender];
    }
}
