pragma solidity ^0.4.23;

import "../lib/SafeMath.sol";

library Sqrt {
    using SafeMath for uint256;

    function sqrt(uint256 x) internal pure
        returns (uint256 y) {
            uint256 z = x.add(1).div(2);
            y = x;
            while (z < y) {
                y = z;
                z = ((x.div(z)).add(z)).div(2);
            }
            return y;
    }
}
