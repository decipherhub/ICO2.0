pragma solidity ^0.4.23;

import "../token/VestingTokens.sol";
import "../ownership/Members.sol";

contract ICrowdsale{
    /* Funcitons */
    /* View Functions */
    function getStartTime() view public returns(uint256);
    function getEndTime() view public returns(uint256);
    
    function getFundingGoal() view public returns(uint256);
    function getCurrentSate() view external returns(string);
    function getRate() public view returns (uint);
    function getNextCap() public view returns(uint);
    
    function getCurrentAmount() view public returns(uint256);
    function getLockedAmount(VestingTokens.LOCK_TYPE _type) view public returns(uint256);
    function getTokenAmount(uint256 weiAmount) internal view returns (uint256);

    function isOver(uint _weiAmount) public view returns(bool);
    function isLockFilled() public view returns(bool);

    /* Change CrowdSale State, call only once */
    function activateSale() public;
    function finishSale() public;
    function finalizeSale() public;
    function activeRefund() public;

    /* Token Purchase Functions */
    function () external payable;
    function buyTokens(address _beneficiary) public payable;
    function _addToUserContributed(address _address, uint _amount, uint _additionalAmount) private;
    function receiveTokens() public;
    function refund() public;
    
    /* Set Functions */
    function setVestingTokens(address _vestingTokensAddress) public;
    function addWhitelist(address _whitelist, uint _maxcap) public;

    function setToDevelopers(address _address, uint _amount) public;
    function setToAdvisors(address _address, uint _amount) public;
    function setToPrivateSale(address _address, uint _amount) public;
    function _isEnrollmentDuplicated(address _address, Members.MEMBER_LEVEL _level) private returns(bool);

    /* Finalizing Functions */
    function _finish() private;
    function _finalize() private;
    function _lockup() private;
    function _forwardFunds() private returns (bool);
    function _dividePool() internal;
}