const CustomToken = artifacts.require("./CustomToken.sol");
const Crowdsale = artifacts.require("./Crowdsale.sol");
const Members = artifacts.require("./Members.sol");
const SafeMath = artifacts.require("./SafeMath.sol");

const Fund = artifacts.require("./Fund.sol");

module.exports = async function(deployer, network, accounts) {

    deployer.link(SafeMath, Fund);
    //deployer.deploy(Fund, token, teamWallet, membersAddress, {from: accounts[0], gasLimit: 50000000});
    const _token = await CustomToken.deployed();
    const _teamWallet = await accounts[4];
    const _members = await Members.deployed();
    console.log("Deploying Fund", _token.address, _teamWallet, _members.address);

    deployer.deploy(Fund,
        _token.address,
        _teamWallet,
        _members.address,
        {from: accounts[0], gasLimit: 7000000});
};
