pragma solidity ^0.4.23;

import "../token/CustomToken.sol";
import "../fund/Fund.sol";
import "../lib/SafeMath.sol";
import "../lib/Param.sol";
import "../ownership/Ownable.sol";
import "../token/VestingTokens.sol";
import "./ICrowdsale.sol";
/**
 * @title Crowdsale
 * @dev Crowdsale is a base contract for managing a token crowdsale.
 * Crowdsales have a start and end timestamps, where investors can make
 * token purchases and the crowdsale will assign them tokens based
 * on a token per ETH rate. Funds collected are forwarded to a wallet
 * as they arrive. The contract requires a MintableToken that will be
 * minted as contributions arrive, note that the crowdsale contract
 * must be owner of the token in order to be able to mint it.
 */
contract Crowdsale is Ownable, ICrowdsale, Param {
    /* Library and Typedefs */
    using SafeMath for uint256;
    enum STATE {PREPARE, ACTIVE, FINISHED, FINALIZED, REFUND}
    struct Purchase{
        uint ethers;
        uint tokens;
    }
    struct Whitelist{
        bool isListed;
        uint maxcap;
    }

    /* Global Variables */
    CustomToken public mToken; //address
    Fund public mFund; // ether bank, it should be Fund.sol's Contract address
    VestingTokens public mVestingTokens;

    uint public mCurrentAmount; //ether amount
    uint public mContributedTokens = 0;
    //discount rate -20%(~1/8) => -15%(~2/8) => -10%(~3/8) => -5%(~4/8) =>0%(~8/8)
    uint public mCurrentDiscountPerc = 20; //inital discount rate
    STATE public mCurrentState = STATE.PREPARE;

    //index => address => amount set of crowdsale participants
    mapping(address => Whitelist) mWhitelist;
    mapping(address => uint) public mPrivateSale;
    mapping(address => uint) public mDevelopers;
    mapping(address => uint) public mAdvisors;
    mapping(address => Purchase) public mContributors;
    address[] public mPrivateSaleIndex;
    address[] public mDevelopersIndex;
    address[] public mAdvisorsIndex;



    /* Events */
    event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 wei_amount, uint256 token_amount);
    event EtherChanges(address indexed purchaser, uint value); // send back ETH changes
    event StateChanged(string state, uint time);
    event RefundEthers(address indexed _receiver, uint _ethers);



    /* Modifiers */
    modifier period(STATE _state) {
        require(mCurrentState == _state, "Crowdsale Period is not matching");
        _;
    }



    /* Constructor */
    constructor(
        address _tokenAddress,
        address _fundAddress,
        address _membersAddress
        ) public
        Ownable(_membersAddress) {
            require(_fundAddress != address(0));
            require(_tokenAddress != address(0));
            require(_membersAddress != address(0));

            mFund = Fund(_fundAddress);
            mToken = CustomToken(_tokenAddress);
    }



    /* View Function */
    function getStartTime() view public returns(uint256) { return SALE_START_TIME; }
    function getEndTime() view public returns(uint256) { return SALE_END_TIME; }

    function getFundingGoal() view public returns(uint256) { return HARD_CAP; }
    function getCurrentSate() view external
        returns(string){
            if(mCurrentState == STATE.PREPARE){
                return "PREPARE";
            } else if(mCurrentState == STATE.ACTIVE){
                return "ACTIVE";
            } else if(mCurrentState == STATE.FINISHED){
                return "FINISHED";
            } else if(mCurrentState == STATE.FINALIZED){
                return "FINALIZED";
            } else if(mCurrentState == STATE.REFUND){
                return "REFUND";
            } else
                return "SOMETHING WORNG";
    }
    // get current rate including the dicount percentage
    function getRate() public view 
        returns (uint){
            uint rate = DEFAULT_RATE;
            if(mCurrentDiscountPerc == 0){
                return rate;
            } else{
                return rate.mul(100).div(100 - mCurrentDiscountPerc);
            }
    }
    // calculate next cap
    // Override this with custom calculation
    function getNextCap() public view 
        returns(uint){
            require(mCurrentDiscountPerc > 0, "No Discount Any More");
            return HARD_CAP.mul(5 - mCurrentDiscountPerc/5).div(8);
    }

    function getCurrentAmount() view public returns(uint256) { return mCurrentAmount; }
    //divide type and check amount of current locked tokens
    function getLockedAmount(VestingTokens.LOCK_TYPE _type) view public 
        returns(uint256){
            uint i;
            uint sum = 0;

            if(_type == VestingTokens.LOCK_TYPE.DEV){
                for (i = 0; i < mDevelopersIndex.length; i++) {
                    sum += mDevelopers[mDevelopersIndex[i]];
                }
            } else if(_type == VestingTokens.LOCK_TYPE.ADV){
                for (i = 0; i < mAdvisorsIndex.length; i++) {
                    sum += mAdvisors[mAdvisorsIndex[i]];
                }
            } else if(_type == VestingTokens.LOCK_TYPE.PRIV){
                for (i = 0; i < mPrivateSaleIndex.length; i++) {
                    sum += mPrivateSale[mPrivateSaleIndex[i]];
                }
            } else
                revert("Wrong Type");

            return sum;
    }
    // Business logic could be described here or getRate()
    function getTokenAmount(uint256 weiAmount) internal view 
        returns (uint256) {
            return weiAmount.mul(getRate());
    }

    // function which checks the amount would be over next cap
    function isOver() public view 
        returns(bool){
            if(mCurrentDiscountPerc == 0){
                if(address(this).balance >= HARD_CAP){
                    return true;
                } else{
                    return false;
                }
            }
            if(address(this).balance >= getNextCap()){
                return true;
            } else{
                return false;
            }
    }
    //check the percentage of locked tokens filled;
    function isLockFilled() public view
        returns(bool){
            uint currentLockedAmount = getLockedAmount(VestingTokens.LOCK_TYPE.DEV);
            if(currentLockedAmount < mToken.totalSupply().div(1000).mul(DEV_TOKEN_PERC)){
                revert("Developers Not Filled : "); // FIXIT:  +mToken.totalSupply().div(1000).mul(DEV_TOKEN_PERC).sub(currentLockedAmount));
            }
            currentLockedAmount = getLockedAmount(VestingTokens.LOCK_TYPE.ADV);
            if(currentLockedAmount < mToken.totalSupply().div(1000).mul(ADV_TOKEN_PERC)){
                revert("Advisors Not Filled : "); // FIXIT:  +mToken.totalSupply().div(1000).mul(ADV_TOKEN_PERC).sub(currentLockedAmount));
            }
            currentLockedAmount = getLockedAmount(VestingTokens.LOCK_TYPE.PRIV);
            if(currentLockedAmount < mToken.totalSupply().div(1000).mul(PRIV_TOKEN_PERC)){
                revert("PrivateSale Not Filled : "); // FIXIT:  +mToken.totalSupply().div(1000).mul(PRIV_TOKEN_PERC).sub(currentLockedAmount));
            }
            return true;
    }



    /* Change CrowdSale State, call only once */
    function activateSale() public 
        onlyOwner period(STATE.PREPARE){
            require(now >= SALE_START_TIME && now < SALE_END_TIME, "Worng Time");
            require(mVestingTokens != address(0));
            require(mToken.balanceOf(address(this)) == mToken.totalSupply());

            mCurrentState = STATE.ACTIVE;
            mFund.startSale(); // tell crowdsale started
            emit StateChanged("ACTIVE", now);
    }
    function finishSale() public 
        onlyOwner period(STATE.ACTIVE){
            require(now >= SALE_END_TIME);
            require(address(this).balance >= SOFT_CAP);
            _finish();
    }
    function finalizeSale() public
        onlyOwner period(STATE.FINISHED) {
            _finalize();
            mCurrentState = STATE.FINALIZED;
            emit StateChanged("FINALIZED", now);
    }
    function activeRefund() public
        period(STATE.ACTIVE){
            require(now >= SALE_END_TIME);
            require(address(this).balance < SOFT_CAP);
            mCurrentState = STATE.REFUND;
    }



    /* Fallback Function */
    function () external payable {
            buyTokens(msg.sender);
    }



    /* Token Purchase Function */
    function buyTokens(address _beneficiary) public payable 
        period(STATE.ACTIVE) {
            require(_beneficiary != address(0));
            require(msg.value > 0);
            require(now >= SALE_START_TIME && now < SALE_END_TIME);
            require(mWhitelist[_beneficiary].isListed);

            uint weiAmount = msg.value;
            require(mWhitelist[_beneficiary].maxcap >= mContributors[_beneficiary].ethers.add(weiAmount));
            // calculate token amount to be created
            uint tokens;
            if(!isOver()){ //check if estimate ether exceeds next cap
                tokens = getTokenAmount(weiAmount);
                emit TokenPurchase(msg.sender, _beneficiary, weiAmount, tokens);
            } else{
                //when estimate ether exceeds next cap
                //we divide input ether by next cap
                uint ether1;
                uint ether2;
                if(mCurrentDiscountPerc > 0){
                    // When discount rate should be changed
                    ether2 = address(this).balance.sub(getNextCap()); //(balance + weiAmount) - NEXT_CAP
                    ether1 = weiAmount.sub(ether2);
                    tokens = getTokenAmount(ether1);
                    emit TokenPurchase(msg.sender, _beneficiary, ether1, tokens);

                    mCurrentDiscountPerc = mCurrentDiscountPerc.sub(5); // Update discount percentage
                    uint additionalTokens = getTokenAmount(ether2);
                    emit TokenPurchase(msg.sender, _beneficiary, ether2, additionalTokens);
                    tokens = tokens.add(additionalTokens);
                } else if(mCurrentDiscountPerc == 0){
                    // Do when CrowdSale Ended
                    ether2 = address(this).balance.sub(HARD_CAP);
                    ether1 = weiAmount.sub(ether2);
                    tokens = getTokenAmount(ether1);

                    emit TokenPurchase(msg.sender, _beneficiary, ether1, tokens);
                    msg.sender.transfer(ether2); //pay back
                    emit EtherChanges(msg.sender, ether2);
                    //add to map
                    _addToUserContributed(_beneficiary, ether1, tokens);
                    _finish();
                    //finalize CrowdSale
                    return;
                } else{
                    revert("DiscountRate should be positive");
                }
            }
            //add to map
            _addToUserContributed(_beneficiary, weiAmount, tokens);
    }
    function _addToUserContributed(
        address _address,
        uint _additionalEther,
        uint _additionalToken) private
        period(STATE.ACTIVE){
            mContributors[_address].tokens = mContributors[_address].tokens.add(_additionalToken);
            mContributors[_address].ethers = mContributors[_address].ethers.add(_additionalEther);
            
            mContributedTokens += _additionalToken;
    }
    function receiveTokens() public 
        period(STATE.FINALIZED){
            require(mContributors[msg.sender].tokens > 0);
            mToken.transfer(msg.sender, mContributors[msg.sender].tokens);
            delete mContributors[msg.sender];
    }

    function refund() public 
        period(STATE.REFUND){
            require(mContributors[msg.sender].ethers > 0);
            uint ethers = mContributors[msg.sender].ethers;
            msg.sender.transfer(ethers);
            delete mContributors[msg.sender];
            emit RefundEthers(msg.sender, ethers);
    }



    /* Set Functions */
    //setting vesting token address only once
    function setVestingTokens(address _vestingTokensAddress) public 
        onlyOwner period(STATE.PREPARE) {
            require(mVestingTokens == address(0)); //only once
            mVestingTokens = VestingTokens(_vestingTokensAddress);
    }
    function addWhitelist(address _whitelist, uint _maxcap) public onlyOwner{
        require(mCurrentState < STATE.FINISHED);
        mWhitelist[_whitelist].isListed = true;
        mWhitelist[_whitelist].maxcap = _maxcap;
    }
    //add developers, advisors, privateSale
    //check if it exceeds percentage
    function setToDevelopers(address _address, uint _tokenWeiAmount) public 
        onlyOwner{
            require(_address != address(0));
            if(mDevelopers[_address] > 0){
                mDevelopers[_address] = _tokenWeiAmount;
            } else{
                mDevelopers[_address] = _tokenWeiAmount;
                mDevelopersIndex.push(_address);
            }
            uint lockedAmount = getLockedAmount(VestingTokens.LOCK_TYPE.DEV);
            require(lockedAmount <= mToken.totalSupply().div(1000).mul(DEV_TOKEN_PERC), "Over!");
            // Solidity will roll back when it reverted
    }
    function setToAdvisors(address _address, uint _tokenWeiAmount) public 
        onlyOwner{
            require(_address != address(0));
            if(mAdvisors[_address] > 0){
                mAdvisors[_address] = _tokenWeiAmount;
            } else{
                mAdvisors[_address] = _tokenWeiAmount;
                mAdvisorsIndex.push(_address);
            }
            uint lockedAmount = getLockedAmount(VestingTokens.LOCK_TYPE.ADV);
            require(lockedAmount <= mToken.totalSupply().div(1000).mul(ADV_TOKEN_PERC), "Over!");
            // Solidity will roll back when it reverted
    }
    function setToPrivateSale(address _address, uint _tokenWeiAmount) public 
        onlyOwner{
            require(_address != address(0));
            if(mPrivateSale[_address] > 0){
                mPrivateSale[_address] = _tokenWeiAmount;
            } else{
                mPrivateSale[_address] = _tokenWeiAmount;
                mPrivateSaleIndex.push(_address);
            }
            uint lockedAmount = getLockedAmount(VestingTokens.LOCK_TYPE.PRIV);
            require(lockedAmount <= mToken.totalSupply().div(1000).mul(PRIV_TOKEN_PERC), "Over!");
            // Solidity will roll back when it reverted
    }



    /* Finalizing Functions */
    function _finish() private 
        period(STATE.ACTIVE){
            mCurrentState = STATE.FINISHED;
            emit StateChanged("FINISHED", now);
    }
    function _finalize() private {
            //lock up tokens
            require(isLockFilled());
            _lockup();
            //finalize funds
            //give initial fund
            _forwardFunds();
            mFund.finalizeSale();
            _dividePool();
            //Refund vote activate
            //set tapVoting available
            //change state
    }

    function _lockup() private {
            //lock tokens
            uint i = 0;
            for (i = 0; i < mPrivateSaleIndex.length; i++) {
                mVestingTokens.lockup(
                    mPrivateSaleIndex[i],
                    mPrivateSale[mPrivateSaleIndex[i]],
                    VestingTokens.LOCK_TYPE.PRIV
                );
            }
            for (i = 0; i < mDevelopersIndex.length; i++) {
                mVestingTokens.lockup(
                    mDevelopersIndex[i],
                    mDevelopers[mDevelopersIndex[i]],
                    VestingTokens.LOCK_TYPE.DEV
                );
            }
            for (i = 0; i < mAdvisorsIndex.length; i++) {
                mVestingTokens.lockup(
                    mAdvisorsIndex[i],
                    mAdvisors[mAdvisorsIndex[i]],
                    VestingTokens.LOCK_TYPE.ADV
                );
            }
            //send Vesting tokens to VestingTokens.sol
            mToken.transfer(mVestingTokens, mToken.totalSupply().div(1000).mul(DEV_TOKEN_PERC + ADV_TOKEN_PERC + PRIV_TOKEN_PERC));
    }
    // send ether to the fund collection wallet
    // override to create custom fund forwarding mechanisms
    function _forwardFunds() private 
        returns (bool){
            address(mFund).transfer(address(this).balance); //send ether
            mToken.transfer(mFund, mToken.totalSupply().div(1000).mul(RESERVE_TOKEN_PERC+REWARD_TOKEN_PERC+INCENTIVE_TOKEN_PERC)); //send tokens
            return true;
    }
    function _dividePool() internal {
            mFund.dividePoolAfterSale([PUB_TOKEN_PERC, INCENTIVE_TOKEN_PERC, RESERVE_TOKEN_PERC]);
    }
}
