const Crowdsale = artifacts.require("./Crowdsale.sol");
const SafeMath = artifacts.require("./SafeMath.sol");
const CustomToken = artifacts.require("./CustomToken.sol");
const Fund = artifacts.require("./Fund.sol");
const Members = artifacts.require("./Members.sol");

module.exports = async function(deployer, network, accounts){
    deployer.link(SafeMath, Crowdsale);

    const _token = await CustomToken.deployed();
    const _fund = await Fund.deployed();
    const _members = await Members.deployed();

    deployer.deploy(Crowdsale,
        _token.address,
        _fund.address,
        _members.address,
        {from: accounts[0], gasLimit: 50000000});
}
