use jedinft::jedi_nft::IJediNFTDispatcherTrait;

use core::serde::Serde;
use clone::Clone;
use starknet::testing;
use array::{ArrayTrait, SpanTrait, SpanCopy, SpanSerde};
use traits::Into;
use zeroable::Zeroable;
use integer::u256_from_felt252;
use debug::PrintTrait;
use starknet::ContractAddress;
use core::result::ResultTrait;
use option::OptionTrait;
use starknet::class_hash::Felt252TryIntoClassHash;
use traits::TryInto;

use jedinft::jedi_nft::{IJediNFT, IJediNFTDispatcher, JediNFT, TokenMetadata};
use rules_erc721::erc721::erc721::{ERC721ABI, ERC721ABIDispatcher, ERC721ABIDispatcherTrait};
use alexandria::data_structures::merkle_tree::{MerkleTree, MerkleTreeTrait};
use hash::LegacyHash;


#[test]
#[available_gas(10000000)]
fn test_verify_alexandria() {
    let mut proof = ArrayTrait::<felt252>::new();
    proof.append(2);
    proof.append(0x262697b88544f733e5c6907c3e1763131e9f14c51ee7951258abbfb29415fbf);
    proof.append(0x5d768cbfb58b59a888e5ae9fe5d55d83b9b0c1d9365e28e3fe4849f8135ddc3);
    let leaf: felt252 = 1;
    let root: felt252 = 0x329d5b51e352537e8424bfd85b34d0f30b77d213e9b09e2976e6f6374ecb59;
    let mut merkle_tree = MerkleTreeTrait::new();
    let result = merkle_tree.verify(root, leaf, proof.span());
    assert(result == true, 'wrong result');
}

fn URI() -> Span<felt252> {
    let mut uri = ArrayTrait::new();

    uri.append(111);
    uri.append(222);
    uri.append(333);

    uri.span()
}

fn OWNER() -> ContractAddress {
    return starknet::contract_address_const::<0x0138EfE7c064c69140e715f58d1e29FC75E5594D342E568246a4D6a3131a5974>();
}

fn setup_dispatcher(uri: Span<felt252>) -> ContractAddress {
    let mut calldata = ArrayTrait::new();

    'Jedi NFT'.serialize(ref output: calldata);
    'a'.serialize(ref output: calldata);
    uri.serialize(ref output: calldata);
    uri.serialize(ref output: calldata);
    OWNER().serialize(ref output: calldata);

    let (address, _) = starknet::deploy_syscall(
        JediNFT::TEST_CLASS_HASH.try_into().unwrap(), 0, calldata.span(), false
    )
        .unwrap();

    address
}

// #[test]
// #[available_gas(20000000)]
// #[should_panic(expected: ('MERKLE_ROOT_NOT_SET', 'ENTRYPOINT_FAILED', ))]
// fn test_mint_whitelist_no_set_merkle_root() {
//     let caller = OWNER();
//     starknet::testing::set_contract_address(caller);
//     let mut jedi_contract_address = setup_dispatcher(URI());
//     let mut jedi_nft = IJediNFTDispatcher { contract_address: jedi_contract_address };
//     let mut erc721 = ERC721ABIDispatcher { contract_address: jedi_contract_address };

//     assert(erc721.name() == 'Jedi NFT', 'name failed');
//     let task_id = 1_u128;
//     let mut proof = ArrayTrait::new();
//     proof.append(0x4992bea106fe44959bbbed1e326a2d96ec88f0fba38efe4b2d8a3e79c965c2e);
//     proof.append(0x4b5d5cbbfd24d8ba097e9e2c724501cd3a39b6ed3136b3dffa6de7e55c89dc9);
//     proof.append(0x2f5ba2761c55521b1141b05a0c21b5b80e2e9e592e9f042242e06fc0b2cb10b);
//     let token_id = 3_u128;
//     jedi_nft.mint_whitelist(task_id, token_id, proof);
//     assert(erc721.owner_of(token_id.into()) == caller, 'owner_of failed');
//     assert(jedi_nft.is_completed(task_id, caller) == true, 'is_minted failed');
// }

