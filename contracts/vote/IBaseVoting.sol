pragma solidity ^0.4.23;

contract IBaseVoting {
    enum VOTE_PERIOD {NONE, INITIALIZED, OPENED, CLOSED, FINALIZED, DISCARDED}
    enum VOTE_STATE {NONE, AGREE, DISAGREE}
    enum RESULT_STATE {NONE, PASSED, REJECTED}
    enum GROUP {PUBLIC, LOCKED}

    event InitializeVote(address indexed vote_account, string indexed voting_name, uint256 startTime, uint256 endTime);
    event OpenVote(address indexed opener, uint256 open_time);
    event CloseVote(address indexed closer, uint256 close_time);
    event FinalizeVote(address indexed finalizer, uint256 finalize_time);
    event DiscardVote(address indexed vote_account, uint256 discard_time);

    function isActivated() public view returns(bool);
    function getName() public view returns(string);
    function getPublicPerc() view public returns(uint256);
    function getParticipatingPerc() view public returns(uint256);
    function getMinVotingPerc() public pure returns(uint256);
    function getTotalPower() view public returns(uint256);
    function getAgreePower() view public returns(uint256);
    function getDisagreePower() view public returns(uint256);
    function getParticipantPower() public view returns(uint256);
    function getAbsentPower() view public returns(uint256);
    function getAgreeCount() public view returns(uint256);
    function getDisagreeCount() public view returns(uint256);
    function getDiscardTime() public view returns(uint256);
    
    function readPartyDict(address account) public view returns(VOTE_STATE, GROUP, uint256, bool);
    function writePartyDict(address account, VOTE_STATE _state, GROUP _group, uint256 _power, bool _bool) public returns(bool);

    function initializeVote(uint256 _term) public returns(bool);
    function openVote() public returns(bool);
    function closeVote() public returns(bool);
    function finalizeVote() public returns(bool);

    function discard() public returns(bool);
    function vote(bool _agree) public returns(bool);
    function getBack() public returns(bool);
}