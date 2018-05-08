const Members = artifacts.require("./Members.sol");

module.exports = async function(deployer, network, accounts) {
    deployer.deploy(Members, {from: accounts[0], gasLimit: 50000000})
    .then((Members) => {

        Members.enroll_developer(accounts[1], {from:accounts[0]}); //developer_1
        Members.enroll_developer(accounts[2], {from:accounts[0]}); //developer_2
        Members.enroll_developer(accounts[3], {from:accounts[0]}); //developer_3

    });

    // const members = await Members.deployed();

};
