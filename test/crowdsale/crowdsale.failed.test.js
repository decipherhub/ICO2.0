import { increaseTimeTo, duration } from 'openzeppelin-solidity/test/helpers/increaseTime';
import { advanceBlock } from 'openzeppelin-solidity/test/helpers/advanceToBlock';

const CustomToken = artifacts.require("CustomToken");
const Crowdsale = artifacts.require("Crowdsale");
const Members = artifacts.require("Members");
const VestingTokens = artifacts.require("VestingTokens");

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
        await advanceBlock();

        let balance = await customToken.balanceOf(accounts[0]);
        customToken.transfer(instance.address, balance).should.be.fulfilled;
    });
    // 0 => owner
    // 0 ~ 3 => dev 14%
    // 4 => teamWallet
    // 10 ~ 59 => public 20%
    // 60 ~ 64 => advisors 5%
    // 65 ~ 84 => privsale 20%
    it("should list users", async () => {
        for(let i = 10; i < 59; i++){
            instance.addWhitelist(accounts[i], web3.toWei(300, 'ether'));
        }
    });
    it("shouldn't set before setting crowdsale to members", async () => {
        await instance.setToDevelopers(accounts[0], web3.toWei(1.5 * 1000**3, 'ether')).should.be.rejectedWith('revert');
        await members.setCrowdsale(instance.address).should.be.fulfilled;
        instance.setToDevelopers(accounts[0], web3.toWei(1.5 * 1000**3, 'ether')).should.be.fulfilled;
    });
    it("should add priv, adv, dev", async () => {// not yet fill all tokens
        for(let i = 1; i < 4; i++){ 
            instance.setToDevelopers(accounts[i], web3.toWei(3.5 * 1000**3, 'ether')).should.be.fulfilled;
        }
        instance.setToAdvisors(accounts[60], web3.toWei(0.5 * 1000*3, 'ether')).should.be.fulfilled;
        for(let i = 61; i < 65; i++){
            instance.setToAdvisors(accounts[i], web3.toWei(1000*3, 'ether')).should.be.fulfilled;
        }
        instance.setToPrivateSale(accounts[65], web3.toWei(0.5 * 1000*3, 'ether')).should.be.fulfilled;
        for(let i = 66; i < 85; i++){
            instance.setToPrivateSale(accounts[i], web3.toWei(1000*3, 'ether')).should.be.fulfilled;
        }
    });
    it("shouldn't duplicate enrollment", async () =>{
        await instance.setToDevelopers(accounts[62], web3.toWei(2 * 1000**3, 'ether')).should.be.rejectedWith('revert');
        instance.setToDevelopers(accounts[0], web3.toWei(2 * 1000**3, 'ether')).should.be.fulfilled;
        await instance.setToAdvisors(accounts[3], web3.toWei(0.5 * 1000**3, 'ether')).should.be.rejectedWith('revert');
        instance.setToAdvisors(accounts[60], web3.toWei(0.5 * 1000**3, 'ether')).should.be.fulfilled;
        await instance.setToPrivateSale(accounts[63], web3.toWei(0.5 * 1000**3, 'ether')).should.be.rejectedWith('revert');
        instance.setToPrivateSale(accounts[65], web3.toWei(0.5 * 1000**3, 'ether')).should.be.fulfilled;
    });
    it("should be activated", async () =>{
        await instance.setVestingTokens(vestingTokens.address).should.be.fulfilled;
        await instance.activateSale().should.be.fulfilled;
        increaseTimeTo(START_TIME);
    });

    
    // We have to seperate discount case
    it("should receive 100*49 ether", async () => {
        for(let i= 10; i < 59; i++){
            instance.sendTransaction({from : accounts[i], value : web3.toWei(100, 'ether')}).should.be.fulfilled;
        }
        await advanceBlock();
        // for(let i= 10; i < 59; i++){
        //     let balance = await instance.getContributors.call(accounts[i])
        //     assert.equal(balance.toNumber(),
        //                 web3.toWei(100,'ether')*rate,
        //                 balance.toNumber() +"is not equal to"+web3.toWei(100,'ether')*rate);
        // }
        // good, but too much time
        let balance = (await web3.eth.getBalance(instance.address)).toNumber();
        console.log(balance, instance.address)
        assert.equal(balance, web3.toWei(100*49, 'ether'),balance +'and'+ web3.toWei(100*49, 'ether'));
    });
    it("shouldn't receive ether after end time", async () => {
        await increaseTimeTo(END_TIME);
        instance.sendTransaction({from : accounts[13], value : web3.toWei(100, 'ether')}).should.be.rejectedWith('revert');
        instance.buyTokens(accounts[10], {from : accounts[10], value : web3.toWei(100, 'ether')}).should.be.rejectedWith('revert');
    });
    it("shouldn't active any functions after end time and not over soft cap", async () => {
        instance.activateSale().should.be.rejectedWith('revert');
        instance.finalizeSale().should.be.rejectedWith('revert');
        instance.finishSale().should.be.rejectedWith('revert');
        instance.receiveTokens().should.be.rejectedWith('revert');
        instance.refund().should.be.rejectedWith('revert');
    });
    it("should be changed to REFUND", async () =>{
        await instance.activeRefund({from : accounts[13]}).should.be.fulfilled;
        let state = await instance.getCurrentSate.call();
        assert.equal(state, 4, "state isn't REFUND");
    });
    it("shouldn't active any functions after refund", async () =>{
        instance.activateSale().should.be.rejectedWith('revert');
        instance.finalizeSale().should.be.rejectedWith('revert');
        instance.finishSale().should.be.rejectedWith('revert');
        instance.receiveTokens().should.be.rejectedWith('revert');
        instance.activeRefund().should.be.rejectedWith('revert');
        instance.sendTransaction({from : accounts[13], value : web3.toWei(100, 'ether')}).should.be.rejectedWith('revert');
        instance.buyTokens(accounts[10], {from : accounts[10], value : web3.toWei(100, 'ether')}).should.be.rejectedWith('revert');
    });
    it("should give refund ethers to only contributors once", async () => {
        await (async () => {
            for(let i = 10; i < 59; i++){
                instance.refund({from : accounts[i]}).should.be.fulfilled;
            }
            instance.refund({from : accounts[59]}).should.be.rejectedWith('revert');
        })();
        await instance.refund({from : accounts[10]}).should.be.rejectedWith('revert');
        await advanceBlock();
        let balance = (await web3.eth.getBalance(instance.address)).toNumber();
        assert.equal(balance, 0, balance +'and'+ 0);
    });
});