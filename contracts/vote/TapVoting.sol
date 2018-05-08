pragma solidity ^0.4.23;

import "./BaseVoting.sol";
import "../fund/Fund.sol";

contract TapVoting is BaseVoting {

    /* Constructor */
    constructor(
        string _votingName,
        address _tokenAddress,
        address _fundAddress,
        address _vestingTokens,
        address _membersAddress
        ) BaseVoting(_votingName, _tokenAddress, _fundAddress, _vestingTokens, _membersAddress) public {
    }

    /* Voting Period Function
     * order: initialize -> open -> close -> finalize
     */
    function initializeVote(uint256 term) public
        period(VOTE_PERIOD.NONE)
        available
        returns(bool) {
            require(term > MIN_TERM && MAX_TERM > term);
            super.initializeVote(term);
    }

    function openVote() public
        period(VOTE_PERIOD.INITIALIZED)
        available
        returns(bool) {
            super.openVote();
    }

    function closeVote() public
        period(VOTE_PERIOD.OPENED)
        available
        returns(bool) {
            super.closeVote();
    }
    //TODO: should we move on to BaesVoting?
    function _snapshot() internal
        returns(bool){
            //FIXIT: how to reduce the snapshot operation gas fee?
            //WARNING: it might exceed the block gas limit.

            for(uint256 i = 0; i < party_list.length; i++) {
                uint256 weight = isLockedGroup(party_list[i]) ? DEV_POWER : 1000; // percent
                uint256 vote_power = mToken.balanceOf(party_list[i]).mul(weight).div(1000);
                party_dict[party_list[i]].power = vote_power; //snapshot each account's vote power
                party_dict[party_list[i]].group = isLockedGroup(party_list[i]) ? GROUP.LOCKED : GROUP.PUBLIC;
                if(party_dict[party_list[i]].state == VOTE_STATE.AGREE) {
                    agree_power = agree_power.add(vote_power);
                } else if(party_dict[party_list[i]].state == VOTE_STATE.DISAGREE) {
                    disagree_power = disagree_power.add(vote_power);
                }    // cumulate total power of agree and disagree parties.
            }
            return true;
    }
    //TODO: should we move on to BaseVoting?
    function finalizeVote() public
        period(VOTE_PERIOD.CLOSED)
        available
        returns(bool) {
            // pass the vote if yes - no > 0
            require(mPeriod == VOTE_PERIOD.CLOSED);
            RESULT_STATE result = RESULT_STATE.NONE;

            if(!_snapshot()){revert("failed to snapshot in tap finalize.");}

            if(getParticipatingPerc() < getMinVotingPerc()){revert("It cannot satisfy minimum voting rate.");}
            if(getAgreePower() > getDisagreePower()) {
                result = RESULT_STATE.PASSED;
            }
            else {
                result = RESULT_STATE.REJECTED;
            }
            mPeriod = VOTE_PERIOD.FINALIZED;
            emit FinalizeVote(msg.sender, now);
            if(!mFund.withdrawTap()){revert("failed to withdrawFromFund in tap finalize.");}
            return true;
    }
    /* Personal Voting function
     * vote, getBack
     */
    function vote(bool agree) public
        period(VOTE_PERIOD.OPENED)
        available
        returns(bool) {
            return super.vote(agree);
    }

    function getBack() public
        period(VOTE_PERIOD.OPENED)
        available
        returns (bool) {
            return super.getBack();
    }

    //TODO: we should add(override) some meaningful function

}
