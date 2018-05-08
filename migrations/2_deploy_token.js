const ERC20 = artifacts.require("./ERC20.sol");
const IERC20 = artifacts.require("./IERC20.sol");
const VestingTokens = artifacts.require("./VestingTokens.sol");
const SafeMath = artifacts.require("./SafeMath.sol");
const Ownable = artifacts.require("./Ownable.sol");

module.exports = function(deployer, network, accounts) {
    console.log(accounts[0]);
    deployer.deploy(SafeMath);
    deployer.link(SafeMath, ERC20);
    //deployer.deploy(ERC20, 50000000, 18, "DECIPHER DAICO TOKEN", "DDT", {from: accounts[0], gasLimit: 50000000});
    deployer.deploy(ERC20, {from: accounts[0], gasLimit: 50000000});
};
