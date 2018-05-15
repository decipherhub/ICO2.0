pragma solidity ^0.4.23;

contract IVotingFactory {

    enum VOTE_TYPE {NONE, REFUND, TAP}
    address public mTapVotingAddress;
    address public mRefundVotingAddress;
    address public mTokenAddress;
    address public mFundAddress;
    address public mVestingTokensAddress;
    
    function isVoteExist(address _votingAddress) view public returns(bool);
    function newTapVoting(string _votingName) public returns(address);
    function newRefundVoting(string _votingName) public returns(address);
    function destroyVoting(address _vote_account, string _memo) public returns(bool);
    function refreshRefundVoting() public returns(bool);

    /* Events */
    event CreateTapVote(address indexed vote_account, VOTE_TYPE indexed type_, uint8 indexed round, string name);
    event CreateRefundVote(address indexed vote_account, VOTE_TYPE indexed type_, uint8 indexed round, string name);
    event DiscardTapVote(address indexed vote_account, VOTE_TYPE indexed type_, uint8 indexed round, string memo);
    event DiscardRefundVote(address indexed vote_account, VOTE_TYPE indexed type_, uint8 indexed round, string memo);
}
