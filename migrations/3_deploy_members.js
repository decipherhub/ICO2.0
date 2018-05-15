const Members = artifacts.require("./Members.sol");

module.exports = async function(deployer, network, accounts) {
    console.log("Deploying Members", accounts[0]);
    deployer.deploy(Members, {from: accounts[0], gasLimit : 5000000});
};
