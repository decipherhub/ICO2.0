pragma solidity ^0.4.23;

import "../token/ERC20.sol";
import "../fund/Fund.sol";
import "../lib/SafeMath.sol";
import "../lib/Param.sol";
import "../token/VestingTokens.sol";
import "../ownership/Ownable.sol";

contract BaseVoting is Ownable, Param {
    /*Library and Typedefs*/
    using SafeMath for uint256;

    enum VOTE_PERIOD {NONE, INITIALIZED, OPENED, CLOSED, FINALIZED, DISCARDED}
    enum VOTE_STATE {NONE, AGREE, DISAGREE}
    enum RESULT_STATE {NONE, PASSED, REJECTED}
    enum GROUP {PUBLIC, LOCKED}

    struct vote_receipt {
        VOTE_STATE state;
        GROUP group;
        uint256 power;
        bool isReceivedIncentive;
    }

    /* Global Variables */
    string public mVotingName;
    VOTE_PERIOD mPeriod;
    ERC20 public mToken;
    Fund public mFund;
    VestingTokens public mVestingTokens;
    address public mFactoryAddress;

    uint public minVotePerc;

    uint256 public startTime;
    uint256 public endTime;
    uint256 public agree_power = 0; // real value is divided by 100(weight)
    uint256 public disagree_power = 0;
    uint256 public agree_count = 0;
    uint256 public disagree_count = 0;

    mapping(address => vote_receipt) public party_dict;
    address[] public party_list;
    address[] public public_party_list; //withhold
    address[] public locked_party_list; //withhold

    bool public isAvailable = true;
    uint256 public discardTime;

    /* Events */
    event InitializeVote(address indexed vote_account, string indexed voting_name, uint256 startTime, uint256 endTime);
    event OpenVote(address indexed opener, uint256 open_time);
    event CloseVote(address indexed closer, uint256 close_time);
    event FinalizeVote(address indexed finalizer, uint256 finalize_time);
    event DiscardVote(address indexed vote_account, uint256 discard_time);

    /* Modifiers */
    modifier period(VOTE_PERIOD p) {
        require(mPeriod == p, "VOTE_PERIOD not match.");
        _;
    }

    modifier onlyVotingFactory() {
        require(msg.sender == mFactoryAddress);
        _;
    }

    modifier available() {
        require(isAvailable, "this refund voting has been discarded.");
        _;
    }

    /* Constructor */
    constructor(
        string _votingName,
        address _tokenAddress,
        address _fundAddress,
        address _vestingTokensAddress,
        address _membersAddress
        ) public
        Ownable(_membersAddress) {
            require(_tokenAddress != address(0));
            require(_fundAddress != address(0));
            require(_vestingTokensAddress != address(0));
            require(_membersAddress != 0x0);

            mVotingName = _votingName;
            mToken = ERC20(_tokenAddress);
            mFund = Fund(_fundAddress);
            mVestingTokens = VestingTokens(_vestingTokensAddress);
            mPeriod = VOTE_PERIOD.NONE;
            mFactoryAddress = msg.sender; // It should be called by only VotingFactory
            isAvailable = true;
    }

    /* View Function */
    function isActivated() public view
        returns(bool) {
            return (mPeriod == VOTE_PERIOD.OPENED);
    }

    function getName() public view
        returns(string) {
            return mVotingName;
    }
    // getPublicPerc = p (the percent of developers' token)
    function getPublicPerc() view public
        returns(uint256) {
            return mFund.publicSupply().mul(1000).div(mToken.totalSupply());
    }

    function getParticipatingPerc() view public
        returns(uint256) {
            uint256 total_token = mToken.totalSupply().mul(PUBLIC_TOKEN_PERC).div(1000);
            return getParticipantPower().mul(1000).div(total_token);
    }

    function getMinVotingPerc() public pure
        returns(uint256) {
            //TODO: it is affected by the previous tap voting's participating rate.
            //IMPORTANT
            uint256 P_S=50;
            uint256 p_M=80;
            uint256 p_m=20;
            uint256 N_M=80;
            uint256 N_m=20;

            return MIN_VOTE_PERCENT(P_S, p_M, p_m, N_M, N_m);
    }

    function getTotalPower() view public
        returns(uint256) {
            // totalSupply(1-p) + totalSupply*p*DEV_POWER, p is dev ratio
            uint256 ret1 = mToken.totalSupply().mul(uint256(1000).sub(getPublicPerc())).div(1000);
            uint256 ret2 = mToken.totalSupply().mul(getPublicPerc()).mul(DEV_POWER).div(1000);
            return ret1.add(ret2);
    }

    function getAgreePower() view public
        returns(uint256) {
            return agree_power;
    }

    function getDisagreePower() view public
        returns(uint256) {
            return disagree_power;
    }

    function getParticipantPower() public view
        returns(uint256) {
            return agree_power.add(disagree_power);
    }

    function getAbsentPower() view public
        returns(uint256) {
            return getTotalPower().sub(getParticipantPower());
    }

    function getAgreeCount() public view
        returns(uint256) {
            return agree_count;
    }

    function getDisagreeCount() public view
        returns(uint256) {
            return disagree_count;
    }

    function getDiscardTime() public view
        returns(uint256) {
            require(discardTime != uint256(0), "this vote is not discarded.");
            return discardTime;
    }

    function readPartyDict(address account) public view
        returns(VOTE_STATE, uint256, bool) {
            return (party_dict[account].state, party_dict[account].power, party_dict[account].isReceivedIncentive);
    }

    function writePartyDict(
        address account,
        VOTE_STATE a,
        uint256 b,
        bool c) public 
        available
        returns(bool) {
            if(a != VOTE_STATE.NONE) {party_dict[account].state = a;}
            if(b != 0) {party_dict[account].power = b;}
            if(c != false) {party_dict[account].isReceivedIncentive = true;}
            return true;
    }

    /* Voting Period Function
     * order: initialize -> open -> close -> finalize
     */
    function initializeVote(uint256 _term) public
        period(VOTE_PERIOD.NONE)
        available
        returns(bool) {
            require(msg.sender != 0x0);

            startTime = now;
            endTime = now + _term; // you should change the alpha into proper value.
            mPeriod = VOTE_PERIOD.INITIALIZED;
            emit InitializeVote(address(this), mVotingName, startTime, endTime);
            return true;
    }

    function openVote() public
        period(VOTE_PERIOD.INITIALIZED)
        available
        returns(bool) {
            mPeriod = VOTE_PERIOD.OPENED;
            emit OpenVote(msg.sender, now);
            return true;
    }

    function closeVote() public
        period(VOTE_PERIOD.OPENED)
        available
        returns(bool) {
            require(now >= endTime);

            mPeriod = VOTE_PERIOD.CLOSED;
            emit CloseVote(msg.sender, now);
            return true;
    }
    //TODO: specify the condition of finality
    //should be overrided
    function finalizeVote() public
        period(VOTE_PERIOD.CLOSED)
        available
        returns(bool) {
            mPeriod = VOTE_PERIOD.FINALIZED;
            emit FinalizeVote(msg.sender, now);
            return true;
    }

    function discard() public
        only(mFactoryAddress)
        period(VOTE_PERIOD.FINALIZED)
        available
        returns(bool) {
            if(!_haltFunctions()) { revert("cannot discard this function."); }
            discardTime = now;
            emit DiscardVote(address(this), discardTime);
            return true;
    }

    function _haltFunctions() internal
        available
        returns(bool) {
            isAvailable = false;
            return true;
    }

    /* Personal Voting function
     * vote, getBack
     */
    function vote(bool _agree) public
        available
        returns(bool) {
            require(isActivated());
            require(msg.sender != 0x0);
            require(party_dict[msg.sender].state == VOTE_STATE.NONE); // can vote only once
            if(_agree) {
                party_dict[msg.sender].state = VOTE_STATE.AGREE;
                agree_count = agree_count.add(1);
            }
            else {
                party_dict[msg.sender].state = VOTE_STATE.DISAGREE;
                disagree_count = disagree_count.add(1);
            }
            return true;
    }

    function getBack() public
        available
        returns(bool) {
            require(isActivated());
            require(msg.sender != 0x0);

            if(party_dict[msg.sender].state == VOTE_STATE.AGREE) {
                party_dict[msg.sender].state = VOTE_STATE.NONE;
                agree_count = agree_count.sub(1);
            }
            else if(party_dict[msg.sender].state == VOTE_STATE.DISAGREE) {
                party_dict[msg.sender].state = VOTE_STATE.NONE;
                disagree_count = disagree_count.sub(1);
            }
            else { return false; }
            return true;
    }

}



