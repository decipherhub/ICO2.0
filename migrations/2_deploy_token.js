const CustomToken = artifacts.require("./CustomToken.sol");

const SafeMath = artifacts.require("./SafeMath.sol");
const Sqrt = artifacts.require("./Sqrt.sol");

module.exports = async function(deployer, network, accounts) {
    deployer.deploy(Sqrt);
    deployer.deploy(SafeMath);

    deployer.link(Sqrt, CustomToken);
    deployer.link(SafeMath, CustomToken);
    
    console.log("Deploying Token", accounts[0]);

    deployer.deploy(CustomToken, {from: accounts[0], gasLimit: 5000000});
};
