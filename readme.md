# bitgrit token and token lock contract
[*This token's development was initially done under `gr-token` so you may find references to the same in a few places*]

## Overview / Objective

* We issue new ERC20 token, named 'bitgrit token'.
* We also develop 'token lock contract' to lock and release the designated amount of tokens of each stakeholder. 
* Token lock should be managed by 'administrators'. The program logic to determine who are administrators, should be upgradable.
* We want to batch-transfer the token to the recipients. 

## bitgrit token specification

* token name: bitgrit token
* ticker symbol: BGR
* token standard: ERC20
* token use: utility
* decimals: 18
* initial supply: 750,000,000
* total supply: 750,000,000
* mintable: no
* burnable: no

## Contracts

There are 4 contracts in total as follows:

### Relations

 * See image below
    - `BGR token` is referred by `batch transfer` and `token lock` contract.
    - `Batch transfer` transfers BGR token to multiple recipients at the same time. Operator(User) should allow `Batch transfer` to spend their tokens before using the contract.
    - `Token lock` locks the designated amount of BGR token until designated time. Only admin can lock/change/remove locks in the contract. Admin Set should be fetched by using `isAdmin(address, bytes)`. When token is locked, the designated amount of BGR token is also sent to the contract, so Admins should allow the `token lock` contract to spend their tokens.
    - `AdminController` manages admin set and implement `isAdmin(address, bytes)`.

<!-- ![image](https://user-images.githubusercontent.com/26596367/103618378-368d5f00-4f73-11eb-90be-e4bb327d665b.png) -->

<img src="https://user-images.githubusercontent.com/26596367/103618378-368d5f00-4f73-11eb-90be-e4bb327d665b.png" width="500" />

### GRToken.sol

* Implement ERC20 based on the specification written above.

### BatchTransfer.sol

* Implement batch transfer function. Before use, users must allow this contract to spend their tokens.
* `function batchTransfer(IERC20 erc20, address[] calldata addrs, uint[] calldata values)`
    - Transfer `values[i]` tokens to `address[i]`.
    - Contract deployer will be the owner of the contract and cannot be altered in the future. Only owner can use the `batchTransfer` function.

### GRTokenMultipleTimelock.sol

* `constructor(IERC20 grToken_, IAdminController adminController_)`
    - Initialize the contract to handle `grToken_`. Admin set is fetched from `adminController_.isAdmin()`.
* `function setAdminContoller(IAdminController adminController_)`
    - Set new admin judgement logic
* `function lock(uint256 id, address beneficiary, uint256 amount, uint256 releaseTime, bytes memory data)`
    - Lock the `amount` of `_grToken` until `releaseTime` as lock-id `id`.  When released, `amount` of `_grToken` will be transfered to `beneficiary`.
    - `data` is used for future extensions and not in use for now.
* `function release(uint256 id)`
    - Release the lock of lock-id `id` only when current timestamp exceeds locks[`id`].releaseTime and the lock is not released.
* `function change(uint256 id, address newBeneficiary, uint256 newAmount, uint256 newReleaseTime, bytes memory data)`
    - Change the lock of lock-id `id` to have `newAmount`, `newBeneficiary` and `newReleaseTime` only when the lock is not released. If the newAmount > current locked amount, this contract need more tokens locked. So difference( {newAmount} - {current locked amount} ) should be transfered to this contract from the caller. On the other hand, if the current locked amount > newAmount, difference( {current locked amount} - {newAmount} ) should be transfered to the caller from this contract
    - `data` is used for future extensions and not in use for now.
* `function remove(uint256 id, bytes memory data)`
    - Remove the lock of lock-id `id` only when the lock is not released.
    - `data` is used for future extensions and not in use for now.
* `function lockOf(uint256 id)`
    - Get the data of the lock of lock-id `id`

### AdminControllerV1.sol

* Implement `1-of-n` admin control scheme.
* Only admin can add new admins and revoke existing admins.
* Contract deployer will be the first admin.