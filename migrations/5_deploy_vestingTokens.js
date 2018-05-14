const VestingTokens = artifacts.require("./VestingTokens.sol");
const SafeMath = artifacts.require("./SafeMath.sol");
const Fund = artifacts.require("./Fund.sol");
const CustomToken = artifacts.require("./CustomToken.sol");

module.exports = async function(deployer, network, accounts) {
    const _token = await CustomToken.deployed();
    const _fund = await Fund.deployed();

    deployer.link(SafeMath, VestingTokens);
    deployer.deploy(VestingTokens, _token.address, _fund.address, {from: accounts[0], gasLimit: 50000000});
};
