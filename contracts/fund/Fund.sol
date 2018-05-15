/*
 * This contract is about manipulating funded ether.
 * After DAICO, funded ether follows this contract.
 */
pragma solidity ^0.4.23;

import "../fund/IncentivePool.sol";
import "../fund/ReservePool.sol";
import "../token/CustomToken.sol";
import "../token/VestingTokens.sol";
import "../ownership/Ownable.sol";
import "../vote/VotingFactory.sol";
import "../lib/Param.sol";

contract Fund is Ownable, Param {
    /* Library and Typedefs */
    enum FUNDSTATE {
        BEFORE_SALE,
        CROWDSALE,
        WORKING,
        LOCKED,
        COLLAPSED
    }

    /* Global Variables */
    // totalEther = [contract_account].balance
    FUNDSTATE state;
    CustomToken token;
    VestingTokens vestingTokens;
    address teamWallet; // no restriction for withdrawing
    address mCrowdsaleAddress;
    uint256 tap;
    uint256 public lastWithdrawTime;

    bool private switch__constructor = false;
    bool private switch__dividePoolAfterSale = false;
    bool private switch__lock_fund = false;


    VotingFactory votingFactory;
    ReservePool res_pool;
    IncentivePool inc_pool;

    /* Modifiers */
    modifier period(FUNDSTATE _state) {
        require(state == _state);
        _;
    }

    modifier unlock {
        require(!switch__lock_fund);
        _;
    }

    modifier lock {
        require(switch__lock_fund);
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
    event SetVotingFactoryAddress(address indexed voting_factory_addr, address indexed setter);
    event SetCrowdsaleAddress(address indexed crowdsale_addr, address indexed setter);
    event SetVestingTokensAddress(address indexed vesting_tokens_addr, address indexed setter);
    event ChangeFundState(uint256 indexed time, FUNDSTATE indexed changed_state);
    event ChangeTap(uint256 indexed time, uint256 indexed changed_tap);
    event DividePoolAfterSale(address indexed inc_addr, address indexed res_addr);
    event WithdrawTap(uint256 indexed time, address indexed _teamwallet);
    event WithdrawFromIncentive(uint256 indexed time, address indexed _caller);
    event WithdrawFromReserve(uint256 indexed time, address indexed _teamwallet);
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
            state = FUNDSTATE.BEFORE_SALE;
            // setFundAddress(address(this)); //FIXIT: set fund address in Members.fundAddress
            token = CustomToken(_token);
            teamWallet = _teamWallet;
            tap = INITIAL_TAP;
            lastWithdrawTime = now;
    }
    /* View Function */
    // function getVestingRate() view public //FIXIT: is it needed? => I think No
    //     returns(uint256) {
    //         uint256 term = now.sub(SALE_START_TIME);
    //         return term.div(DEV_VESTING_PERIOD);
    // }
    // // the total supply of unlocked token
    function publicSupply() public view
        returns(uint256) {
            require(address(token) != 0x0);
            return token.totalSupply().sub(token.balanceOf(address(vestingTokens)));
    }

    // function getState() view public
    //     returns(FUNDSTATE) {
    //         return state;
    // }

    // function getToken() view public
    //     returns(address) {
    //         return address(token);
    // }

    // function getTeamWallet() view public
    //     returns(address) {
    //         return teamWallet;
    // }

    // function getTap() view public
    //     returns(uint256) {
    //         return tap;
    // }

    // function getVotingFactoryAddress() view public
    //     returns(address) {
    //         return address(votingFactory);
    // }

    // function getIncentiveAddress() view public
    //     returns(address) {
    //         return address(inc_pool);
    // }

    // function getReserveAddress() view public
    //     returns(address) {
    //         return address(res_pool);
    // }

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
            require(address(votingFactory) == 0x0);

            votingFactory = VotingFactory(_votingfacaddr);
            // emit SetVotingFactoryAddress(_votingfacaddr, msg.sender);
            return true;
    }

    function setCrowdsaleAddress(address _crowdsaleAddress) external
        onlyDevelopers
        unlock
        returns(bool) {
            require(_crowdsaleAddress != 0x0);
            require(mCrowdsaleAddress == 0x0);

            mCrowdsaleAddress = _crowdsaleAddress;
            // emit SetCrowdsaleAddress(_crowdsale, msg.sender);
            return true;
    }

    function setVestingTokensAddress(address _vestingTokensAddr) external
        onlyDevelopers
        unlock
        returns(bool) {
            require(_vestingTokensAddr != 0x0);
            require(address(vestingTokens) == 0x0);

            vestingTokens = VestingTokens(_vestingTokensAddr);
            // emit SetVestingTokensAddress(_vestingTokensAddr, msg.sender);
            return true;
    }

    function createIncentivePool() external
        onlyDevelopers
        unlock{
            inc_pool = new IncentivePool(address(token), address(this), address(members));
    }
    function createReservePool() external
        onlyDevelopers
        unlock{
            res_pool = new ReservePool(address(token), address(this), teamWallet, address(members));
    }

    /* Fallback Function */
    function () external payable {}

    /* State Function */
    function startSale() public
        period(FUNDSTATE.BEFORE_SALE)
        only(mCrowdsaleAddress) {
            state = FUNDSTATE.CROWDSALE;
            emit ChangeFundState(now, state);
    }

    function finalizeSale() public
        period(FUNDSTATE.CROWDSALE)
        only(mCrowdsaleAddress) {
            state = FUNDSTATE.WORKING;
            emit ChangeFundState(now, state);
    }

    function lockFund() public
        period(FUNDSTATE.WORKING)
        only(address(votingFactory.mRefundVotingAddress()))
        unlock
        returns(bool) {
            state = FUNDSTATE.LOCKED;
            switch__lock_fund = true;
            if(!vestingTokens.lock()) { revert(); }
            emit ChangeFundState(now, state);
            return true;
    }

    /* Tap Function */
    function changeTap(uint _tap) public
        period(FUNDSTATE.WORKING)
        only(address(votingFactory.mTapVotingAddress()))
        unlock
        returns(bool) {
            tap = _tap;
            emit ChangeTap(now, tap);
            return true; 
    }
    // We should compress below two funcs in one

    // function increaseTap(uint256 change) public
    //     period(FUNDSTATE.WORKING)
    //     only(address(votingFactory.mTapVotingAddress()))
    //     unlock
    //     returns(bool) {
    //         tap = tap.add(change);
    //         emit ChangeTap(now, tap);
    //         return true;
    // }

    // function decreaseTap(uint256 change) public
    //     period(FUNDSTATE.WORKING)
    //     only(address(votingFactory.mTapVotingAddress()))
    //     unlock
    //     returns(bool) {
    //         tap = tap.sub(change);
    //         emit ChangeTap(now, tap);
    //         return true;
    // }

    // /* Withdraw Function */
    function dividePoolAfterSale(uint256[3] asset_percent) public
        period(FUNDSTATE.WORKING)
        only(mCrowdsaleAddress) {
            //asset_percent = [public, incentive, reserve] = total 100
            require(!switch__dividePoolAfterSale);

            switch__dividePoolAfterSale = true; // this function is called only once.
            token.transfer(address(inc_pool), address(this).balance.mul(asset_percent[1]).div(100));
            token.transfer(address(res_pool), address(this).balance.mul(asset_percent[2]).div(100));
            emit DividePoolAfterSale(address(inc_pool), address(res_pool));
    }

    function withdrawTap() public
        period(FUNDSTATE.WORKING)
        only(address(votingFactory.mTapVotingAddress()))
        unlock
        payable
        returns(bool) {
            require(teamWallet != 0x0);
            require(getWithdrawable() != 0);

            uint256 withdraw_amount = getWithdrawable();
            teamWallet.transfer(withdraw_amount); //payable
            if(!_withdrawFromIncentive(withdraw_amount)) {revert();}
            emit WithdrawTap(now, teamWallet);
            return true;
    }
    function _withdrawFromIncentive(uint256 withdraw_amt) private
        period(FUNDSTATE.WORKING)
        unlock
        returns(bool) {
            require(address(inc_pool) != 0x0);

            if(!inc_pool.withdraw(withdraw_amt)) {revert();}
            emit WithdrawFromIncentive(now, msg.sender);
            return true;
    }

    // function withdrawFromReserve(uint256 weiAmount) external
    //     onlyDevelopers
    //     period(FUNDSTATE.WORKING)
    //     unlock
    //     returns(bool) {
    //         require(address(res_pool) != 0x0);
    //         require(weiAmount > 0);
    //         require(weiAmount <= address(res_pool).balance);

    //         //TODO: not implemented
    //         uint256 tokenAmount = 100;
    //         if(!res_pool.withdraw(tokenAmount)) {revert();}
    //         emit WithdrawFromReserve(now, teamWallet);
    //         return true;
    // }
    // Just withdraw from reserve contract, not here

    /* Refund Function */
    function refund() external
        period(FUNDSTATE.LOCKED)
        lock
        allset
        returns(bool) {

            uint256 refundETH = address(this).balance.mul(token.balanceOf(msg.sender)).div(publicSupply()); // refund ETH = remained ETH * (Token Amount) / (Public Token Supply)
            if(!msg.sender.send(refundETH)) {revert(); }
            emit Refund(now, msg.sender, refundETH);
            return true;
    }

    function dead() external
        period(FUNDSTATE.LOCKED)
        lock
        allset
        returns(bool) {
            require(address(this).balance <= 10 ether);
            state = FUNDSTATE.COLLAPSED;
            return true;
        }
}

