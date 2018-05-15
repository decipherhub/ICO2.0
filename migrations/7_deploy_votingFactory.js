const VotingFactory = artifacts.require("./VotingFactory.sol");

const CustomToken = artifacts.require("./CustomToken.sol");
const Fund = artifacts.require("./Fund.sol");
const Members = artifacts.require("./Members.sol");
const VestingTokens = artifacts.require("./VestingTokens.sol");

const SafeMath = artifacts.require("./SafeMath.sol");
const Sqrt = artifacts.require("./Sqrt.sol");

module.exports = async function(deployer, network, accounts){
    deployer.deploy(Sqrt);
    deployer.deploy(SafeMath);

    deployer.link(Sqrt, VotingFactory);
    deployer.link(SafeMath, VotingFactory);

    const _token = await CustomToken.deployed();
    const _fund = await Fund.deployed();
    const _vestingTokens = await VestingTokens.deployed();
    const _members = await Members.deployed();
    
    console.log("Deploying VotingFactory", _token.address, _fund.address, _vestingTokens.address, _members.address);
    
    deployer.deploy(VotingFactory,
        _token.address,
        _fund.address,
        _vestingTokens.address,
        _members.address,
        {from: accounts[0], gasLimit: 5000000});
}