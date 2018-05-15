pragma solidity ^0.4.23;

import "../lib/SafeMath.sol";
import "../lib/Param.sol";
import "./IERC20.sol";
import "./ILockedTokens.sol";
import "../fund/Fund.sol";


/**
 * @title LockedTokens
 * @dev Lock tokens for certain period of time
 */
contract LockedTokens is ILockedTokens, Param {
    using SafeMath for uint256;
    struct Tokens {
        uint256 amount;
        uint256 lockEndTime;
        bool released;
    }

    IERC20 mToken;
    address mCrowdsaleAddress;
    Fund mFund;
    mapping(address => Tokens[]) public mWalletTokens;
    bool workable = true;


    modifier available {
        require(workable);
        _;
    }
    /**
     * @dev LockedTokens constructor
     * @param _token ERC20 compatible token contract
     * @param _fundAddress Fund contract address
     */
    constructor(
        address _token,
        address _fundAddress) public {
            require(_token != 0x0);
            require(_fundAddress != 0x0);

            mToken = IERC20(_token);
            mFund = Fund(_fundAddress);
            workable = true;
    }

    function setCrowdsaleAddress(address _crowdsaleAddress) public
        returns(bool) {
            require(mCrowdsaleAddress == 0x0);
            mCrowdsaleAddress = _crowdsaleAddress;
            return true;
        }

    /**
     * @dev Functions locks tokens
     * @param _to Wallet address to transfer tokens after _lockEndTime
     * @param _amount Amount of tokens to lock
     * @param _lockEndTime End of lock period
     */
    function addTokens(
        address _to,
        uint256 _amount,
        uint256 _lockEndTime) internal
        returns(bool) {
            require(msg.sender == mCrowdsaleAddress);

            mWalletTokens[_to].push(Tokens({amount: _amount, lockEndTime: _lockEndTime, released: false}));
            emit TokensLocked(_to, _amount, _lockEndTime);
            return true;
    }

    /**
     * @dev Called by owner of locked tokens to release them
     */
    function releaseTokens() external
        available
        returns(bool) {
            require(mWalletTokens[msg.sender].length > 0);

            for(uint256 i = 0; i < mWalletTokens[msg.sender].length; i++) {
                if(!mWalletTokens[msg.sender][i].released && now >= mWalletTokens[msg.sender][i].lockEndTime) {
                    mWalletTokens[msg.sender][i].released = true;
                    mToken.transfer(msg.sender, mWalletTokens[msg.sender][i].amount);
                    emit TokensUnlocked(msg.sender, mWalletTokens[msg.sender][i].amount);
                }
            }
            return true;
    }

    function lock() public
        available
        returns(bool) {
            require(msg.sender == address(mFund));

            workable = false;
            return true;
    }
}
