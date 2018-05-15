pragma solidity ^0.4.23;

import "../token/CustomToken.sol";
import "../fund/Fund.sol";
import "../lib/SafeMath.sol";
import "../lib/Param.sol";
import "../ownership/Ownable.sol";
import "../token/IVestingTokens.sol";
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
    struct Purchase{
        uint ethers;
        uint tokens;
    }
    struct Whitelist{
        bool isListed;
        uint maxcap;
    }

    /* Global Variables */
    CustomToken mToken; //address
    Fund mFund; // ether bank, it should be Fund.sol's Contract address
    IVestingTokens mVestingTokens;

    uint mCurrentAmount; //ether amount
    uint public mContributedTokens = 0;
    // discount rate -20%(~1/8) => -15%(~2/8) => -10%(~3/8) => -5%(~4/8) => 0%(~8/8)
    // cap is ratio of tokens, discount rate is of ethers
    uint8 public mCurrentDiscountPerc = 20; //inital discount rate
    STATE mCurrentState = STATE.PREPARE;

    // index => address => amount set of crowdsale participants
    mapping(address => Whitelist) public mWhitelist;
    mapping(address => uint) mPrivateSale;
    mapping(address => uint) mDevelopers;
    mapping(address => uint) mAdvisors;
    mapping(address => Purchase) public mContributors;
    address[] mPrivateSaleIndex;
    address[] mDevelopersIndex;
    address[] mAdvisorsIndex;



    /* Events */
    event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 wei_amount, uint256 token_amount);
    event EtherChanges(address indexed purchaser, uint value); // send back ETH changes
    event StateChanged(STATE state, uint time);
    event RefundEthers(address indexed _receiver, uint _ethers);



    /* Modifiers */
    modifier period(STATE _state) {
        require(mCurrentState == _state);
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
    function getStartTime() view external returns(uint256) { return SALE_START_TIME; }
    function getEndTime() view external returns(uint256) { return SALE_END_TIME; }
    function getFundingGoal() view external returns(uint256) { return HARD_CAP; }
    function getCurrentSate() view external
        returns(STATE){
            if(mCurrentState == STATE.PREPARE){
                return STATE.PREPARE;
            } else if(mCurrentState == STATE.ACTIVE){
                return STATE.ACTIVE;
            } else if(mCurrentState == STATE.FINISHED){
                return STATE.FINISHED;
            } else if(mCurrentState == STATE.FINALIZED){
                return STATE.FINALIZED;
            } else if(mCurrentState == STATE.REFUND){
                return STATE.REFUND;
            } else
                revert();
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
            require(mCurrentDiscountPerc > 0);
            return HARD_CAP.mul(5 - mCurrentDiscountPerc/5).div(8);
    }

    //divide type and check amount of current locked tokens
    function getLockedAmount(IVestingTokens.LOCK_TYPE _type) view public 
        returns(uint256){
            uint i;
            uint sum = 0;

            if(_type == IVestingTokens.LOCK_TYPE.DEV){
                for (i = 0; i < mDevelopersIndex.length; i++) {
                    sum += mDevelopers[mDevelopersIndex[i]];
                }
            } else if(_type == IVestingTokens.LOCK_TYPE.ADV){
                for (i = 0; i < mAdvisorsIndex.length; i++) {
                    sum += mAdvisors[mAdvisorsIndex[i]];
                }
            } else if(_type == IVestingTokens.LOCK_TYPE.PRIV){
                for (i = 0; i < mPrivateSaleIndex.length; i++) {
                    sum += mPrivateSale[mPrivateSaleIndex[i]];
                }
            } else
                revert();

            return sum;
    }
    function getPersonalLockedAmount(address _address, IVestingTokens.LOCK_TYPE _type) view public 
        returns(uint256){
            require(_address != address(0));

            if(_type == IVestingTokens.LOCK_TYPE.DEV){
                return mDevelopers[_address];
            } else if(_type == IVestingTokens.LOCK_TYPE.ADV){
                return mAdvisors[_address];
            } else if(_type == IVestingTokens.LOCK_TYPE.PRIV){
                return mPrivateSale[_address];
            } else
                revert();
    }
    // Business logic could be described here or getRate()
    function _getTokenAmount(uint256 weiAmount) private view 
        returns (uint256) {
            return weiAmount.mul(getRate());
    }

    // function which checks the amount would be over next cap
    function _isOver() private view 
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
            uint currentLockedAmount = getLockedAmount(IVestingTokens.LOCK_TYPE.DEV);
            if(currentLockedAmount < mToken.totalSupply().div(1000).mul(DEV_TOKEN_PERC)){
                revert(); // FIXIT:  +mToken.totalSupply().div(1000).mul(DEV_TOKEN_PERC).sub(currentLockedAmount));
            }
            currentLockedAmount = getLockedAmount(IVestingTokens.LOCK_TYPE.ADV);
            if(currentLockedAmount < mToken.totalSupply().div(1000).mul(ADV_TOKEN_PERC)){
                revert(); // FIXIT:  +mToken.totalSupply().div(1000).mul(ADV_TOKEN_PERC).sub(currentLockedAmount));
            }
            currentLockedAmount = getLockedAmount(IVestingTokens.LOCK_TYPE.PRIV);
            if(currentLockedAmount < mToken.totalSupply().div(1000).mul(PRIV_TOKEN_PERC)){
                revert(); // FIXIT:  +mToken.totalSupply().div(1000).mul(PRIV_TOKEN_PERC).sub(currentLockedAmount));
            }
            return true;
    }



    /* Change CrowdSale State, call only once */
    function activateSale() external 
        onlyOwner period(STATE.PREPARE){
            require(now >= SALE_START_TIME && now < SALE_END_TIME);
            require(mVestingTokens != address(0));
            require(mToken.balanceOf(address(this)) == mToken.totalSupply());

            mCurrentState = STATE.ACTIVE;
            mFund.startSale(); // tell crowdsale started
            emit StateChanged(STATE.ACTIVE, now);
    }
    function finishSale() external 
        onlyOwner period(STATE.ACTIVE){
            require(now >= SALE_END_TIME);
            require(address(this).balance >= SOFT_CAP);
            _finish();
    }
    function finalizeSale() external
        onlyOwner period(STATE.FINISHED) {
            _finalize();
            mCurrentState = STATE.FINALIZED;
            emit StateChanged(STATE.FINALIZED, now);
    }
    function activeRefund() external
        period(STATE.ACTIVE){
            require(now >= SALE_END_TIME);
            require(address(this).balance < SOFT_CAP);
            mCurrentState = STATE.REFUND;
            emit StateChanged(STATE.REFUND, now);
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
            if(!_isOver()){ //check if estimate ether exceeds next cap
                tokens = _getTokenAmount(weiAmount);
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
                    tokens = _getTokenAmount(ether1);
                    emit TokenPurchase(msg.sender, _beneficiary, ether1, tokens);

                    uint8 temp = mCurrentDiscountPerc - 5;
                    require(temp < mCurrentDiscountPerc);
                    mCurrentDiscountPerc = temp; // Update discount percentage
                    uint additionalTokens = _getTokenAmount(ether2);
                    emit TokenPurchase(msg.sender, _beneficiary, ether2, additionalTokens);
                    tokens = tokens.add(additionalTokens);
                } else if(mCurrentDiscountPerc == 0){
                    // Do when CrowdSale Ended
                    ether2 = address(this).balance.sub(HARD_CAP);
                    ether1 = weiAmount.sub(ether2);
                    tokens = _getTokenAmount(ether1);

                    emit TokenPurchase(msg.sender, _beneficiary, ether1, tokens);
                    msg.sender.transfer(ether2); //pay back
                    emit EtherChanges(msg.sender, ether2);
                    //add to map
                    _addToUserContributed(_beneficiary, ether1, tokens);
                    _finish();
                    //finalize CrowdSale
                    return;
                } else{
                    revert();
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
    function receiveTokens() external 
        period(STATE.FINALIZED){
            require(mContributors[msg.sender].tokens > 0);
            mToken.transfer(msg.sender, mContributors[msg.sender].tokens);
            delete mContributors[msg.sender];
    }

    function refund() external 
        period(STATE.REFUND){
            require(mContributors[msg.sender].ethers > 0);
            uint ethers = mContributors[msg.sender].ethers;
            msg.sender.transfer(ethers);
            delete mContributors[msg.sender];
            emit RefundEthers(msg.sender, ethers);
    }



    /* Set Functions */
    //setting vesting token address only once
    function setVestingTokens(address _vestingTokensAddress) external 
        onlyOwner period(STATE.PREPARE) {
            require(mVestingTokens == address(0)); //only once
            mVestingTokens = VestingTokens(_vestingTokensAddress);
    }
    function addWhitelist(address _whitelist, uint _maxcap) external onlyOwner{
        require(mCurrentState < STATE.FINISHED);
        mWhitelist[_whitelist].isListed = true;
        mWhitelist[_whitelist].maxcap = _maxcap;
    }
    //add developers, advisors, privateSale
    //check if it exceeds percentage

    /*
        We should consider to lower gas of below functions
        There are some duplicated check code
    */

    function setToDevelopers(address _address, uint _tokenWeiAmount) external 
        onlyOwner{
            require(_address != address(0));
            require(!_isEnrollmentDuplicated(_address, IMembers.MEMBER_LEVEL.DEV));
            uint lockedAmount = getLockedAmount(IVestingTokens.LOCK_TYPE.DEV).add(_tokenWeiAmount);
            require(lockedAmount <= mToken.totalSupply().div(1000).mul(DEV_TOKEN_PERC));
            // Solidity will roll back when it reverted
            // check already included
            if(mDevelopers[_address] > 0){
                mDevelopers[_address] = _tokenWeiAmount;
                if(_tokenWeiAmount == 0){   // if input == 0 => delete
                    members.delete_developer(_address);
                }
            } else{
                if(_tokenWeiAmount == 0){   // if input == 0 => revert
                    revert();
                }
                // add members
                mDevelopers[_address] = _tokenWeiAmount;
                mDevelopersIndex.push(_address);
                members.enroll_developer(_address);
            }
            
    }
    function setToAdvisors(address _address, uint _tokenWeiAmount) external 
        onlyOwner{
            require(_address != address(0));
            require(!_isEnrollmentDuplicated(_address, IMembers.MEMBER_LEVEL.ADV));
            uint lockedAmount = getLockedAmount(IVestingTokens.LOCK_TYPE.ADV).add(_tokenWeiAmount);
            require(lockedAmount <= mToken.totalSupply().div(1000).mul(ADV_TOKEN_PERC));
            // Solidity will roll back when it reverted
            // check already included
            if(mAdvisors[_address] > 0){
                mAdvisors[_address] = _tokenWeiAmount;
                if(_tokenWeiAmount == 0){   // if input == 0 => delete
                    members.delete_advisor(_address);
                }
            } else{
                if(_tokenWeiAmount == 0){   // if input == 0 => revert
                    revert();
                }
                // add members
                mAdvisors[_address] = _tokenWeiAmount;
                mAdvisorsIndex.push(_address);
                members.enroll_advisor(_address);
            }
            
    }
    function setToPrivateSale(address _address, uint _tokenWeiAmount) external 
        onlyOwner{
            require(_address != address(0));
            require(!_isEnrollmentDuplicated(_address, IMembers.MEMBER_LEVEL.PRIV));
            uint lockedAmount = getLockedAmount(IVestingTokens.LOCK_TYPE.PRIV).add(_tokenWeiAmount);
            require(lockedAmount <= mToken.totalSupply().div(1000).mul(PRIV_TOKEN_PERC));
            // Solidity will roll back when it reverted
            // check already included
            if(mPrivateSale[_address] > 0){
                mPrivateSale[_address] = _tokenWeiAmount;
                if(_tokenWeiAmount == 0){   // if input == 0 => delete
                    members.delete_privsale(_address);
                }
            } else{
                if(_tokenWeiAmount == 0){   // if input == 0 => revert
                    revert();
                }
                // add members
                mPrivateSale[_address] = _tokenWeiAmount;
                mPrivateSaleIndex.push(_address);
                members.enroll_privsale(_address);
            } 
    }
    function _isEnrollmentDuplicated(
        address _address,
        IMembers.MEMBER_LEVEL _level
        ) private
        returns(bool){
            IMembers.MEMBER_LEVEL level = members.getMemberLevel(_address);
            if(level == IMembers.MEMBER_LEVEL.NONE || level == _level){
                // left means trying update
                // right means trying enrollment first time
                return false;
            }
            if(level == IMembers.MEMBER_LEVEL.OWNER && _level == IMembers.MEMBER_LEVEL.DEV){
                return false;
            }
            return true;
    }



    /* Finalizing Functions */
    function _finish() private 
        period(STATE.ACTIVE){
            mCurrentState = STATE.FINISHED;
            emit StateChanged(STATE.FINISHED, now);
    }
    function _finalize() private {
            //lock up tokens
            require(isLockFilled());
            _lockup();
            //finalize funds
            //give initial fund
            _forwardFunds();
            mFund.finalizeSale();
            mFund.dividePoolAfterSale([PUB_TOKEN_PERC, INCENTIVE_TOKEN_PERC, RESERVE_TOKEN_PERC]);
            //Refund vote activate
            //set tapVoting available
            //change state
    }

    function _lockup() private {
            //lock tokens
            uint i = 0;
            for (i = 0; i < mDevelopersIndex.length; i++) {
                if(mDevelopers[mDevelopersIndex[i]] > 0){
                    mVestingTokens.lockup(
                        mDevelopersIndex[i],
                        mDevelopers[mDevelopersIndex[i]],
                        IVestingTokens.LOCK_TYPE.DEV
                    );
                    delete mDevelopers[mDevelopersIndex[i]];
                }
            }
            for (i = 0; i < mAdvisorsIndex.length; i++) {
                if(mAdvisors[mAdvisorsIndex[i]] > 0){
                    mVestingTokens.lockup(
                        mAdvisorsIndex[i],
                        mAdvisors[mAdvisorsIndex[i]],
                        IVestingTokens.LOCK_TYPE.ADV
                    );
                    delete mAdvisors[mAdvisorsIndex[i]];
                }
            }
            for (i = 0; i < mPrivateSaleIndex.length; i++) {
                if(mPrivateSale[mPrivateSaleIndex[i]] > 0 ){
                    mVestingTokens.lockup(
                        mPrivateSaleIndex[i],
                        mPrivateSale[mPrivateSaleIndex[i]],
                        IVestingTokens.LOCK_TYPE.PRIV
                    );
                    delete mPrivateSale[mPrivateSaleIndex[i]];
                }
            }
            //send Vesting tokens to VestingTokens.sol
            mToken.transfer(mVestingTokens, mToken.totalSupply().div(1000).mul(DEV_TOKEN_PERC + ADV_TOKEN_PERC + PRIV_TOKEN_PERC));
    }
    // send ether to the fund collection wallet
    // override to create custom fund forwarding mechanisms
    function _forwardFunds() private 
        returns (bool){
            address(mFund).transfer(address(this).balance); //send ether
            mToken.transfer(mFund, mToken.totalSupply().div(1000).mul(RESERVE_TOKEN_PERC+INCENTIVE_TOKEN_PERC)); //send tokens
            return true;
    }
}
