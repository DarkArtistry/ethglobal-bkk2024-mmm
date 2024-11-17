## Foundry

**Foundry is a blazing fast, portable and modular toolkit for Ethereum application development written in Rust.**

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
$ make deploy-sepolia
$ make deploy-base-sepolia
```


# Export the ABIs
```shell
forge inspect Trade abi > abis/Trade.json
forge inspect Stash abi > abis/Stash.json
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


### Run Local
```shell
anvil --fork-url https://ethereum-rpc.publicnode.com --port 8080
anvil --fork-url https://polygon.meowrpc.com --port 8081
anvil --fork-url https://ethereum-rpc.publicnode.com --port 8080 --block-time 10
anvil --fork-url https://polygon-pokt.nodies.app --port 8081 --block-time 10
```