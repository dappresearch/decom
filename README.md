## Experimental Decentralize Ecommerce(DeCom)

This is an ongoing working in progress experimental decentralize store, which will be deployed on one of the ethereum layer2 network. This store can only list one item for simplicity, since it a demo version. 

```
$ forge build
$ forge test
```
## Local testnet deployment

```
$anvil
$ forge script script/DeCom.s.sol:AnvilMyScript --fork-url http://localhost:8545 --broadcast
$ forge script script/DeCom.s.sol:SepoliaMyScript --rpc-url $SEPOLIA_RPC_URL --broadcast --verify -vvvv
```

## Sepolia testnet deployment

```
$  forge script script/DeCom.s.sol:SepoliaMyScript --rpc-url $SEPOLIA_RPC_URL --broadcast --verify -vvvv
```








