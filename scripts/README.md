## Generate Merkle json

Generate merkle json file which can be retrieved by frontend as input parameter for minting nft.

```
cd scripts
```

```
node --loader ts-node/esm src/generate_merkle_json.ts
```

## Generate metadata json

Generate metadata json file which is used as part of the NFT when shown on nft marketplace.

```
cd scripts
```

```
node --loader ts-node/esm src/generate_metadata_json.ts
```

## Generate merkle root hash and proof


Generate ec stark signature and output

```
cd scripts
```

```
node --loader ts-node/esm src/merkle_stark.ts
```

## Generate ec stark


Generate ec stark signature and output

```
cd scripts
```

```
node --loader ts-node/esm src/ec_stark.ts
```