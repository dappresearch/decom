## Experimental Decentralize Ecommerce(DeCom)

This is an ongoing working in progress experimental decentralize store, which will be deployed on one of the ethereum layer2 network. This store can only list one item for simplicity, since it a demo version. 

```
$ forge build
$ forge test
```

-See env.example before any of the following depoloyment.

-create .env file and structure the variables according to env.example.

## Local testnet deployment

```
$anvil
$ source .env
$ forge script script/DeCom.s.sol:Anvil --fork-url http://localhost:8545 --broadcast
```

## Sepolia testnet deployment

```
$ sournce .env
$  forge script script/DeCom.s.sol:Sepolia --rpc-url $SEPOLIA_RPC_URL --broadcast
```


## Arbitrum Sepolia testnet deploye

```
$ source .env
$  forge script script/DeCom.s.sol:ArbitrumSepolia --rpc-url $ARBITRUM_SEPOLIA --broadcast 
```







