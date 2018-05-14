pragma solidity ^0.4.23;

import "../token/VestingTokens.sol";
import "../ownership/Members.sol";

contract ICrowdsale{
    enum STATE {PREPARE, ACTIVE, FINISHED, FINALIZED, REFUND}
    /* Funcitons */
    /* View Functions */
    function getStartTime() view external returns(uint256);
    function getEndTime() view external returns(uint256);
    
    function getFundingGoal() view external returns(uint256);
    function getCurrentSate() view external returns(STATE);
    function getRate() public view returns (uint);
    function getNextCap() public view returns(uint);
    

    function getLockedAmount(VestingTokens.LOCK_TYPE _type) view public returns(uint256);
    function getPersonalLockedAmount(address _address, VestingTokens.LOCK_TYPE _type) view public returns(uint256);
    function _getTokenAmount(uint256 weiAmount) internal view returns (uint256);

    function _isOver(uint _weiAmount) private view returns(bool);
    function isLockFilled() public view returns(bool);

    /* Change CrowdSale State, call only once */
    function activateSale() external;
    function finishSale() external;
    function finalizeSale() external;
    function activeRefund() external;

    /* Token Purchase Functions */
    function () external payable;
    function buyTokens(address _beneficiary) public payable;
    function _addToUserContributed(address _address, uint _amount, uint _additionalAmount) private;
    function receiveTokens() external;
    function refund() external;
    
    /* Set Functions */
    function setVestingTokens(address _vestingTokensAddress) external;
    function addWhitelist(address _whitelist, uint _maxcap) external;

    function setToDevelopers(address _address, uint _amount) external;
    function setToAdvisors(address _address, uint _amount) external;
    function setToPrivateSale(address _address, uint _amount) external;
    function _isEnrollmentDuplicated(address _address, Members.MEMBER_LEVEL _level) private returns(bool);

    /* Finalizing Functions */
    function _finish() private;
    function _finalize() private;
    function _lockup() private;
    function _forwardFunds() private returns (bool);
}