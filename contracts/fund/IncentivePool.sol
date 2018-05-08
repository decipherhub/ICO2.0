pragma solidity ^0.4.23;

import "../fund/Fund.sol";
import "../token/ERC20.sol";
import "../ownership/Ownable.sol";
import "../vote/TapVoting.sol";
import "../crowdsale/Crowdsale.sol";
import "../lib/SafeMath.sol";
import "../lib/Param.sol";

contract IncentivePool is Ownable, Param {
    using SafeMath for uint256;

    ERC20 public token;
    Fund private fund;
    TapVoting public tapvoting;
    mapping(uint256 => TapVoting) public prevTapVotingList;
    mapping(uint256 => uint256) public withdrawnByDev;
    uint256 currentTapVotingNumber;
    mapping(uint256 => bool) switch__withdraw;

    constructor(address _token, address _fund, address _membersAddress) public
        only(_fund)
        Ownable(_membersAddress) {
            require(_membersAddress != 0x0);
            token = ERC20(_token);
            fund = Fund(_fund);
            currentTapVotingNumber = 0;
    }

    event ReceiveIncentive(uint256 indexed vote_number, address indexed receiver, uint256 incentive_amount);
    //TODO: must cover the previous tap voting incentive
    function getBalance() public view
        returns(uint256) {
            return address(this).balance;
    }

    function getFund() public view
        returns(Fund) {
            return fund;
    }

    function getToken() public view
        returns(address) {
            return address(token);
    }

    function getCurrentTapVoting() public view
        returns(address) {
            return address(tapvoting);
    }

    function getPrevTapVoting(uint256 _votingNumber) public view
        returns(address) {
            return address(prevTapVotingList[_votingNumber]);
    }

    function getIncentiveAmountPerOne(address account) public view
        returns(uint256) {
            //TODO: put the formula in this func
            require(account != 0x0);
            require(address(tapvoting) != 0x0);

            uint256 my_stake;
            (,my_stake,) = tapvoting.readPartyDict(account); //power
            uint256 total_stake = tapvoting.getTotalPower();
            uint256 total_incentive = withdrawnByDev[currentTapVotingNumber].div(100); // FIXIT: 1%, but the withdrawn currency by dev is ETH and incentivised currency is Token
            uint256 ret = total_incentive.mul(withdrawnByDev[currentTapVotingNumber]).mul(my_stake).div(HARD_CAP).div(total_stake);
            return ret;
    }
    function getPrevIncentiveAmountPerOne(uint256 _votingNumber, address account) public view
        returns(uint256) {
            //TODO: put the formula in this func
            require(account != 0x0);

            if(_votingNumber == 0) { return getIncentiveAmountPerOne(account); }

            uint256 my_stake;
            (,my_stake,) = prevTapVotingList[_votingNumber].readPartyDict(account);
            uint256 total_stake = prevTapVotingList[_votingNumber].getTotalPower();
            uint256 total_incentive = withdrawnByDev[_votingNumber].div(100); // FIXIT: 1%, but the withdrawn currency by dev is ETH and incentivised currency is Token
            uint256 ret = total_incentive.mul(withdrawnByDev[_votingNumber]).mul(my_stake).div(HARD_CAP).div(total_stake);
            return ret;
    }

    function hasReceived(address account) public view
        returns(bool ret) {
            (,,ret) = tapvoting.readPartyDict(account);
            return ret;
    }
    function hasPrevReceived(uint256 _votingNumber, address account) public view
        returns(bool ret) {
            (,,ret) = prevTapVotingList[_votingNumber].readPartyDict(account);
            return ret;
    }

    //should make function on Fund.sol which calls this function
    function setTapVotingAddr(address _tapvoting) public
        only(fund)
        returns(bool) {
            require(_tapvoting != 0x0);

            currentTapVotingNumber++;
            prevTapVotingList[currentTapVotingNumber] = TapVoting(_tapvoting);
            tapvoting = prevTapVotingList[currentTapVotingNumber];
            return true;
    }

    function withdraw(uint256 withdraw_by_dev) public
        only(fund)
        returns (bool) {
            switch__withdraw[currentTapVotingNumber] = true;
            withdrawnByDev[currentTapVotingNumber] = withdraw_by_dev;
            return true;
    }
    /*
    the incentivised holder should call this function directly.
    */
    function receiveIncentiveItself() public
        returns(bool) {
            require(switch__withdraw[currentTapVotingNumber], "not opening incentive withdraw");
            require(!hasReceived(msg.sender), "already received incentive");
            require(token.balanceOf(msg.sender) >= MIN_RECEIVABLE_TOKEN, "short of token holdings on snapshot"); //should be changed from token balance to snapshot holdings.

            token.transfer(msg.sender, getIncentiveAmountPerOne(msg.sender)); // ??
            if(!tapvoting.writePartyDict(msg.sender,BaseVoting.VOTE_STATE.NONE,0,true)) { revert(); }
            emit ReceiveIncentive(currentTapVotingNumber, msg.sender, getIncentiveAmountPerOne(msg.sender));
    }

    function receivePrevIncentiveItself(uint256 _votingNumber) public
        returns(bool) {
            require(switch__withdraw[_votingNumber], "not opening incentive withdraw");
            require(!hasPrevReceived(_votingNumber, msg.sender), "already received incentive");

            token.transfer(msg.sender, getPrevIncentiveAmountPerOne(_votingNumber, msg.sender));
            if(!prevTapVotingList[_votingNumber].writePartyDict(msg.sender,BaseVoting.VOTE_STATE.NONE,0,true)) { revert(); }
            emit ReceiveIncentive(_votingNumber, msg.sender, getPrevIncentiveAmountPerOne(_votingNumber, msg.sender));
    }


    /*
    function _sendIncentivePerOne(address account) internal returns(uint256) {
        //TODO: sender must be the contract
        token.transfer(account, getIncentiveAmountPerOne(account));
    }
    function sendIncentive() external onlyDevelopers returns(bool) {

        for(uint i=0; i<___.length; i++){
            _sendIncentivePerOne(___[i]);
        }
    }
    */
}
