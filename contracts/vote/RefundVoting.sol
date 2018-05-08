pragma solidity ^0.4.23;

import "./BaseVoting.sol";

contract RefundVoting is BaseVoting {

    event DiscardRefundVoting(uint256 indexed time);

    constructor(
        string _votingName,
        address _tokenAddress,
        address _fundAddress,
        address _vestingTokens,
        address _membersAddress
        )
        BaseVoting( _votingName,
                    _tokenAddress,
                    _fundAddress,
                    _vestingTokens, 
                    membersAddress) public {
    }
    
    function canDiscard() public view
        returns(bool) {
            return (now >= endTime && now >= startTime.add(REFRESH_TERM));
    }

    function isDiscarded() public view
        returns(bool) {
            return (VOTE_PERIOD.DISCARDED == mPeriod) ;
    }
    
    /* RefundVoting Period Function
     * order: initialize -> open -> close -> finalize -> discard
     */
    function initializeVote() public
        period(VOTE_PERIOD.NONE)
        available
        returns(bool) {
            return super.initializeVote(REFRESH_TERM); //fixed term
    }
    
    function openVote() public
        period(VOTE_PERIOD.INITIALIZED)
        available
        returns(bool) {
            return super.openVote();
    }

    function closeVote() public
        period(VOTE_PERIOD.OPENED)
        available
        returns(bool) {
            return super.closeVote();
    }

    function finalizeVote() public
        period(VOTE_PERIOD.CLOSED) 
        available
        returns (bool) { 
            //TODO: finalize the refund voting. call lockFund() if refund has approved
            RESULT_STATE result = RESULT_STATE.NONE;


            emit FinalizeVote(msg.sender, now);    
    }
    
    function discard() public
        period(VOTE_PERIOD.FINALIZED)
        available
        only(mFactoryAddress)
        returns(bool) {
            require(now >= endTime && now >= startTime.add(REFRESH_TERM), "check that refund voting is in the discardable state.");
            
            if(!_haltFunctions()) {revert("cannot discard the refund voting.");}
            
            discardTime = now;
            mPeriod = VOTE_PERIOD.DISCARDED;
            emit DiscardRefundVoting(discardTime);
            return true;
    }
    
    /* Personal Voting function
     * vote, getBack
     */
    function vote(bool agree) public
        available
        returns (bool) {
            return super.vote(agree);
    }
    
    function getBack() public
        available
        returns (bool) {
            return super.getBack();
    }
    

}
