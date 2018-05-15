const VestingTokens = artifacts.require("./VestingTokens.sol");

const Fund = artifacts.require("./Fund.sol");
const CustomToken = artifacts.require("./CustomToken.sol");

const SafeMath = artifacts.require("./SafeMath.sol");
const Sqrt = artifacts.require("./Sqrt.sol");

module.exports = async function(deployer, network, accounts) {
    deployer.deploy(Sqrt);
    deployer.deploy(SafeMath);

    deployer.link(Sqrt, VestingTokens);
    deployer.link(SafeMath, VestingTokens);

    const _token = await CustomToken.deployed();
    const _fund = await Fund.deployed();
    
    console.log("Deploying VestingTokens", _token.address, _fund.address);

    deployer.deploy(VestingTokens,
        _token.address,
        _fund.address,
        {from: accounts[0], gasLimit: 5000000});
};
