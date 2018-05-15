pragma solidity ^0.4.23;

import "../lib/SafeMath.sol";
import "../lib/Param.sol";
import "./IERC20.sol";

contract ERC20 is IERC20, Param {
    /* Library */
    /* Global Variables */
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 totalSupply_;
    mapping(address => uint256) balances;
    mapping (address => mapping (address => uint256)) internal allowed;

	address public owner;

    //we can view public variables without view function
    /* Functions */
    function totalSupply() public view returns (uint256) {
        return totalSupply_;
    }
    /**
    * @dev Gets the balance of the specified address.
    * @param _owner The address to query the the balance of.
    * @return An uint256 representing the amount owned by the passed address.
    */
    function balanceOf(address _owner) public view returns (uint256) {
        return balances[_owner];
    }
    function allowance(address _owner, address _spender) public view returns (uint256) {
        return allowed[_owner][_spender];
    }

    /**
    * @dev transfer token for a specified address
    * @param _to The address to transfer to.
    * @param _value The amount to be transferred.
    */
    function transfer(address _to, uint256 _value) public returns (bool) {
        require(_to != address(0));
        require(_value <= balances[msg.sender]);

        // SafeMath.sub will throw if there is not enough balance.
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    // Allow another contract to spend some tokens in your behalf
    function approve(address _spender, uint256 _value) public returns (bool) {
        require(_value > 0);
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }
    // A contract attempts to get the coins
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        require(_to != address(0));     // Prevent transfer to 0x0 address. Use burn() instead
        require(_value > 0);
        require(balances[_from] >= _value, "Not Enough Value");
        require(balances[_to] + _value > balances[_to], "OverFlow!");
        require(_value <= allowed[_from][msg.sender], "over allowance");
        balances[_from] = balances[_from].sub(_value);    // Subtract from the sender
        balances[_to] = balances[_to].add(_value);    // Add the same to the recipient
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        emit Transfer(_from, _to, _value);
        return true;
    }
}
