import { increaseTimeTo, duration } from 'openzeppelin-solidity/test/helpers/increaseTime';
import { advanceBlock } from 'openzeppelin-solidity/test/helpers/advanceToBlock';

const CustomToken = artifacts.require("CustomToken");
const Crowdsale = artifacts.require("Crowdsale");
const VestingTokens = artifacts.require("VestingTokens");
const Fund = artifacts.require("Fund");
const Members = artifacts.require("Members");

const BigNumber = web3.BigNumber;

require('chai')
    .use(require('chai-as-promised'))
    .use(require('chai-bignumber')(BigNumber))
    .should();

contract("Crowdsale", function(accounts){
    let instance;
    let token;
    let members;
    let fund;

    let totalSupply;
    let decimals;
    let HARD_CAP;
    let SOFT_CAP;
    let SALE_START_TIME;
    let SALE_END_TIME;
    let owner;
    before(async () => {
        await advanceBlock();

        instance = await Crowdsale.deployed();
        token = await CustomToken.deployed();
        members = await Members.deployed();
        fund = await Fund.deployed();
        fund.setCrowdsaleAddress(instance.address).should.be.fulfilled;
        members.enroll_developer(accounts[1], {from : accounts[0]}).should.be.fulfilled; //developer_1
        members.enroll_developer(accounts[2], {from : accounts[0]}).should.be.fulfilled; //developer_2
        members.enroll_developer(accounts[3], {from : accounts[0]}).should.be.fulfilled; //developer_3

        totalSupply = await token.totalSupply.call();
        decimals = await token.decimals.call();
        HARD_CAP = await instance.getFundingGoal.call();
        SOFT_CAP = web3.toWei(5000, "ether");
        SALE_START_TIME = await instance.getStartTime.call();
        SALE_END_TIME = await instance.getEndTime.call();
    });
    it("shouldn't active when its balance is not totalSupply", async () => {
        await token.transfer(instance.address, 10);
        let balance = await token.balanceOf(instance.address);
        console.log(balance.toNumber()/(10 ** decimals))
        await instance.activateSale().should.be.rejectedWith('revert');
        let leftBalance = await token.balanceOf(accounts[0]);
        await token.transfer(instance.address, leftBalance);
        let instanceBalance = await token.balanceOf(instance.address);
        console.log(instanceBalance.toNumber(), totalSupply.toNumber());
        assert.equal(instanceBalance.toNumber(), totalSupply.toNumber());
    });
    it("should have same owner with deployer", async () => {
        let isOwner = await instance.isOwner(accounts[0]);
        assert.equal(isOwner, true, "not same owner");
    });
    it("shouldn't receive ether when preparing process", async () =>{
        instance.send(web3.toWei(10, 'ether')).should.be.rejectedWith('revert');
        instance.buyTokens(accounts[0], {from : accounts[0], value : web3.toWei(10, 'ether')}).should.be.rejectedWith('revert');
    });
    it("shouldn't active onlyOwner function", async () => {
        instance.activateSale({from : accounts[1]}).should.be.rejectedWith('revert');
        instance.finishSale({from : accounts[1]}).should.be.rejectedWith('revert');
        instance.finalizeSale({from : accounts[1]}).should.be.rejectedWith('revert');
        instance.setVestingTokens(accounts[2], {from : accounts[1]}).should.be.rejectedWith('revert');
        instance.setToDevelopers(accounts[2], 1000, {from : accounts[1]}).should.be.rejectedWith('revert');
        instance.setToAdvisors(accounts[2], 1000, {from : accounts[1]}).should.be.rejectedWith('revert');
        instance.setToPrivateSale(accounts[2], 1000, {from : accounts[1]}).should.be.rejectedWith('revert');
    });
    it("should add whitelist", async () =>{
        //just accounts[0] and accounts[2]
        instance.addWhitelist(accounts[0], web3.toWei(10, 'ether')).should.be.fulfilled;
        instance.addWhitelist(accounts[2], web3.toWei(5, 'ether')).should.be.fulfilled;
    });
    it("should active after setting", async () => {
        let state = await instance.getCurrentSate.call();
        assert.equal(state, 0, "state isn't PREPARE");

        await instance.activateSale().should.be.rejectedWith('revert');
        await instance.setVestingTokens(VestingTokens.address).should.be.fulfilled;
        console.log(VestingTokens.address, 'ye-ah');
        await instance.activateSale().should.be.fulfilled;;
        state = await instance.getCurrentSate.call();
        assert.equal(state, 1, "state isn't ACTIVE");
    });
    it("shouldn't active other processes before start time even if state is ACTIVE", async () => {
        instance.activateSale().should.be.rejectedWith('revert'); //not call twice

        instance.finishSale().should.be.rejectedWith('revert');
        instance.send(web3.toWei(10, 'ether')).should.be.rejectedWith('revert');
        instance.buyTokens(accounts[0], {from : accounts[0], value : web3.toWei(10, 'ether')}).should.be.rejectedWith('revert');
        instance.activeRefund().should.be.rejectedWith('revert');
        instance.finalizeSale().should.be.rejectedWith('revert');
        instance.receiveTokens().should.be.rejectedWith('revert');
        instance.refund().should.be.rejectedWith('revert');
    });
    it("should receive ethers of listed people after start time", async () =>{
        await increaseTimeTo(SALE_START_TIME);
        await instance.sendTransaction({from : accounts[2], value : web3.toWei(1, 'ether')}).should.be.fulfilled;
        instance.buyTokens(accounts[0], {from : accounts[2], value : web3.toWei(1, 'ether')}).should.be.fulfilled;
        instance.sendTransaction({from : accounts[4], value : web3.toWei(1, 'ether')}).should.be.rejectedWith('revert');
        instance.sendTransaction({from : accounts[2], value : web3.toWei(10, 'ether')}).should.be.rejectedWith('revert');

        let tokenBalance0 = (await instance.mContributors.call(accounts[0]))[1];
        let tokenBalance2 = (await instance.mContributors.call(accounts[2]))[1];
        console.log(tokenBalance0.toNumber()/10**decimals, tokenBalance2.toNumber()/10**decimals);
    });
    it("shouldn't active other processes before sale finished", async () =>{
        instance.activateSale().should.be.rejectedWith('revert');
        instance.activeRefund().should.be.rejectedWith('revert');
        instance.finalizeSale().should.be.rejectedWith('revert');
        instance.finishSale().should.be.rejectedWith('revert');
        instance.receiveTokens().should.be.rejectedWith('revert');
        instance.refund().should.be.rejectedWith('revert');
    });
    
});

