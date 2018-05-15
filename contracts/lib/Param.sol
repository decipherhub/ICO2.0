/* All constants used in other contracts are defined here.
*/
pragma solidity ^0.4.23;
import "../lib/SafeMath.sol";
import "../lib/Sqrt.sol";

library Param {
    using SafeMath for uint256;
    using Sqrt for uint256;
    /* Token */
    uint8 constant DECIMALS = 18;
    uint constant INITIAL_SUPPLY = 100 * (1000 ** 3) * (10 ** uint256(DECIMALS));
    string constant TOKEN_NAME = "Decipher";
    string constant TOKEN_SYMBOL = "DEC";

    /* Crowdsale */

    uint constant HARD_CAP = 37500 ether;
    uint constant SOFT_CAP = 5000 ether;

        //percentage of tokens total : 1000%
    uint constant PUB_TOKEN_PERC = 200;
    uint constant PRIV_TOKEN_PERC = 200;
    uint constant DEV_TOKEN_PERC = 140;
    uint constant ADV_TOKEN_PERC = 50;
    uint constant RESERVE_TOKEN_PERC = 400;
    uint constant INCENTIVE_TOKEN_PERC = 10;

        //crowd sale time
    uint constant SALE_START_TIME = 1526169600000; // 5/13 00:00:00
    uint constant SALE_END_TIME = 1527119999000; // 5/23 23:59:59

        // how many token units a buyer gets per wei
    uint constant DEFAULT_RATE = 50*10**5; //this is ether/token or wei/tokenWei

    /* Fund */


    uint constant INITIAL_TAP = 0.01 ether; //(0.01 ether/sec)
    uint constant DEV_VESTING_PERIOD = 1 years;

    /* Pool */


    uint256 constant MIN_RECEIVABLE_TOKEN = 100; // minimum token holdings
        // HARD_CAP // derived from Crowdsale

    /* Voting */


    uint256 constant MIN_TERM = 7 days; // possible term of minimum tap voting
    uint256 constant MAX_TERM = 2 weeks; // possible term of maximum tap voting
    uint256 constant DEV_POWER = 700; // voting weight of developers (max: 1000%)
        // DEV_TOKEN_PERC // derived from Crowdsale
    uint256 constant PUBLIC_TOKEN_PERC = 65; //FIXIT: it should be changed in every tap voting term and it is NOT constant, it means totalSupply() - locked_token - reserve_token
    uint256 constant REFRESH_TERM = 4 weeks; // refresh term of refund voting
    uint256 constant MIN_VOTABLE_TOKEN_PER = 1; // 0.01% (max: 10000)
        //IMPORTANT: need reviewing
        function MIN_VOTE_PERCENT(
            uint256 P_S,
            uint256 p_M,
            uint256 p_m,
            uint256 N_M,
            uint256 N_m) internal pure
            returns(uint256 X) {
                //TODO: X ~ N(m, variance) => X-m/std ~ N(0, 1)
                /*uint256 m = (P_S.mul(p_M).add((uint256(100).sub(P_S)).mul(p_m))).div(uint256(10000));
                uint256 variance = P_S.mul(P_S).mul(p_M).mul(uint256(100).sub(p_M)).div(N_M);
                variance = variance.add( (uint256(100).sub(P_S)).mul(uint256(100).sub(P_S)).mul(p_m).mul(uint256(100).sub(p_m)).div(N_m) );
                uint256 std = Sqrt.sqrt(variance.div(uint256(100000000)));
                //If you wanna the voting rate 80%, P(Z>= -0.842) = 0.8
                X = m.sub(std.mul(842).div(1000));*/
                return X;
        }
}
