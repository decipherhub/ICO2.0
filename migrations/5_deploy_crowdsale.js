const Crowdsale = artifacts.require("./Crowdsale.sol");
const SafeMath = artifacts.require("./SafeMath.sol");
const JChoyToken = artifacts.require("./JChoyToken.sol");
const Fund = artifacts.require("./Fund.sol");
const Members = artifacts.require("./Members.sol");

module.exports = async function(deployer, network, accounts){
    deployer.deploy(SafeMath);
    deployer.link(SafeMath, Crowdsale);

    const _token = await JChoyToken.deployed();
    const _fund = await Fund.deployed();
    const _members = await Members.deployed();
    deployer.deploy(Crowdsale, _token.address, _fund.address, _members.address, {from: accounts[0], gasLimit: 50000000});
}