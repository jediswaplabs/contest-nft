# contest-nft

Jediswap nft contract for LP contest.


Greatly powered by [ruleslab's code](https://github.com/ruleslabs/starknet-erc721.git) and [alexandria](https://github.com/keep-starknet-strange/alexandria)

## Testing

```
scarb test
```

## Declare
```
starkli declare target/dev/jedinft_JediNFT.sierra.json --account ${Your starkli account path}

```

## Deploy
```
starkli deploy 0x0448ba00e7c1a0ac10b09c5cf3cc6e27f7c10cb8b8b5ae4fb4398f22dc00b198 str:Rise\ of\ the\ First\ LPs str:MIS 2 str:https://static.missions str:.jediswap.xyz/missions-json/ 3 str:https://static.missions str:.jediswap.xyz/ str:missions-json/0.json 0x0138EfE7c064c69140e715f58d1e29FC75E5594D342E568246a4D6a3131a5974 --account ${Your starkli account path}
```