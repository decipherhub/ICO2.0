const Members = artifacts.require("./Members.sol");

module.exports = async function(deployer, network, accounts) {
    await deployer.deploy(Members, {from: accounts[0], gasLimit : 50000000});    

    const members = await Members.deployed();
    try{
        members.enroll_developer(accounts[1], {from : accounts[0]}); //developer_1
        members.enroll_developer(accounts[2], {from : accounts[0]}); //developer_2
        members.enroll_developer(accounts[3], {from : accounts[0]}); //developer_3
    } catch(e){
        console.log("Error : " + e);
    }
};
