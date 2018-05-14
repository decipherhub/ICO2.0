const CustomToken = artifacts.require("./CustomToken.sol");
const SafeMath = artifacts.require("./SafeMath.sol");

module.exports = async function(deployer, network, accounts) {
    console.log("Deploying Token", accounts[0]);
    deployer.deploy(SafeMath);
    deployer.link(SafeMath, CustomToken);
    deployer.deploy(CustomToken, {from: accounts[0], gasLimit: 5000000});
};
