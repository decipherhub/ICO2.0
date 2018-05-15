const Crowdsale = artifacts.require("./Crowdsale.sol");

const CustomToken = artifacts.require("./CustomToken.sol");
const Fund = artifacts.require("./Fund.sol");
const Members = artifacts.require("./Members.sol");

const SafeMath = artifacts.require("./SafeMath.sol");
const Sqrt = artifacts.require("./Sqrt.sol");

module.exports = async function(deployer, network, accounts){
    deployer.deploy(Sqrt);
    deployer.deploy(SafeMath);
    
    deployer.link(Sqrt, Crowdsale);
    deployer.link(SafeMath, Crowdsale);

    const _token = await CustomToken.deployed();
    const _fund = await Fund.deployed();
    const _members = await Members.deployed();

    console.log("Deploying Crowdsale", _token.address, _fund.address, _members.address);

    deployer.deploy(Crowdsale,
        _token.address,
        _fund.address,
        _members.address,
        {from: accounts[0], gasLimit: 50000000});
}
