import { increaseTimeTo, duration } from 'openzeppelin-solidity/test/helpers/increaseTime';
import { advanceBlock } from 'openzeppelin-solidity/test/helpers/advanceToBlock';

const CustomToken = artifacts.require("CustomToken");
const Crowdsale = artifacts.require("Crowdsale");

const BigNumber = web3.BigNumber;

require('chai')
    .use(require('chai-as-promised'))
    .use(require('chai-bignumber')(BigNumber))
    .should();

contract("Crowdsale", function(accounts){
    let instance;
    let token;
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
        totalSupply = await token.totalSupply.call();
        decimals = await token.decimals.call();
        HARD_CAP = await instance.HARD_CAP.call();
        SOFT_CAP = await instance.SOFT_CAP.call();
        SALE_START_TIME = await instance.SALE_START_TIME.call();
        SALE_END_TIME = await instance.SALE_END_TIME.call();
        await advanceBlock();

        let balance = await token.balanceOf(accounts[0]);
        token.transfer(instance.address, balance).should.be.fulfilled;
    })
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
    it("should add priv, adv, dev", async () => {
        for(let i = 0; i < 4; i++){
            instance.setToDevelopers(accounts[i], web3.toWei(3.5 * 1000**3, 'ether')).should.be.fulfilled;
        }
        for(let i = 60; i < 65; i++){
            instance.setToAdvisors(accounts[i], web3.toWei(1000*3, 'ether')).should.be.fulfilled;
        }
        for(let i = 65; i < 85; i++){
            instance.setToPrivateSale(accounts[i], web3.toWei(1000*3, 'ether')).should.be.fulfilled;
        }
    });
    it("should be activated", async () =>{
        await instance.activeSale();
        increaseTimeTo(START_TIME);
    });
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
        instance.activeSale().should.be.rejectedWith('revert');
        instance.finalizeSale().should.be.rejectedWith('revert');
        instance.finishSale().should.be.rejectedWith('revert');
        instance.receiveTokens().should.be.rejectedWith('revert');
        instance.refund().should.be.rejectedWith('revert');
    });
    it("should be changed to REFUND", async () =>{
        await instance.activeRefund({from : accounts[13]}).should.be.fulfilled;
        let state = await instance.getCurrentSate.call();
        assert.equal(state, "REFUND", "state isn't REFUND");
    });
    it("shouldn't active any functions after refund", async () =>{
        instance.activeSale().should.be.rejectedWith('revert');
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