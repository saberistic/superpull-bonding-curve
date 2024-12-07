# Bonding Curve Contract for SuperPull Platform

This project implements a **Bonding Curve** smart contract for experimenting with dynamic token pricing mechanisms on the [SuperPull](https://superpull.world) platform.

## Overview

The `BondingCurve.sol` contract models a bonding curve, which defines the relationship between token supply and price. It enables dynamic pricing based on supply and demand, facilitating fair and transparent token distribution on the SuperPull platform.

## Components

- **`src/BondingCurve.sol`**: The primary contract implementing the bonding curve logic.
- **`src/superpull.sol`**: Integrates the bonding curve with SuperPull platform-specific features.
- **Tests**:
  - **`test/BondingCurve.t.sol`**: Unit tests for the bonding curve contract.
  - **`test/Counter.t.sol`**: Additional tests.

## Usage

### Build

```shell
$ forge build
```

### Test

```shell
$ forge test
```

### Anvil

Anvil is a local Ethereum node implemented in Rust, similar to Ganache or Hardhat Network. It allows you to set up a local Ethereum blockchain for development and testing purposes.

```shell
$ anvil
```

When you run `anvil`, it starts a local Ethereum node on `http://localhost:8545`. You can connect to it using your Ethereum development tools like Forge, Cast, or any Ethereum client.

## Deploy

To deploy the `BondingCurve` contract, use the following command:

```shell
$ forge script script/BondingCurve.s.sol:BondingCurveScript --rpc-url <your_rpc_url> --private-key <your_private_key> --broadcast
```

Replace `<your_rpc_url>` with your Ethereum node RPC URL and `<your_private_key>` with your private key.

## Examples

### Buying Tokens

You can interact with the deployed contract to buy tokens using the `buy` function:

```solidity
bondingCurve.buy{value: amountInWei}();
```

Replace `amountInWei` with the amount of Ether (in wei) you want to spend.

### Selling Tokens

To sell tokens back to the bonding curve, use the `sell` function:

```solidity
bondingCurve.sell(tokenAmount);
```

Replace `tokenAmount` with the amount of tokens you wish to sell.

### Checking Token Price

To get the cost of buying a specific amount of tokens based on the bonding curve:

```solidity
uint256 cost = bondingCurve.buyPrice(amount);
```

Replace `amount` with the number of tokens you want to buy.

To calculate the revenue from selling a specific amount of tokens:

```solidity
uint256 revenue = bondingCurve.sellPrice(amount);
```

Replace `amount` with the number of tokens you wish to sell.

### Retrieving Total Supply

To check the total supply of tokens:

```solidity
uint256 totalSupply = bondingCurve.totalSupply();
```

### Example Script

An example of calling contract functions in a script:

```javascript
// Assume you have a web3 or ethers.js instance set up
const bondingCurveContract = new ethers.Contract(contractAddress, abi, signer);

// Buying tokens
await bondingCurveContract.buy({ value: ethers.utils.parseEther("1.0") });

// Selling tokens
await bondingCurveContract.sell(ethers.utils.parseUnits("10", 18));

// Checking current price
const price = await bondingCurveContract.getCurrentPrice();

// Getting total supply
const supply = await bondingCurveContract.totalSupply();
```

## Contract Functions

Below are all the functions provided by the `BondingCurve` contract along with their descriptions:

- **`buyPrice(uint256 amount) public view returns (uint256)`**

  Calculates the cost in Ether to buy a specific `amount` of tokens based on the bonding curve pricing formula.

- **`sellPrice(uint256 amount) public view returns (uint256)`**

  Calculates the revenue in Ether from selling a specific `amount` of tokens back to the bonding curve.

- **`buy(uint256 amount) external payable`**

  Allows users to purchase a specific `amount` of tokens. Users must send enough Ether to cover the cost calculated by `buyPrice(amount)`. Any excess Ether sent will be refunded.

- **`sell(uint256 amount) external`**

  Allows users to sell a specific `amount` of tokens back to the bonding curve in exchange for Ether. The Ether amount received is calculated using `sellPrice(amount)`.

- **`withdrawReserve(uint256 amount) external onlyOwner`**

  Enables the contract owner to withdraw a specific `amount` of Ether from the contract's reserve.

- **`receive() external payable`**

  Fallback function to accept Ether sent directly to the contract. Increases the contract's reserve balance.

## Disclaimer

**Note:** This smart contract has not been audited. Use it at your own risk.

