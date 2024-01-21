## TSwap Project

**Description** 

TSwap is a decentralized token swap contract built on Ethereum, enabling users to swap between ERC20 tokens and manage liquidity in a fixed ratio pool. The project leverages Solidity and OpenZeppelin's SafeERC20 library to ensure safe and efficient ERC20 token interactions.
This is really v v basic implementation of an AMM with a fixed ratio pool.

**Features**

-  **Token Swapping**: Swap between different ERC20 tokens with ease.
-  **Liquidity Provision**: Users can provide liquidity to the pool and receive liquidity provider (LP) tokens in return.
-  **Liquidity Removal**: Liquidity providers can remove their liquidity from the pool, receiving back their share of the pool's tokens.
-  **Fixed Ratio Pool**: Maintains a fixed ratio for liquidity provisions, ensuring balanced token contributions.





## Foundry

**Built with foundry**

Foundry consists of:

-   **Forge**: Ethereum testing framework (like Truffle, Hardhat and DappTools).
-   **Cast**: Swiss army knife for interacting with EVM smart contracts, sending transactions and getting chain data.
-   **Anvil**: Local Ethereum node, akin to Ganache, Hardhat Network.
-   **Chisel**: Fast, utilitarian, and verbose solidity REPL.

## Documentation

https://book.getfoundry.sh/

## Usage

### Build

```shell
$ forge build
```

### Test

```shell
$ forge test
```

### Format

```shell
$ forge fmt
```

### Gas Snapshots

```shell
$ forge snapshot
```

### Anvil

```shell
$ anvil
```

### Deploy

```shell
$ forge script script/Counter.s.sol:CounterScript --rpc-url <your_rpc_url> --private-key <your_private_key>
```

### Cast

```shell
$ cast <subcommand>
```

### Help

```shell
$ forge --help
$ anvil --help
$ cast --help
```
