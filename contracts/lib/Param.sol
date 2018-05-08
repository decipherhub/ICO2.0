/* All constants used in other contracts are defined here.
*/
pragma solidity ^0.4.23;
import "../lib/SafeMath.sol";
import "../lib/Sqrt.sol";

contract Param {
    using SafeMath for uint256;
    using Sqrt for uint256;
    /* Token */
    uint8 public constant DECIMALS = 18;
    uint public constant INITIAL_SUPPLY = 100 * (1000 ** 3) * (10 ** uint256(DECIMALS));
    string public constant TOKEN_NAME = "CUSTOM";
    string public constant TOKEN_SYMBOL = "CTM";

    /* Crowdsale */

    uint public constant HARD_CAP = 37500 ether;
    uint public constant SOFT_CAP = 5000 ether;
    uint public constant MIN_CONTRIB = 5000 ether;

        //percentage of tokens total : 1000%
    uint public constant PUB_TOKEN_PERC = 200;
    uint public constant PRIV_TOKEN_PERC = 200;
    uint public constant DEV_TOKEN_PERC = 140;
    uint public constant ADV_TOKEN_PERC = 50;
    uint public constant RESERVE_TOKEN_PERC = 200;
    uint public constant REWARD_TOKEN_PERC = 200;
    uint public constant INCENTIVE_TOKEN_PERC = 10;

        //limitation of public participants
    uint public constant ETHER_MIN_CONTRIB = 1 ether;
    uint public constant ETHER_MAX_CONTRIB = 300 ether;

        //crowd sale time
    uint public constant SALE_START_TIME = 0;
    uint public constant SALE_END_TIME = 0;

        // how many token units a buyer gets per wei
    uint public constant DEFAULT_RATE = 50*10**5; //this is ether/token or wei/tokenWei

    /* Fund */


    uint public constant INITIAL_TAP = 0.01 ether; //(0.01 ether/sec)
    uint public constant DEV_VESTING_PERIOD = 1 years;

    /* Pool */


    uint256 public constant MIN_RECEIVABLE_TOKEN = 100; // minimum token holdings
        // HARD_CAP // derived from Crowdsale

    /* Voting */


    uint256 public constant MIN_TERM = 7 days; // possible term of minimum tap voting
    uint256 public constant MAX_TERM = 2 weeks; // possible term of maximum tap voting
    uint256 public constant DEV_POWER = 700; // voting weight of developers (max: 1000%)
        // DEV_TOKEN_PERC // derived from Crowdsale
    uint256 public constant PUBLIC_TOKEN_PERC = 65; //FIXIT: it should be changed in every tap voting term and it is NOT constant, it means totalSupply() - locked_token - reserve_token
    uint256 public constant REFRESH_TERM = 4 weeks; // refresh term of refund voting
    uint256 public constant MIN_VOTABLE_TOKEN_PER = 1; // 0.01% (max: 10000)
        //IMPORTANT: need reviewing
    function MIN_VOTE_PERCENT(
        uint256 P_S,
        uint256 p_M,
        uint256 p_m,
        uint256 N_M,
        uint256 N_m) internal pure
        returns(uint256 X) {
            //TODO: X ~ N(m, variance) => X-m/std ~ N(0, 1)
            uint256 UINT_100 = 100;
            uint256 m = (P_S.mul(p_M).add((UINT_100.sub(P_S)).mul(p_m))).div(10000); 
            uint256 variance = P_S.mul(P_S).mul(p_M).mul(UINT_100.sub(p_M)).div(N_M);
            variance = variance.add((UINT_100.sub(P_S)).mul(UINT_100.sub(P_S)).mul(p_m).mul(UINT_100.sub(p_m)).div(N_m));
            uint256 std = variance.div(100000000).sqrt();
            //If you wanna the voting rate 80%, P(Z>= -0.842) = 0.8
            X = m.sub(std.mul(842).div(1000));
            return X;
    }
}