#[test]
#[available_gas(20000000)]
fn test_mint_whitelist() {
    let caller = OWNER();
    starknet::testing::set_contract_address(caller);
    let mut jedi_contract_address = setup_dispatcher(URI());
    let mut jedi_nft = IJediNFTDispatcher { contract_address: jedi_contract_address };
    let mut erc721 = ERC721ABIDispatcher { contract_address: jedi_contract_address };

    assert(erc721.name() == 'Jedi NFT', 'name failed');
    let token_id = 1_u128;
    let task_id = 1_u128;
    let name = 'L1P1';
    let rank = 10;
    let score = 12000;
    let percentile = 1;
    let level = 6;
    name.print();
    let total_eligable_users = 120000;
    let token_metadata = TokenMetadata {
        task_id: task_id,
        name: name,
        rank: rank,
        score: score,
        percentile: percentile,
        level: level,
        total_eligable_users: total_eligable_users,
    };
    jedi_nft.set_merkle_root(task_id, 0x1b1e0c3f4a87d1c6829cd8dfce486a42e6cfcaf119f8eaf2aa3e34cb646a5a);
    let mut proof = ArrayTrait::new();
    proof.append(0x4a9c765a45a96a8ddc6afb1a8d086d14dd5c3a54ccbeea049969101ebe59ad1);
    proof.append(0x63edeac7f0773edfa49f70380c79c18c72fc065a398b813c4c658812c16b3c6);
    proof.append(0x2df262d0827ea289ff0ae82047e8c99bc35d7e3deb383b8b28bae51f38efec3);
    jedi_nft.mint_whitelist(token_id.into(), proof, token_metadata);
    assert(erc721.owner_of(token_id.into()) == caller, 'owner_of failed');
    assert(jedi_nft.is_completed(task_id, caller) == true, 'is_minted failed');
}

// #[test]
// #[should_panic(expected: ('ALREADY_MINTED', 'ENTRYPOINT_FAILED', ))]
// #[available_gas(20000000)]
// fn test_mint_whitelist_already_mint() {
//     let caller = OWNER();
//     starknet::testing::set_contract_address(caller);
//     let mut jedi_contract_address = setup_dispatcher(URI());
//     let mut jedi_nft = IJediNFTDispatcher { contract_address: jedi_contract_address };
//     let mut erc721 = ERC721ABIDispatcher { contract_address: jedi_contract_address };

//     assert(erc721.name() == 'Jedi NFT', 'name failed');
//     let task_id = 1_u128;
//     jedi_nft.set_merkle_root(task_id, 0x4debc46eee6fc815ece0273d8895ecaaaff3e6c062323042500fda4843b41d7);
//     let mut proof = ArrayTrait::new();
//     proof.append(0x4992bea106fe44959bbbed1e326a2d96ec88f0fba38efe4b2d8a3e79c965c2e);
//     proof.append(0x4b5d5cbbfd24d8ba097e9e2c724501cd3a39b6ed3136b3dffa6de7e55c89dc9);
//     proof.append(0x2f5ba2761c55521b1141b05a0c21b5b80e2e9e592e9f042242e06fc0b2cb10b);
//     let token_id = 3_u128;
//     jedi_nft.mint_whitelist(task_id, token_id, proof.clone());
//     assert(erc721.owner_of(token_id.into()) == caller, 'owner_of failed');
//     assert(jedi_nft.is_completed(task_id, caller) == true, 'is_minted failed');
//     jedi_nft.mint_whitelist(task_id, token_id, proof);
// }

// #[test]
// #[available_gas(20000000)]
// fn test_mint_sig() {
//     let caller = OWNER();
//     starknet::testing::set_contract_address(caller);
//     let mut jedi_contract_address = setup_dispatcher(URI());
//     let mut jedi_nft = IJediNFTDispatcher { contract_address: jedi_contract_address };
//     let mut erc721 = ERC721ABIDispatcher { contract_address: jedi_contract_address };

//     assert(erc721.name() == 'Jedi NFT', 'name failed');

//     jedi_nft.set_mint_sig_pub_key(0x33f45f07e1bd1a51b45fc24ec8c8c9908db9e42191be9e169bfcac0c0d99745);
//     let task_id = 1_u128;

//     let token_id = 1024_u128;
//     let mut sig = ArrayTrait::new();
//     sig.append(0x1a6c3b29d4b286e0fcda56ab4061aadf1ccf64337948ee97f10488ab82942ef);
//     sig.append(0x7ff0da732040f1cb3dc529952c5628a85c11c014d6932a9694cb902d5957e39);
//     jedi_nft.mint_sig(task_id, token_id, sig.span());
// }
