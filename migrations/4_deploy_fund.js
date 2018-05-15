const Fund = artifacts.require("./Fund.sol");

const CustomToken = artifacts.require("./CustomToken.sol");
const Members = artifacts.require("./Members.sol");

const SafeMath = artifacts.require("./SafeMath.sol");
const Sqrt = artifacts.require("./Sqrt.sol");

module.exports = async function(deployer, network, accounts) {
    deployer.deploy(Sqrt);
    deployer.deploy(SafeMath);

    deployer.link(Sqrt, Fund);
    deployer.link(SafeMath, Fund);

    const _token = await CustomToken.deployed();
    const _teamWallet = accounts[4];
    const _members = await Members.deployed();
    
    console.log("Deploying Fund", _token.address, _teamWallet, _members.address);

    deployer.deploy(Fund,
        _token.address,
        _teamWallet,
        _members.address,
        {from: accounts[0], gasLimit: 50000000});
};
