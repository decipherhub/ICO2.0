pragma solidity ^0.4.23;

import "../token/IERC20.sol";

contract IBaseToken is IERC20 {
    function increaseApproval(address _spender, uint _addedValue) public returns(bool);
    function decreaseApproval(address _spender, uint _subtractedValue) public returns(bool);
    function burn(uint256 _value) public;
    function burnFrom(address _from, uint256 _value) public;

    event Burn(address indexed burner, uint256 value);
}
