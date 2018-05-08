/*
 * VotingFactory.sol is used for creating new voting instance.
 */
pragma solidity ^0.4.23;

import "../token/IERC20.sol";
import "../fund/Fund.sol";
import "./BaseVoting.sol";
import "./TapVoting.sol";
import "./RefundVoting.sol";
import "../ownership/Ownable.sol";
import "../ownership/Members.sol";
import "../token/VestingTokens.sol";
import "../lib/SafeMath.sol";
import "../lib/Param.sol";

contract VotingFactory is Ownable, Param {

    /* Typedefs */
    enum VOTE_TYPE {NONE, REFUND, TAP}
    struct voteInfo {
        VOTE_TYPE voteType;
        uint256 round;
        bool isExist;
    }

    /* Global Variables */
    IERC20 public mToken;
    Fund public mFund;
    mapping(address => voteInfo) mVoteList; // {vote name => {voteAddress, voteType}}
    TapVoting public mTapVoting;
    RefundVoting public mRefundVoting;
    TapVoting public NULL_TapVoting;
    RefundVoting public NULL_RefundVoting;
    uint256 public mTapRound;
    uint256 public mRefundRound;
    VestingTokens public mVestingTokens;

    bool public switch__isTapVotingOpened = false;


    /* Events */
    event CreateTapVote(address indexed vote_account, VOTE_TYPE indexed type_, uint256 indexed round, string name);
    event CreateRefundVote(address indexed vote_account, VOTE_TYPE indexed type_, uint256 indexed round, string name);
    event DiscardTapVote(address indexed vote_account, VOTE_TYPE indexed type_, uint256 indexed round, string memo);
    event DiscardRefundVote(address indexed vote_account, VOTE_TYPE indexed type_, uint256 indexed round, string memo);

    /* Modifiers */
    modifier allset() {
        require(address(mToken) != 0x0);
        require(address(mFund) != 0x0);
        require(address(mVestingTokens) != 0x0);
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

            mToken = IERC20(_tokenAddress);
            mFund = Fund(_fundAddress);
            mTapRound = 1;
            mRefundRound = 1;
            mVestingTokens = VestingTokens(_vestingTokensAddress);
            mFund.setVotingFactoryAddress(address(this));
            NULL_TapVoting = new TapVoting("null", 0x1, 0x1, 0x1, _membersAddress);
            NULL_RefundVoting = new RefundVoting("null", 0x1, 0x1, 0x1, _membersAddress);
    }
    /* Fallback Function */
    function () external {}

    function isVoteExist(address _votingAddress) view public
        returns(bool) {
            return mVoteList[_votingAddress].isExist;
    }

    //TODO: chop it
    function newTapVoting(string _votingName) public
        onlyDevelopers
        allset
        returns(address) {
            require(!switch__isTapVotingOpened, "other tap voting is already exists.");

            mTapVoting = new TapVoting(_votingName, address(mToken), address(mFund), address(mVestingTokens), address(members));
            if(address(mTapVoting) == 0x0) { revert("Tap voting has not created."); }
            switch__isTapVotingOpened = true;
            emit CreateTapVote(address(mTapVoting), VOTE_TYPE.TAP, mTapRound, _votingName);
            mTapRound++;
            return address(mTapVoting);
    }

    function newRefundVoting(string _votingName) public
        allset
        returns(address) {

            if(address(mRefundVoting) == address(0)) { // first time of creating refund vote
                mRefundVoting = new RefundVoting(_votingName, address(mToken), address(mFund), address(mVestingTokens), address(members));
                emit CreateRefundVote(address(mRefundVoting), VOTE_TYPE.REFUND, mRefundRound, _votingName);
                mRefundRound++;
                return address(mRefundVoting);
            }
            else { // more than once
                require(mRefundVoting.isDiscarded(), "prev refund voting has not discarded yet.");

                mRefundVoting = new RefundVoting(_votingName, address(mToken), address(mFund), address(mVestingTokens), address(members));
                if(address(mRefundVoting) == 0x0) { revert("Refund voting has not created."); }
                emit CreateRefundVote(address(mRefundVoting), VOTE_TYPE.REFUND, mRefundRound, _votingName);
                mRefundRound++;
                return address(mRefundVoting);
            }
    }

    //TODO: chop the destroyVoting into Tap and Refund voting
    function destroyVoting(
        address _vote_account,
        string _memo) public
        allset
        returns(bool) {
            require(isVoteExist(_vote_account));

            if(mVoteList[_vote_account].voteType == VOTE_TYPE.REFUND) { // Refund Voting Destroying
                if(address(mRefundVoting) != _vote_account) { revert("input voting address and current address are not equal."); }
                if(!mRefundVoting.discard()) { revert("This refund voting cannot be discarded."); }
                emit DiscardRefundVote(_vote_account, VOTE_TYPE.REFUND, mVoteList[_vote_account].round, _memo); // TODO: _vote_name is not in mVoteList.
                mRefundVoting = NULL_RefundVoting; // FIXIT: how to initialize NULL

            }
            else if(mVoteList[_vote_account].voteType == VOTE_TYPE.TAP && switch__isTapVotingOpened == true) {
                if(address(mTapVoting) != _vote_account) { revert("input voting address and current address are not equal."); }
                if(!mTapVoting.discard()) { revert("This tap voting cannot be discarded."); }
                emit DiscardTapVote(_vote_account, VOTE_TYPE.TAP, mVoteList[_vote_account].round, _memo);
                mTapVoting = NULL_TapVoting; // FIXIT: how to initialize NULL
                switch__isTapVotingOpened = false;
            }
            else if(mVoteList[_vote_account].voteType == VOTE_TYPE.NONE) {
                revert("invalid vote account.");
            }
            return true;
    }

    function refreshRefundVoting() public
        allset
        returns(bool) {
            destroyVoting(address(mRefundVoting), "refresh by refreshRefundVoting");
            newRefundVoting("refund voting");
            return true;
    }
}
