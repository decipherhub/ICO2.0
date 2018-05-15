pragma solidity ^0.4.23;

contract ILockedTokens {

    function setCrowdsaleAddress(address _crowdsaleAddress) public returns(bool);
    function releaseTokens() external returns(bool);
    function lock() returns(bool);
    event TokensLocked(address indexed _to, uint256 _value, uint256 _lockEndTime);
    event TokensUnlocked(address indexed _to, uint256 _value);
}
