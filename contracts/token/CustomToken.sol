/*withhold this contract*/

pragma solidity ^0.4.23;

import "./BaseToken.sol";
import "../ownership/Ownable.sol";

contract CustomToken is BaseToken{
    constructor() public
        {
            decimals = 18;     // Amount of decimals for display purposes
            name = "decipher";    // Set the name for display purposes
            symbol = "DEC";        // Set the symbol for display purposes
            totalSupply_ = 1000 * 1000 * 1000 * (10 ** uint(decimals));    // Update total supply, 100 billion tokens
            balances[msg.sender] = totalSupply_;
            emit Transfer(0x0, msg.sender, totalSupply_);
    }

    /**
    * @dev returns the public supply of total tokens regardless of locked group tokens.
    */
   /*
    function publicSupply() public view
        returns(uint256) {
           //DO NOT USE: use publicSupply() in Fund.sol

    }
   */
}
