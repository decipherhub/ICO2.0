pragma solidity ^0.4.23;

import "./IBaseVoting.sol";

contract IRefundVoting is IBaseVoting{
    event DiscardRefundVoting(uint256 indexed time);
    
    function canDiscard() public view returns(bool);
    function isDiscarded() public view returns(bool);
    function initializeVote() public returns(bool);
}