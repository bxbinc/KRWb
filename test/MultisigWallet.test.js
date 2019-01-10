require('./setup');

import {sendTransaction} from "./sendTransaction";
import * as utils from './utils';
import {assertRevert} from 'zos-lib'

const MultisigWallet = artifacts.require('MultisigWallet');
const KRWb = artifacts.require('KRWb');

const newWallet = async (owners, required) => {
    let wallet = await MultisigWallet.new();
    await sendTransaction(wallet, 'initialize', ['address[]', 'uint256'], [owners, required]);
    return wallet;
};

const newToken = async (wallet) => {
    let token = await KRWb.new();
    await sendTransaction(token, 'initialize', ['address'], [wallet.address]);
    return token;
};

const getTransactionId = (transaction) => {
    return utils.getParamFromTxEvent(transaction, 'transactionId', null, 'Submission');
};

const sleep = (seconds) => {
    return new Promise(resolve => setTimeout(resolve, seconds * 1000));
};

contract('MultisigWallet', function ([_, owner1, owner2, owner3, user]) {
    it('should set owners and required', async function () {
        let wallet = await newWallet([owner1, owner2, owner3], 3);

        (await wallet.owners(0)).should.be.eq(owner1);
        (await wallet.owners(1)).should.be.eq(owner2);
        (await wallet.owners(2)).should.be.eq(owner3);
    });

    it('should have at least one owner', async function () {
        await assertRevert(newWallet([], 0));
    });

    it('should deposit', async function () {
        const wallet = await newWallet([owner1], 1);
        const sender = owner2;
        const value = 1;
        const tx = await wallet.sendTransaction({from: sender, value: value});
        utils.getParamFromTxEvent(tx, "sender", null, "Deposit").should.be.eq(sender);
        utils.getParamFromTxEvent(tx, "value", null, "Deposit").toNumber().should.be.eq(value);
    });

    it('should submit', async function () {
        let wallet = await newWallet([owner1], 1);

        const to = wallet.address;
        const value = 1;
        const data = wallet.contract.addOwner.getData(owner2);
        const expiredAt = Math.floor((Date.now() / 1000) + 3);
        const memo = "test";
        const txId = getTransactionId(
            await wallet.submitTransaction(to, value, data, expiredAt, memo, {from: owner1})
        );
        (await wallet.getTransactionIds(0, 1, true, true))[0].toNumber().should.be.eq(txId.toNumber());
        (await wallet.getConfirmationCount(txId)).toNumber().should.be.eq(1);

        const tx = await wallet.transactions(txId);
        tx[0].should.be.eq(to);
        tx[1].toNumber().should.be.eq(value);
        tx[2].should.be.eq(data);
        tx[4].toNumber().should.be.eq(expiredAt);
        tx[5].should.be.eq(memo);
        tx[6].should.be.eq(false); // executed
    });

    it('should add owner', async function () {
        let wallet = await newWallet([owner1], 1);

        // add owner2
        let data = wallet.contract.addOwner.getData(owner2);
        await wallet.submitTransaction(wallet.address, 0, data, 0, "", {from: owner1});
        (await wallet.owners(0)).should.be.eq(owner1);
        (await wallet.owners(1)).should.be.eq(owner2);

        // change required to 2
        data = wallet.contract.changeRequirement.getData(2);
        await wallet.submitTransaction(wallet.address, 0, data, 0, "", {from: owner1});
        (await wallet.required()).toNumber().should.be.eq(2);

        // add owner3
        data = wallet.contract.addOwner.getData(owner3);
        let transactionId = getTransactionId(
            await wallet.submitTransaction(wallet.address, 0, data, 0, "", {from: owner1})
        );
        await wallet.confirmTransaction(transactionId, {from: owner2});
        (await wallet.owners(0)).should.be.eq(owner1);
        (await wallet.owners(1)).should.be.eq(owner2);
        (await wallet.owners(2)).should.be.eq(owner3);
    });

    it('should remove owner', async function () {
        let wallet = await newWallet([owner1, owner2, owner3], 3);

        // remove owner2
        let data = wallet.contract.removeOwner.getData(owner2);
        let transactionId = getTransactionId(
            await wallet.submitTransaction(wallet.address, 0, data, 0, "", {from: owner1})
        );
        await wallet.confirmTransaction(transactionId, {from: owner2});
        await wallet.confirmTransaction(transactionId, {from: owner3});
        (await wallet.getOwners()).length.should.be.eq(2);
        (await wallet.required()).toNumber().should.be.eq(2);

        // remove owner3
        data = wallet.contract.removeOwner.getData(owner3);
        transactionId = getTransactionId(
            await wallet.submitTransaction(wallet.address, 0, data, 0, "", {from: owner1})
        );
        await wallet.confirmTransaction(transactionId, {from: owner3});
        (await wallet.getOwners()).length.should.be.eq(1);
        (await wallet.required()).toNumber().should.be.eq(1);

        // remove owner 1
        data = wallet.contract.removeOwner.getData(owner1);
        let transaction = await wallet.submitTransaction(wallet.address, 0, data, 0, "", {from: owner1});
        transaction.logs.filter((l) => l.event === "ExecutionFailure").length.should.be.eq(1)
    });

    it('should replace owner', async function () {
        let wallet = await newWallet([owner1, owner2], 2);

        // replace owner2 with owner3
        let data = wallet.contract.replaceOwner.getData(owner2, owner3);
        let transactionId = getTransactionId(
            await wallet.submitTransaction(wallet.address, 0, data, 0, "", {from: owner1})
        );
        await wallet.confirmTransaction(transactionId, {from: owner2});
        (await wallet.getOwners()).length.should.be.eq(2);
        (await wallet.owners(0)).should.be.eq(owner1);
        (await wallet.owners(1)).should.be.eq(owner3);

        // replace owner3 with owner3
        data = wallet.contract.replaceOwner.getData(owner3, owner3);
        transactionId = getTransactionId(
            await wallet.submitTransaction(wallet.address, 0, data, 0, "", {from: owner1})
        );
        let transaction = await wallet.confirmTransaction(transactionId, {from: owner3});
        transaction.logs.filter((l) => l.event === "ExecutionFailure").length.should.be.eq(1)
    });

    it('should submit, confirm and execute', async function () {
        let wallet = await newWallet([owner1, owner2, owner3], 3);
        let token = await newToken(wallet);
        (await token.paused()).should.be.eq(false);

        let data = token.contract.pause.getData();

        // only owners can submit a transaction
        await assertRevert(wallet.submitTransaction(token.address, 0, data, 0, "", {from: user}));

        // only transactions that has been submitted can be confirmed
        (await wallet.getTransactionCount(true, true)).toNumber().should.be.eq(0);
        await assertRevert(wallet.confirmTransaction(0, {from: owner1}));
        await assertRevert(wallet.confirmTransaction(0, {from: owner2}));
        await assertRevert(wallet.confirmTransaction(0, {from: owner3}));

        // submit of owner1
        let transactionId = getTransactionId(
            await wallet.submitTransaction(token.address, 0, data, 0, "", {from: owner1})
        );
        (await wallet.getTransactionCount(true, true)).toNumber().should.be.eq(1);
        (await wallet.getConfirmations(transactionId)).length.should.be.eq(1);
        (await wallet.isConfirmed(transactionId)).should.be.eq(false);
        (await token.paused()).should.be.eq(false);

        // confirm of owner2
        await wallet.confirmTransaction(transactionId, {from: owner2});
        (await wallet.getConfirmations(transactionId)).length.should.be.eq(2);
        (await wallet.isConfirmed(transactionId)).should.be.eq(false);
        (await token.paused()).should.be.eq(false);

        // confirm of owner3
        await wallet.confirmTransaction(transactionId, {from: owner3});
        (await wallet.getConfirmations(transactionId)).length.should.be.eq(3);
        (await wallet.isConfirmed(transactionId)).should.be.eq(true);
        (await token.paused()).should.be.eq(true);

        // a transaction that has already been confirmed cannot be confirmed again
        await assertRevert(wallet.confirmTransaction(transactionId, {from: owner1}));
        await assertRevert(wallet.confirmTransaction(transactionId, {from: owner2}));
        await assertRevert(wallet.confirmTransaction(transactionId, {from: owner3}));
    });

    it('should submit, confirm and revoke', async function () {
        let wallet = await newWallet([owner1, owner2, owner3], 3);
        let token = await newToken(wallet);

        let data = token.contract.pause.getData();

        // submit of owner1
        let transactionId = getTransactionId(
            await wallet.submitTransaction(token.address, 0, data, 0, "", {from: owner1})
        );
        (await wallet.getTransactionCount(true, true)).toNumber().should.be.eq(1);
        (await wallet.getConfirmations(transactionId)).length.should.be.eq(1);
        (await wallet.isConfirmed(transactionId)).should.be.eq(false);

        // confirm of owner2
        await wallet.confirmTransaction(transactionId, {from: owner2});
        (await wallet.getConfirmations(transactionId)).length.should.be.eq(2);
        (await wallet.isConfirmed(transactionId)).should.be.eq(false);

        // only owners can revoke a transaction
        await assertRevert(wallet.revokeConfirmation(transactionId, {from: user}));

        // revoke of owner2
        await wallet.revokeConfirmation(transactionId, {from: owner2});
        (await wallet.getConfirmations(transactionId)).length.should.be.eq(1);
        (await wallet.isConfirmed(transactionId)).should.be.eq(false);

        // revoke of owner1
        await wallet.revokeConfirmation(transactionId, {from: owner1});
        (await wallet.getConfirmations(transactionId)).length.should.be.eq(0);
        (await wallet.isConfirmed(transactionId)).should.be.eq(false);

        // revoke of owner3
        await assertRevert(wallet.revokeConfirmation(transactionId, {from: owner3}));
    });

    it('should submit, confirm and invalidate', async function () {
        let wallet = await newWallet([owner1, owner2, owner3], 3);
        let token = await newToken(wallet);

        let data = token.contract.pause.getData();

        // submit of owner1
        let transactionId = getTransactionId(
            await wallet.submitTransaction(token.address, 0, data, 0, "", {from: owner1})
        );
        (await wallet.getTransactionCount(true, true)).toNumber().should.be.eq(1);
        (await wallet.getConfirmations(transactionId)).length.should.be.eq(1);
        (await wallet.isConfirmed(transactionId)).should.be.eq(false);
        (await wallet.invalidated(transactionId)).should.be.eq(false);

        // confirm of owner2
        await wallet.confirmTransaction(transactionId, {from: owner2});
        (await wallet.getConfirmations(transactionId)).length.should.be.eq(2);
        (await wallet.isConfirmed(transactionId)).should.be.eq(false);
        (await wallet.invalidated(transactionId)).should.be.eq(false);

        // only owners can invalidate a transaction
        await assertRevert(wallet.invalidateTransaction(transactionId, {from: user}));

        // invalidation of owner2
        await wallet.invalidateTransaction(transactionId, {from: owner2});
        (await wallet.invalidated(transactionId)).should.be.eq(true);

        // invalidated transactions cannot be invalidated again
        await assertRevert(wallet.invalidateTransaction(transactionId, {from: owner1}));
        await assertRevert(wallet.invalidateTransaction(transactionId, {from: owner2}));
        await assertRevert(wallet.invalidateTransaction(transactionId, {from: owner3}));

        // invalidated transactions cannot be confirmed
        await assertRevert(wallet.confirmTransaction(transactionId, {from: owner3}));

        // invalidated transactions cannot be revoked
        await assertRevert(wallet.revokeConfirmation(transactionId, {from: owner2}));
    });

    it('should submit, confirm and expire', async function () {
        let wallet = await newWallet([owner1, owner2, owner3], 3);
        let token = await newToken(wallet);

        let data = token.contract.pause.getData();
        let expiredAt = (Date.now() / 1000) + 3;

        // submit of owner1
        let transactionId = getTransactionId(
            await wallet.submitTransaction(token.address, 0, data, expiredAt, "", {from: owner1})
        );
        (await wallet.getTransactionCount(true, true)).toNumber().should.be.eq(1);
        (await wallet.getConfirmations(transactionId)).length.should.be.eq(1);
        (await wallet.isConfirmed(transactionId)).should.be.eq(false);
        (await wallet.invalidated(transactionId)).should.be.eq(false);

        // confirm of owner2
        await wallet.confirmTransaction(transactionId, {from: owner2});
        (await wallet.getConfirmations(transactionId)).length.should.be.eq(2);
        (await wallet.isConfirmed(transactionId)).should.be.eq(false);
        (await wallet.invalidated(transactionId)).should.be.eq(false);

        // wait for 3 seconds
        await sleep(3);

        // revoke of owner1
        await assertRevert(wallet.revokeConfirmation(transactionId, {from: owner1}));
        // revoke of owner2
        await assertRevert(wallet.revokeConfirmation(transactionId, {from: owner2}));
        // confirm of owner3
        await assertRevert(wallet.confirmTransaction(transactionId, {from: owner3}));
    });
});
