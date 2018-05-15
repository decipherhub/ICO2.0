pragma solidity ^0.4.23;

import "../ownership/IMembers.sol";
import "../token/IVestingTokens.sol";

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
    

    function getLockedAmount(IVestingTokens.LOCK_TYPE _type) view public returns(uint256);
    function getPersonalLockedAmount(address _address, IVestingTokens.LOCK_TYPE _type) view public returns(uint256);
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
}
