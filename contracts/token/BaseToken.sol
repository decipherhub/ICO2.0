pragma solidity ^0.4.23;

import "./ERC20.sol";
import "../lib/SafeMath.sol";

// from https://github.com/OpenZeppelin/zeppelin-solidity/blob/master/contracts/token/ERC20/StandardBurnableToken.sol

contract BaseToken is ERC20 {
    
    event Burn(address indexed burner, uint256 value);

    // functions which increase/decrease approval
    function increaseApproval(address _spender, uint _addedValue) public
        returns (bool) {
            allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
            emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
            return true;
    }
    function decreaseApproval(address _spender, uint _subtractedValue) public
        returns (bool) {
            uint oldValue = allowed[msg.sender][_spender];
            if (_subtractedValue > oldValue) {
                allowed[msg.sender][_spender] = 0;
            } else {
                allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
            }
            emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
            return true;
    }
    
    function burn(uint256 _value) public
        {
            _burn(msg.sender, _value);
    }

    /**
    * @dev Burns a specific amount of tokens from the target address and decrements allowance
    * @param _from address The address which you want to send tokens from
    * @param _value uint256 The amount of token to be burned
    */
    function burnFrom(address _from, uint256 _value) public
        {
            require(_value <= allowed[_from][msg.sender]);
            // Should https://github.com/OpenZeppelin/zeppelin-solidity/issues/707 be accepted,
            // this function needs to emit an event with the updated approval.
            allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
            _burn(_from, _value);
    }

    function _burn(address _who, uint256 _value) internal
        {
            require(_value > 0);
            require(balances[_who] >= _value, "Not Enough Value");
            balances[_who] = balances[_who].sub(_value);    // Subtract from the sender
            totalSupply_ = totalSupply_.sub(_value);     // Updates totalSupply
            emit Burn(_who, _value);
            emit Transfer(_who, address(0), _value);
    }
}
