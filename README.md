# contest-nft

Jediswap nft contract for LP contest.


Greatly powered by [ruleslab's code](https://github.com/ruleslabs/starknet-erc721.git) and [alexandria](https://github.com/keep-starknet-strange/alexandria)

# Deploy

## Scarb version

using scarb version
```
0.5.1
```

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
starkli deploy ${class-hash} str:jedi-nft str:sym 5 str:https://ipfs.io str:/ipfs/QmWTqq str:LG7XE1y2EfB5o str:SiV9DQy2gWV5 str:PraUiH98upSDZsK/  1 str:https://b.com/ 0x0138EfE7c064c69140e715f58d1e29FC75E5594D342E568246a4D6a3131a5974 --account ${Your starkli account path}
```