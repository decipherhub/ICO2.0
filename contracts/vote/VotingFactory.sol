/*
 * VotingFactory.sol is used for creating new voting instance.
 */
pragma solidity ^0.4.23;

import "./TapVoting.sol";
import "./RefundVoting.sol";
import "../ownership/Ownable.sol";
import "../lib/Param.sol";

contract VotingFactory is Ownable, Param {

    /* Typedefs */
    enum VOTE_TYPE {NONE, REFUND, TAP}
    struct VoteInfo {
        VOTE_TYPE voteType;
        uint8 round;
        bool isExist;
    }

    /* Global Variables */
    address mTokenAddress;
    address mFundAddress;
    address mVestingTokensAddress;
    mapping(address => VoteInfo) mVoteList; // {vote name => {voteAddress, voteType}}
    TapVoting mTapVoting;
    RefundVoting mRefundVoting;
    address public mTapVotingAddress;
    address public mRefundVotingAddress;
    TapVoting NULL_TapVoting;
    RefundVoting NULL_RefundVoting;
    uint8 mTapRound;
    uint8 mRefundRound;

    bool switch__isTapVotingOpened = false;


    /* Events */
    event CreateTapVote(address indexed vote_account, VOTE_TYPE indexed type_, uint8 indexed round, string name);
    event CreateRefundVote(address indexed vote_account, VOTE_TYPE indexed type_, uint8 indexed round, string name);
    event DiscardTapVote(address indexed vote_account, VOTE_TYPE indexed type_, uint8 indexed round, string memo);
    event DiscardRefundVote(address indexed vote_account, VOTE_TYPE indexed type_, uint8 indexed round, string memo);

    /* Modifiers */
    modifier allset() {
        require(mTokenAddress != 0x0);
        require(mFundAddress != 0x0);
        require(mVestingTokensAddress != 0x0);
        _;
    }

    /* Constructor */
    //call when Crowdsale finished
    constructor(
        address _tokenAddress,
        address _fundAddress,
        address _vestingTokensAddress,
        address _membersAddress
        ) public
        Ownable(_membersAddress) {
            require(_tokenAddress != address(0));
            require(_fundAddress != address(0));
            require(_membersAddress != address(0));
            require(_vestingTokensAddress != address(0));

            mTokenAddress =_tokenAddress;
            mFundAddress = _fundAddress;
            mTapRound = 1;
            mRefundRound = 1;
            mVestingTokensAddress = _vestingTokensAddress;
    }
    // function initialize() public
    //     onlyDevelopers{
    //         NULL_TapVoting = new TapVoting("null", 0x1, 0x1, 0x1, address(members));
    //         NULL_RefundVoting = new RefundVoting("null", 0x1, 0x1, 0x1, address(members));
    // }

    /* Fallback Function */
    function () external payable {}

    function isVoteExist(address _votingAddress) view public
        returns(bool) {
            return mVoteList[_votingAddress].isExist;
    }

    //TODO: chop it
    function newTapVoting(string _votingName) public
        onlyDevelopers
        allset
        returns(address) {
            // require(!switch__isTapVotingOpened);// "other tap voting is already exists."

            // mTapVoting = new TapVoting(_votingName, mTokenAddress, mFundAddress, mVestingTokensAddress, address(members));
            // if(address(mTapVoting) == 0x0) { revert(); }//"Tap voting has not created."
            // switch__isTapVotingOpened = true;
            // emit CreateTapVote(address(mTapVoting), VOTE_TYPE.TAP, mTapRound, _votingName);
            // mTapRound++;
            // mTapVotingAddress = address(mTapVoting);
            // return mTapVotingAddress;
    }

    function newRefundVoting(string _votingName) public
        allset
        returns(address) {

            // if(address(mRefundVoting) == address(0)) { // first time of creating refund vote
            //     mRefundVoting = new RefundVoting(_votingName, mTokenAddress, mFundAddress, mVestingTokensAddress, address(members));
            //     emit CreateRefundVote(address(mRefundVoting), VOTE_TYPE.REFUND, mRefundRound, _votingName);
            //     mRefundRound++;
            //     return address(mRefundVoting);
            // }
            // else { // more than once
            //     require(mRefundVoting.isDiscarded());// "prev refund voting has not discarded yet."

            //     mRefundVoting = new RefundVoting(_votingName, mTokenAddress, mFundAddress, mVestingTokensAddress, address(members));
            //     if(address(mRefundVoting) == 0x0) { revert(); }//"Refund voting has not created."
            //     emit CreateRefundVote(address(mRefundVoting), VOTE_TYPE.REFUND, mRefundRound, _votingName);
            //     mRefundRound++;
            //     return address(mRefundVoting);
            // }
    }

    //TODO: chop the destroyVoting into Tap and Refund voting
    function destroyVoting(
        address _vote_account,
        string _memo) public
        allset
        returns(bool) {
            require(isVoteExist(_vote_account));

            if(mVoteList[_vote_account].voteType == VOTE_TYPE.REFUND) { // Refund Voting Destroying
                if(address(mRefundVoting) != _vote_account) { revert(); }//"input voting address and current address are not equal."
                if(!mRefundVoting.discard()) { revert(); }//"This refund voting cannot be discarded."
                emit DiscardRefundVote(_vote_account, VOTE_TYPE.REFUND, mVoteList[_vote_account].round, _memo); // TODO: _vote_name is not in mVoteList.
                mRefundVoting = NULL_RefundVoting; // FIXIT: how to initialize NULL

            }
            else if(mVoteList[_vote_account].voteType == VOTE_TYPE.TAP && switch__isTapVotingOpened == true) {
                if(address(mTapVoting) != _vote_account) { revert(); }//"input voting address and current address are not equal."
                if(!mTapVoting.discard()) { revert(); }//"This tap voting cannot be discarded."
                emit DiscardTapVote(_vote_account, VOTE_TYPE.TAP, mVoteList[_vote_account].round, _memo);
                mTapVoting = NULL_TapVoting; // FIXIT: how to initialize NULL
                switch__isTapVotingOpened = false;
            }
            else if(mVoteList[_vote_account].voteType == VOTE_TYPE.NONE) {
                revert();//"invalid vote account."
            }
            return true;
    }

    function refreshRefundVoting() public
        allset
        returns(bool) {
            destroyVoting(mRefundVotingAddress, "refresh by refreshRefundVoting");
            mRefundVotingAddress = newRefundVoting("refund voting");
            return true;
    }
}
