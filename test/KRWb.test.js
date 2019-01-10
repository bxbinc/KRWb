require('./setup');

import {sendTransaction} from "./sendTransaction";
import {assertRevert} from 'zos-lib'

const KRWb = artifacts.require('KRWb');

contract('KRWb', function ([_, owner, user1, user2, user3]) {
    beforeEach(async function () {
        this.krwb = await KRWb.new();
        await sendTransaction(this.krwb, 'initialize', ['address'], [owner]);
    });

    it('should set owner', async function () {
        (await this.krwb.owner()).should.be.eq(owner);
    });

    it('should set name, symbol and decimals', async function () {
        (await this.krwb.name()).should.be.eq("KRWb Token");
        (await this.krwb.symbol()).should.be.eq("KRWb");
        (await this.krwb.decimals()).toNumber().should.be.eq(2);
    });

    it('should mint', async function () {
        await assertRevert(this.krwb.mint(user1, 1, {from: user1}));

        await this.krwb.addToMintWhitelist(user1, {from: owner});
        (await this.krwb.getMintWhitelistLength()).toNumber().should.be.eq(1);
        (await this.krwb.getMintWhitelist(0)).should.be.eq(user1);

        await this.krwb.pause({from: owner});
        await assertRevert(this.krwb.mint(user1, 1, {from: owner}));

        await this.krwb.unpause({from: owner});
        await this.krwb.mint(user1, 1, {from: owner});
        (await this.krwb.balanceOf(user1)).toNumber().should.be.eq(1);
        (await this.krwb.totalSupply()).toNumber().should.be.eq(1);

        await this.krwb.setMintBounds(10, 100, {from: owner});
        (await this.krwb.mintMin()).toNumber().should.be.eq(10);
        (await this.krwb.mintMax()).toNumber().should.be.eq(100);

        await this.krwb.mint(user1, 10, {from: owner});
        await this.krwb.mint(user1, 100, {from: owner});
        (await this.krwb.totalSupply()).toNumber().should.be.eq(111);
        await assertRevert(this.krwb.mint(user1, 9, {from: owner}));
        await assertRevert(this.krwb.mint(user1, 101, {from: owner}));

        await this.krwb.removeFromMintWhitelist(user1, {from: owner});
        (await this.krwb.getMintWhitelistLength()).toNumber().should.be.eq(0);
    });

    it('should burn', async function () {
        await assertRevert(this.krwb.burn(1, {from: owner}));

        await this.krwb.addToMintWhitelist(user1, {from: owner});
        await this.krwb.mint(user1, 1, {from: owner});
        (await this.krwb.balanceOf(user1)).toNumber().should.be.eq(1);
        (await this.krwb.totalSupply()).toNumber().should.be.eq(1);

        await this.krwb.pause({from: owner});
        await assertRevert(this.krwb.burn(1, {from: owner}));

        await this.krwb.unpause({from: owner});
        await assertRevert(this.krwb.burn(1, {from: user1}));

        await this.krwb.addToMintWhitelist(owner, {from: owner});
        await this.krwb.mint(owner, 1, {from: owner});
        (await this.krwb.balanceOf(owner)).toNumber().should.be.eq(1);
        (await this.krwb.totalSupply()).toNumber().should.be.eq(2);

        await this.krwb.burn(1, {from: owner});
        (await this.krwb.balanceOf(owner)).toNumber().should.be.eq(0);
        (await this.krwb.totalSupply()).toNumber().should.be.eq(1);

        await this.krwb.mint(owner, 1000, {from: owner});
        (await this.krwb.totalSupply()).toNumber().should.be.eq(1001);

        await assertRevert(this.krwb.setBurnBounds(10, 9, {from: owner}));
        await this.krwb.setBurnBounds(10, 100, {from: owner});
        (await this.krwb.burnMin()).toNumber().should.be.eq(10);
        (await this.krwb.burnMax()).toNumber().should.be.eq(100);

        await this.krwb.burn(10, {from: owner});
        await this.krwb.burn(100, {from: owner});
        (await this.krwb.totalSupply()).toNumber().should.be.eq(891);
        await assertRevert(this.krwb.burn(9, {from: owner}));
        await assertRevert(this.krwb.burn(101, {from: owner}));
    });

    it('should pause and unpause', async function () {
        await this.krwb.addToMintWhitelist(user1, {from: owner});
        await this.krwb.mint(user1, 10, {from: owner});
        (await this.krwb.balanceOf(user1)).toNumber().should.be.eq(10);

        await assertRevert(this.krwb.pause({from: user1}));

        await this.krwb.pause({from: owner});
        (await this.krwb.paused()).should.be.eq(true);

        await assertRevert(this.krwb.transfer(user2, 1, {from: user1}));
        await assertRevert(this.krwb.approve(owner, 1, {from: user1}));
        await assertRevert(this.krwb.transferFrom(user1, user2, 1, {from: owner}));
        await assertRevert(this.krwb.increaseAllowance(owner, 1, {from: user1}));
        await assertRevert(this.krwb.decreaseAllowance(owner, 1, {from: user1}));

        await assertRevert(this.krwb.unpause({from: user1}));

        await this.krwb.unpause({from: owner});
        (await this.krwb.paused()).should.be.eq(false);

        await this.krwb.transfer(user2, 1, {from: user1});
        (await this.krwb.balanceOf(user1)).toNumber().should.be.eq(9);
        (await this.krwb.balanceOf(user2)).toNumber().should.be.eq(1);

        await this.krwb.approve(owner, 1, {from: user1});
        (await this.krwb.allowance(user1, owner)).toNumber().should.be.eq(1);
        await this.krwb.increaseAllowance(owner, 1, {from: user1});
        (await this.krwb.allowance(user1, owner)).toNumber().should.be.eq(2);
        await this.krwb.decreaseAllowance(owner, 1, {from: user1});
        (await this.krwb.allowance(user1, owner)).toNumber().should.be.eq(1);

        await this.krwb.transferFrom(user1, user2, 1, {from: owner});
        (await this.krwb.balanceOf(user1)).toNumber().should.be.eq(8);
        (await this.krwb.balanceOf(user2)).toNumber().should.be.eq(2);
    });

    it('should add to and remove from blacklist', async function () {
        await this.krwb.addToMintWhitelist(user1, {from: owner});
        await this.krwb.mint(user1, 10, {from: owner});
        (await this.krwb.balanceOf(user1)).toNumber().should.be.eq(10);

        await assertRevert(this.krwb.addToBlacklist(user1, {from: user1}));

        await this.krwb.addToBlacklist(user1, {from: owner});
        (await this.krwb.isBlacklisted(user1)).should.be.eq(true);
        (await this.krwb.getBlacklistLength()).toNumber().should.be.eq(1);
        (await this.krwb.getBlacklist(0)).should.be.eq(user1);

        await assertRevert(this.krwb.transfer(user2, 1, {from: user1}));
        await assertRevert(this.krwb.approve(owner, 1, {from: user1}));
        await assertRevert(this.krwb.transferFrom(user1, user2, 1, {from: owner}));
        await assertRevert(this.krwb.increaseAllowance(owner, 1, {from: user1}));
        await assertRevert(this.krwb.decreaseAllowance(owner, 1, {from: user1}));

        await assertRevert(this.krwb.removeFromBlacklist(user1, {from: user1}));

        await this.krwb.removeFromBlacklist(user1, {from: owner});
        (await this.krwb.isBlacklisted(user1)).should.be.eq(false);
        (await this.krwb.getBlacklistLength()).toNumber().should.be.eq(0);

        await this.krwb.transfer(user2, 1, {from: user1});
        (await this.krwb.balanceOf(user1)).toNumber().should.be.eq(9);
        (await this.krwb.balanceOf(user2)).toNumber().should.be.eq(1);

        await this.krwb.approve(owner, 1, {from: user1});
        (await this.krwb.allowance(user1, owner)).toNumber().should.be.eq(1);
        await this.krwb.increaseAllowance(owner, 1, {from: user1});
        (await this.krwb.allowance(user1, owner)).toNumber().should.be.eq(2);
        await this.krwb.decreaseAllowance(owner, 1, {from: user1});
        (await this.krwb.allowance(user1, owner)).toNumber().should.be.eq(1);

        await this.krwb.transferFrom(user1, user2, 1, {from: owner});
        (await this.krwb.balanceOf(user1)).toNumber().should.be.eq(8);
        (await this.krwb.balanceOf(user2)).toNumber().should.be.eq(2);
    });

    it('should transfer with fee', async function () {
        await testTransferFees(this.krwb, owner);
    });

    it('should transfer with fee after changing transferFeeReceiver', async function () {
        await this.krwb.setTransferFeeReceiver(user3, {from: owner});
        (await this.krwb.transferFeeReceiver()).should.be.eq(user3);
        await testTransferFees(this.krwb, user3);
    });

    it('should transfer with individual fee', async function () {
        await testIndividualTransferFees(this.krwb, owner);
    });

    it('should transfer with individual fee after changing transferFeeReceiver', async function () {
        await this.krwb.setTransferFeeReceiver(user3, {from: owner});
        (await this.krwb.transferFeeReceiver()).should.be.eq(user3);
        await testIndividualTransferFees(this.krwb, user3);
    });

    const testTransferFees = async function (krwb, transferFeeReceiver) {
        await krwb.addToMintWhitelist(user1, {from: owner});
        await krwb.addToMintWhitelist(user2, {from: owner});
        await krwb.mint(user1, 100, {from: owner});
        (await krwb.balanceOf(user1)).toNumber().should.be.eq(100);

        await assertRevert(krwb.setTransferFee(3, 50, {from: user1}));
        await assertRevert(krwb.setTransferFee(0, 0, {from: owner}));
        await assertRevert(krwb.setTransferFee(1, 1, {from: owner}));

        await krwb.setTransferFee(3, 50, {from: owner});
        (await krwb.transferFeeNumerator()).toNumber().should.be.eq(3);
        (await krwb.transferFeeDenominator()).toNumber().should.be.eq(50);

        await krwb.transfer(user2, 100, {from: user1});
        (await krwb.balanceOf(user1)).toNumber().should.be.eq(0);
        (await krwb.balanceOf(user2)).toNumber().should.be.eq(94);
        (await krwb.balanceOf(transferFeeReceiver)).toNumber().should.be.eq(6);

        await krwb.mint(user2, 6, {from: owner});
        (await krwb.balanceOf(user1)).toNumber().should.be.eq(0);
        (await krwb.balanceOf(user2)).toNumber().should.be.eq(100);
        (await krwb.balanceOf(transferFeeReceiver)).toNumber().should.be.eq(6);

        await krwb.approve(owner, 100, {from: user2});
        await krwb.transferFrom(user2, user1, 100, {from: owner});
        (await krwb.balanceOf(user1)).toNumber().should.be.eq(94);
        (await krwb.balanceOf(user2)).toNumber().should.be.eq(0);
        (await krwb.balanceOf(transferFeeReceiver)).toNumber().should.be.eq(12);

        await krwb.setTransferFee(0, 100, {from: owner});
        (await krwb.transferFeeNumerator()).toNumber().should.be.eq(0);
        (await krwb.transferFeeDenominator()).toNumber().should.be.eq(100);

        await krwb.transfer(user2, 94, {from: user1});
        (await krwb.balanceOf(user1)).toNumber().should.be.eq(0);
        (await krwb.balanceOf(user2)).toNumber().should.be.eq(94);
        (await krwb.balanceOf(transferFeeReceiver)).toNumber().should.be.eq(12);
    };

    const testIndividualTransferFees = async function (krwb, transferFeeReceiver) {
        await krwb.addToMintWhitelist(user1, {from: owner});
        await krwb.addToMintWhitelist(user2, {from: owner});
        await krwb.mint(user1, 100, {from: owner});
        (await krwb.balanceOf(user1)).toNumber().should.be.eq(100);

        await assertRevert(krwb.setIndividualTransferFee(user1, 7, 100, {from: user1}));
        await assertRevert(krwb.setTransferFee(0, 0, {from: owner}));
        await assertRevert(krwb.setTransferFee(1, 1, {from: owner}));

        await krwb.setIndividualTransferFee(user1, 7, 100, {from: owner});
        (await krwb.individualTransferFeeNumerator(user1)).toNumber().should.be.eq(7);
        (await krwb.individualTransferFeeDenominator(user1)).toNumber().should.be.eq(100);

        await krwb.transfer(user2, 100, {from: user1});
        (await krwb.balanceOf(user1)).toNumber().should.be.eq(0);
        (await krwb.balanceOf(user2)).toNumber().should.be.eq(93);
        (await krwb.balanceOf(transferFeeReceiver)).toNumber().should.be.eq(7);

        await krwb.setIndividualTransferFee(user2, 11, 100, {from: owner});
        (await krwb.individualTransferFeeNumerator(user2)).toNumber().should.be.eq(11);
        (await krwb.individualTransferFeeDenominator(user2)).toNumber().should.be.eq(100);

        await krwb.mint(user2, 7, {from: owner});
        (await krwb.balanceOf(user1)).toNumber().should.be.eq(0);
        (await krwb.balanceOf(user2)).toNumber().should.be.eq(100);
        (await krwb.balanceOf(transferFeeReceiver)).toNumber().should.be.eq(7);

        await krwb.approve(owner, 100, {from: user2});
        await krwb.transferFrom(user2, user1, 100, {from: owner});
        (await krwb.balanceOf(user1)).toNumber().should.be.eq(89);
        (await krwb.balanceOf(user2)).toNumber().should.be.eq(0);
        (await krwb.balanceOf(transferFeeReceiver)).toNumber().should.be.eq(18);
    }
});
