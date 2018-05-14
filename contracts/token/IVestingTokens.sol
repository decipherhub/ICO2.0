pragma solidity ^0.4.23;

import "../token/ILockedTokens.sol";

contract IVestingTokens is ILockedTokens {
    enum LOCK_TYPE {DEV, ADV, PRIV}

    function setCrowdsaleAddress(address _crowdsaleAddress) public returns(bool);
    function lockup(address _to, uint256 _amount, LOCK_TYPE _type) external;
}
