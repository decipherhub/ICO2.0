import { increaseTimeTo, duration } from 'openzeppelin-solidity/test/helpers/increaseTime';
import { advanceBlock } from 'openzeppelin-solidity/test/helpers/advanceToBlock';

const CustomToken = artifacts.require("CustomToken");

const BigNumber = web3.BigNumber;

require('chai')
    .use(require('chai-as-promised'))
    .use(require('chai-bignumber')(BigNumber))
    .should();

/**
 * below test code is modification of https://www.pubnub.com/blog/testing-and-deploying-an-ethereum-token-part-2/
 */


contract("CustomToken", function(accounts){
    let instance;
    before(async () => {
        instance = await CustomToken.deployed();
    })

    it('should pass if contract is deployed', async function() {
        let name = await instance.name.call();
        assert.strictEqual(name, 'Decipher');
    });
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
    it('should [approve] token for [transferFrom]', async function() {
        let approver = accounts[0];
        let spender = accounts[2];
        let originalAllowance = await instance.allowance.call(approver, spender);
        let tokenWei = 5000000;
        await instance.approve(spender, tokenWei);
        let resultAllowance = await instance.allowance.call(approver, spender);
        assert.strictEqual(originalAllowance.toNumber(), 0);
        assert.strictEqual(resultAllowance.toNumber(), tokenWei);
    });
    it('should fail to [transferFrom] more than allowed', async function() {
        let from = accounts[0];
        let to = accounts[2];
        let tokenWei = 10000000;
        instance.transferFrom(from, to, tokenWei, {from : accounts[2]}).should.be.rejectedWith('revert');
    });
    it('should [transferFrom] approved tokens', async function() {
        let from = accounts[0];
        let to = web3.eth.accounts[2];
        let tokenWei = 5000000;
        let allowance = await instance.allowance.call(from, to);
        let ownerBalance = await instance.balanceOf.call(from);
        let spenderBalance = await instance.balanceOf.call(to);
        await instance.transferFrom(from, to, tokenWei, {from : accounts[2]}).should.be.fulfilled;
        
        let allowanceAfter = await instance.allowance.call(from, to);
        let ownerBalanceAfter = await instance.balanceOf.call(from);
        let spenderBalanceAfter = await instance.balanceOf.call(to);
        // Correct account balances
        // toString() numbers that are too large for js
        assert.strictEqual(
          ownerBalance.toString(),
          ownerBalanceAfter.add(tokenWei).toString()
        );
        assert.strictEqual(
          spenderBalance.add(tokenWei).toString(),
          spenderBalanceAfter.toString()
        );
        // Proper original allowance
        assert.strictEqual(allowance.toNumber(), tokenWei);
        // All of the allowance should have been used
        assert.strictEqual(allowanceAfter.toNumber(), 0);
    });
})