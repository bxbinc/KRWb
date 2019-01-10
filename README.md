# KRWb

Solidity contracts for KRWb.

## Contracts
* multisig/MultisigWallet.sol: Allows multiple parties to agree on transactions before execution.
* token/ERC20.sol: Standard ERC20 token.
* token/Ownable.sol: Owner is set at first and cannot be changed.
* token/ERC20Detailed.sol: Specifies name, symbol and decimals.
* token/ERC20WithFees.sol: Sets transferFee and individualsTransferFee.
* token/ERC20WithBlacklist.sol: Maintains blacklisted accounts.
* token/PausableERC20.sol: Pauses and unpauses transfers of token.
* token/BurnableERC20.sol: Burns tokens.
* token/MintableERC20.sol: Mints tokens.


## Requirements
### Install
```
npm install -g zos
npm install
```
### Configure .env
Create a file named `.env` at the project root and copy following.
```
ROPSTEN_PROVIDER_URL=https://ropsten.infura.io/v3/<Your Infura API Key>
ROPSTEN_MNEMONIC=<Seed phrases of 12 words>
```
## Deploy
> **Caution**: *Deployment Account* must be different from accounts you want to interact with the contract later. If you deployed a contract with Account X, then all the following calls/transactions to that contract from Account X shall fail with errors.
### Initialize
If you want to ignore previous updates, do the following.
Delete the file `zos.<Network Name>.json` if exist network setting. Then,  
```
zos add MultisigWallet
zos add KRWb
zos link openzeppelin-eth
zos session --network <Network Name> --from <Deployment Account>
zos push
zos create MultisigWallet --init initialize --args [<Account1>,<Account2>,<Account3>],3
zos create KRWb --init initialize --args <MultisigWallet Address>
```
### Update
Everytime contracts need to be updated, do the following.
```
zos session --network <Network Name> --from <Deployment Account>
zos push
zos update MultisigWallet
zos update KRWb

```

## Test
```
npm test
```

## Code Coverage
The following generates coverage report.
```
./node_modules/.bin/solidity-coverage
```
