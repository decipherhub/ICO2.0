import { increaseTimeTo, duration } from 'openzeppelin-solidity/test/helpers/increaseTime';
import { advanceBlock } from 'openzeppelin-solidity/test/helpers/advanceToBlock';

const CustomToken = artifacts.require("CustomToken");

const BigNumber = web3.BigNumber;

require('chai')
  .use(require('chai-as-promised'))
  .use(require('chai-bignumber')(BigNumber))
  .should();

contract("CustomToken", function(accounts){
    let instance;
    before(async () => {
        instance = await CustomToken.deployed();
    })

    it("should value is totalSupply", async () => {
        let initialBalance = await instance.balanceOf(accounts[0]);
        let totalSupply = await instance.totalSupply.call();

        console.log(initialBalance.toNumber(), totalSupply.toNumber());
        assert.equal(initialBalance.toNumber(), totalSupply.toNumber(), "initial == totalSupply");
        
    });
    it("should send correctly", async () => {
        let instance = await CustomToken.deployed();
        await instance.transfer(accounts[2], web3.toWei(100, 'ether'), {from : accounts[0]});
        await instance.transfer(accounts[2], web3.toWei(100, 'ether'), {from : accounts[0]});
        await instance.transfer(accounts[2], web3.toWei(100, 'ether'), {from : accounts[0]});
        let decimals = await instance.decimals.call();
        console.log("decimals : " + decimals);

        let balance0 = await instance.balanceOf(accounts[0]);
        let balance2 = await instance.balanceOf(accounts[2]);
        console.log(balance0.toNumber()/(10 ** decimals), balance2.toNumber()/(10 ** decimals));
    });
})