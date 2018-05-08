/*
 * This contract is about manipulating funded ether.
 * After DAICO, funded ether follows this contract.
 */
pragma solidity ^0.4.23;

import "../fund/IncentivePool.sol";
import "../fund/ReservePool.sol";
import "../token/ERC20.sol";
import "../token/IERC20.sol";
import "../token/VestingTokens.sol";
import "../crowdsale/Crowdsale.sol";
import "../ownership/Ownable.sol";
import "../ownership/Members.sol";
import "../vote/VotingFactory.sol";
import "../vote/TapVoting.sol";
import "../vote/RefundVoting.sol";
import "../lib/SafeMath.sol";
import "../lib/Param.sol";

contract Fund is Ownable, Param {
    /* Library and Typedefs */
    using SafeMath for uint256;
    enum FUNDSTATE {
        BEFORE_SALE,
        CROWDSALE,
        WORKING,
        LOCKED,
        COLLAPSED
    }

    /* Global Variables */
    // totalEther = [contract_account].balance
    FUNDSTATE public state;
    ERC20 public token;
    VestingTokens public vestingTokens;
    address public teamWallet; // no restriction for withdrawing
    uint256 public tap;
    uint256 public lastWithdrawTime;

    bool private switch__constructor = false;
    bool private switch__dividePoolAfterSale = false;
    bool private switch__lock_fund = false;

    Crowdsale public crowdsale;
    VotingFactory public votingFactory;
    TapVoting public tapVoting;
    RefundVoting public refundVoting;
    ReservePool public res_pool;
    IncentivePool public inc_pool;

    /* Modifiers */
    modifier period(FUNDSTATE _state) {
        require(state == _state, "Fund period is not matching");
        _;
    }

    modifier unlock {
        require(!switch__lock_fund, "fund has locked");
        _;
    }

    modifier lock {
        require(switch__lock_fund, "It is only executable when fund is locked");
        _;
    }

    modifier allset {
        require(address(token) != 0x0);
        require(address(vestingTokens) != 0x0);
        require(teamWallet != 0x0);
        require(address(members) != 0x0);
        require(address(inc_pool) != 0x0);
        require(address(res_pool) != 0x0);
        _;
    }

    /* Events */
    event CreateFund(address indexed token_address, address indexed team_wallet, address indexed fund_addr);
    event SetVotingFactoryAddress(address indexed voting_factory_addr, address indexed setter);
    event SetCrowdsaleAddress(address indexed voting_factory_addr, address indexed setter);
    event SetVestingTokensAddress(address indexed vesting_tokens_addr, address indexed setter);
    event ChangeFundState(uint256 indexed time, FUNDSTATE indexed changed_state);
    event ChangeTap(uint256 indexed time, uint256 indexed changed_tap);
    event DividePoolAfterSale(address indexed fund_addr, address indexed inc_addr, address indexed res_addr);
    event WithdrawTap(uint256 indexed time, address indexed fund_addr, address indexed _teamwallet);
    event WithdrawFromIncentive(uint256 indexed time, address indexed inc_addr, address indexed _caller);
    event WithdrawFromReserve(uint256 indexed time, address indexed res_addr, address indexed _teamwallet);
    event Refund(uint256 indexed time, address indexed refund_addr, uint256 indexed wei_amount);
    //add more

    /* Constructor */
    constructor(
        address _token,
        address _teamWallet,
        address _membersAddress
        ) public Ownable(_membersAddress) {
            require(!switch__constructor);
            require(_token != 0x0);
            require(_teamWallet != 0x0);
            require(_membersAddress != 0x0);
            switch__constructor = true;
            _constructor(_token, _teamWallet, _membersAddress);
    }
    function _constructor(
        address _token,
        address _teamWallet,
        address _membersAddress
    ) private {
            state = FUNDSTATE.BEFORE_SALE;
            // setFundAddress(address(this)); //FIXIT: set fund address in Members.fundAddress
            token = ERC20(_token);
            teamWallet = _teamWallet;
            inc_pool = new IncentivePool(address(token), address(this), _membersAddress);
            res_pool = new ReservePool(address(token), address(this), teamWallet, _membersAddress);
            tap = INITIAL_TAP;
            lastWithdrawTime = now;
            emit CreateFund(token, teamWallet, address(this));
    }
    /* View Function */
    function getVestingRate() view public //FIXIT: is it needed?
        returns(uint256) {
            uint256 term = now.sub(crowdsale.getStartTime());
            return term.div(DEV_VESTING_PERIOD);
    }
    // the total supply of unlocked token
    function publicSupply() public view
        returns(uint256) {
            require(address(token) != 0x0);
            return token.totalSupply().sub(token.balanceOf(address(vestingTokens)));
    }

    function getState() view public
        returns(FUNDSTATE) {
            return state;
    }

    function getToken() view public
        returns(IERC20) {
            return token;
    }

    function getTeamWallet() view public
        returns(address) {
            return teamWallet;
    }

    function getTap() view public
        returns(uint256) {
            return tap;
    }

    function getVotingFactoryAddress() view public
        returns(address) {
            return address(votingFactory);
    }

    function getIncentiveAddress() view public
        returns(address) {
            return address(inc_pool);
    }

    function getReserveAddress() view public
        returns(address) {
            return address(res_pool);
    }

    function getWithdrawable() view public
        returns(uint256) {
            return tap.mul(now.sub(lastWithdrawTime));
    }

    function getLocked() view public
        returns(bool) {
            return switch__lock_fund;
    }

    /* Set Function */
    function setVotingFactoryAddress(address _votingfacaddr) external
        onlyDevelopers
        unlock
        returns(bool) {
            require(_votingfacaddr != 0x0);
            require(address(votingFactory) == 0x0, "should call only once");

            votingFactory = VotingFactory(_votingfacaddr);
            emit SetVotingFactoryAddress(_votingfacaddr, msg.sender);
            return true;
    }

    function setCrowdsaleAddress(address _crowdsale) external
        onlyDevelopers
        unlock
        returns(bool) {
            require(_crowdsale != 0x0);
            require(address(crowdsale) == 0x0, "should call only once");

            crowdsale = Crowdsale(_crowdsale);
            emit SetCrowdsaleAddress(_crowdsale, msg.sender);
            return true;
    }

    function setVestingTokensAddress(address _vestingTokensAddr) external
        onlyDevelopers
        unlock
        returns(bool) {
            require(_vestingTokensAddr != 0x0);
            require(address(vestingTokens) == 0x0, "should call only once");

            vestingTokens = VestingTokens(_vestingTokensAddr);
            emit SetVestingTokensAddress(_vestingTokensAddr, msg.sender);
            return true;
    }


    /* Fallback Function */
    function () external payable {}

    /* State Function */
    function startSale() public
        period(FUNDSTATE.BEFORE_SALE)
        only(address(crowdsale)) {
            state = FUNDSTATE.CROWDSALE;
            emit ChangeFundState(now, state);
    }

    function finalizeSale() public
        period(FUNDSTATE.CROWDSALE)
        only(address(crowdsale)) {
            state = FUNDSTATE.WORKING;
            emit ChangeFundState(now, state);
    }

    function lockFund() public
        period(FUNDSTATE.WORKING)
        only(address(refundVoting))
        unlock
        returns(bool) {
            state = FUNDSTATE.LOCKED;
            switch__lock_fund = true;
            if(!vestingTokens.lock()) { revert(); }
            emit ChangeFundState(now, state);
            return true;
    }

    /* Tap Function */
    function increaseTap(uint256 change) public
        period(FUNDSTATE.WORKING)
        only(address(tapVoting))
        unlock
        returns(bool) {
            tap = tap.add(change);
            emit ChangeTap(now, tap);
            return true;
    }

    function decreaseTap(uint256 change) public
        period(FUNDSTATE.WORKING)
        only(address(tapVoting))
        unlock
        returns(bool) {
            tap = tap.sub(change);
            emit ChangeTap(now, tap);
            return true;
    }

    /* Withdraw Function */
    function dividePoolAfterSale(uint256[3] asset_percent) public
        period(FUNDSTATE.WORKING)
        only(address(crowdsale)) {
            //asset_percent = [public, incentive, reserve] = total 100
            require(!switch__dividePoolAfterSale, "this function should be called only once.");

            switch__dividePoolAfterSale = true; // this function is called only once.
            token.transfer(address(inc_pool), address(this).balance.mul(asset_percent[1]).div(100));
            token.transfer(address(res_pool), address(this).balance.mul(asset_percent[2]).div(100));
            emit DividePoolAfterSale(address(this), address(inc_pool), address(res_pool));
    }

    function withdrawTap() public
        period(FUNDSTATE.WORKING)
        only(address(tapVoting))
        unlock
        payable
        returns(bool) {
            require(teamWallet != 0x0, "teamWallet has not determined.");
            require(getWithdrawable() != 0, "not enough withdrawable ETH.");

            uint256 withdraw_amount = getWithdrawable();
            teamWallet.transfer(withdraw_amount); //payable
            if(!_withdrawFromIncentive(withdraw_amount)) {revert();}
            emit WithdrawTap(now, address(this), teamWallet);
            return true;
    }
    function _withdrawFromIncentive(uint256 withdraw_amt) private
        period(FUNDSTATE.WORKING)
        unlock
        returns(bool) {
            require(address(inc_pool) != 0x0, "Incentive pool has not deployed.");

            if(!inc_pool.withdraw(withdraw_amt)) {revert();}
            emit WithdrawFromIncentive(now, address(inc_pool), msg.sender);
            return true;
    }

    function withdrawFromReserve(uint256 weiAmount) external
        onlyDevelopers
        period(FUNDSTATE.WORKING)
        unlock
        returns(bool) {
            require(address(res_pool) != 0x0, "Reserve pool has not deployed.");
            require(weiAmount <= address(res_pool).balance, "Not enough balance in reserve pool.");

            //TODO: not implemented
            uint256 tokenAmount = 100;
            if(!res_pool.withdraw(tokenAmount)) {revert();}
            emit WithdrawFromReserve(now, address(res_pool), teamWallet);
            return true;
    }

    /* Refund Function */
    function refund() external
        period(FUNDSTATE.LOCKED)
        lock
        allset
        returns(bool) {

            uint256 refundETH = address(this).balance.mul(token.balanceOf(msg.sender)).div(publicSupply()); // refund ETH = remained ETH * (Token Amount) / (Public Token Supply)
            if(!msg.sender.send(refundETH)) {revert("cannot refund."); }
            emit Refund(now, msg.sender, refundETH);
            return true;
    }

    function dead() external
        period(FUNDSTATE.LOCKED)
        lock
        allset
        returns(bool) {
            require(address(this).balance <= 10 ether, "it is temporary value");
            state = FUNDSTATE.COLLAPSED;
            return true;
        }
}

