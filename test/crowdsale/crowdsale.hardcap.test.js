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
});