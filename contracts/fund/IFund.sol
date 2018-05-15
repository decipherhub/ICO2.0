pragma solidity ^0.4.23;

contract IFund {

    enum FUNDSTATE {
        BEFORE_SALE,
        CROWDSALE,
        WORKING,
        LOCKED,
        COLLAPSED
    }

    function publicSupply() public view returns(uint256);
    function getWithdrawable() view public returns(uint256);
    function getLocked() view public returns(bool);
    function setIncentivePoolAddress(address _addr) external returns(bool); 
    function setReservePoolAddress(address _addr) external returns(bool);
    function setVotingFactoryAddress(address _votingfacaddr) external returns(bool);
    function setVestingTokensAddress(address _vestingTokensAddr) external returns(bool);
    function startSale() public;
    function finalizeSale() public;
    function lockFund() public returns(bool);
    function changeTap(uint _tap) public returns(bool);
    function dividePoolAfterSale(uint256[3] asset_percent) public;
    function withdrawTap() public payable returns(bool);
    function refund() external returns(bool);
    function dead() external returns(bool);

    /* Events */
    
    // event SetIncentivePoolAddress(address indexed inc_pool_addr, address indexed setter);
    // event SetReservePoolAddress(address indexed res_pool_addr, address indexed setter);
    // event SetVotingFactoryAddress(address indexed voting_factory_addr, address indexed setter);
    // event SetCrowdsaleAddress(address indexed crowdsale_addr, address indexed setter);
    // event SetVestingTokensAddress(address indexed vesting_tokens_addr, address indexed setter);
    //
    event ChangeFundState(uint256 indexed time, FUNDSTATE indexed changed_state);
    event ChangeTap(uint256 indexed time, uint256 indexed changed_tap);
    event DividePoolAfterSale(address indexed inc_addr, address indexed res_addr);
    event WithdrawTap(uint256 indexed time, address indexed _teamwallet);
    event WithdrawFromIncentive(uint256 indexed time, address indexed _caller);
    event WithdrawFromReserve(uint256 indexed time, address indexed _teamwallet);
    event Refund(uint256 indexed time, address indexed refund_addr, uint256 indexed wei_amount);
    //add more
}
