const Crowdsale = artifacts.require("./Crowdsale.sol");
const SafeMath = artifacts.require("./SafeMath.sol");
const CustomToken = artifacts.require("./CustomToken.sol");
const Fund = artifacts.require("./Fund.sol");
const Members = artifacts.require("./Members.sol");

module.exports = async function(deployer, network, accounts){
    deployer.deploy(SafeMath);
    deployer.link(SafeMath, Crowdsale);

    const _token = await CustomToken.deployed();
    // const _fund = await Fund.deployed();
    const _members = await Members.deployed();
    console.log("Deploying Crowdsale", _token.address, accounts[5], _members.address);

    deployer.deploy(Crowdsale,
        _token.address,
        // _fund.address,
        accounts[5],
        _members.address,
        {from: accounts[0], gasLimit: 5000000});
}