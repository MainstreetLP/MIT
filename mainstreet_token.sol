pragma solidity ^0.4.7;

import "./erc20.sol";
import "./mainstreet_crowdfund.sol";

/**
 * @title MainstreetToken
 */
contract MainstreetToken is ERC20 {
    
    mapping (address => uint) public ownerMIT;
    uint public totalMIT;
    
    mapping (address => bool) public isImported;
    
    modifier notImported(address recipient) {
        if (isImported[recipient]) {
            throw;
        }
        _;
    }
    
    MainstreetCrowdfund public mainstreetCrowdfund;
    
    /**
     * @dev A MIT balance has been imported.
     * @param recipient Address imported.
     * @param MIT Amount of MIT imported.
     */
    event RecipientImported(address indexed recipient, uint MIT);

    /**
     * @dev Constructor.
     * @param _mainstreetCrowdfund Address of crowdfund contract.
     */
    function MainstreetToken(MainstreetCrowdfund _mainstreetCrowdfund) {
        mainstreetCrowdfund = _mainstreetCrowdfund;
    }
    
    /**
     * @dev Imports MIT balance from crowdfund contract.
     * @param recipient Address to import.
     * @return MIT Amount of MIT imported.
     */
    function importRecipient(address recipient) external notImported(recipient) returns (uint MIT) {
        MIT = mainstreetCrowdfund.recipientMITWithBonus(recipient);
        ownerMIT[recipient] = MIT;
        totalMIT += MIT;
        isImported[recipient] = true;
        RecipientImported(recipient, MIT);
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
    function transfer(address _to, uint256 _value) returns (bool success) {
        if (ownerMIT[msg.sender] < _value) {
            return false;
        }
        ownerMIT[msg.sender] -= _value;
        ownerMIT[_to] += _value;
        Transfer(msg.sender, _to, _value);
        return true;
    }

    /**
     * Unimplemented ERC20 methods.
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
