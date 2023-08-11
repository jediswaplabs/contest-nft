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
use alexandria_data_structures::merkle_tree::{MerkleTree, MerkleTreeTrait};
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

#[test]
#[available_gas(20000000)]
#[should_panic(expected: ('merkle root not set', 'ENTRYPOINT_FAILED', ))]
fn test_mint_whitelist_no_set_merkle_root() {
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
    let total_eligible_users = 120000;
    let token_metadata = TokenMetadata {
        task_id: task_id,
        name: name,
        rank: rank,
        score: score,
        percentile: percentile,
        level: level,
        total_eligible_users: total_eligible_users,
    };
    let mut proof = ArrayTrait::new();
    proof.append(0x4a9c765a45a96a8ddc6afb1a8d086d14dd5c3a54ccbeea049969101ebe59ad1);
    proof.append(0x63edeac7f0773edfa49f70380c79c18c72fc065a398b813c4c658812c16b3c6);
    proof.append(0x2df262d0827ea289ff0ae82047e8c99bc35d7e3deb383b8b28bae51f38efec3);
    jedi_nft.mint_whitelist(token_id.into(), proof, token_metadata);
    assert(erc721.owner_of(token_id.into()) == caller, 'owner_of failed');
    assert(jedi_nft.is_completed(task_id, caller) == true, 'is_minted failed');
}

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
    let total_eligible_users = 120000;
    let token_metadata = TokenMetadata {
        task_id: task_id,
        name: name,
        rank: rank,
        score: score,
        percentile: percentile,
        level: level,
        total_eligible_users: total_eligible_users,
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

#[test]
#[should_panic(expected: ('ALREADY_MINTED', 'ENTRYPOINT_FAILED', ))]
#[available_gas(20000000)]
fn test_mint_whitelist_already_mint() {
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
    let total_eligible_users = 120000;
    let token_metadata = TokenMetadata {
        task_id: task_id,
        name: name,
        rank: rank,
        score: score,
        percentile: percentile,
        level: level,
        total_eligible_users: total_eligible_users,
    };
    jedi_nft.set_merkle_root(task_id, 0x1b1e0c3f4a87d1c6829cd8dfce486a42e6cfcaf119f8eaf2aa3e34cb646a5a);
    let mut proof = ArrayTrait::new();
    proof.append(0x4a9c765a45a96a8ddc6afb1a8d086d14dd5c3a54ccbeea049969101ebe59ad1);
    proof.append(0x63edeac7f0773edfa49f70380c79c18c72fc065a398b813c4c658812c16b3c6);
    proof.append(0x2df262d0827ea289ff0ae82047e8c99bc35d7e3deb383b8b28bae51f38efec3);
    jedi_nft.mint_whitelist(token_id.into(), proof.clone(), token_metadata);
    assert(erc721.owner_of(token_id.into()) == caller, 'owner_of failed');
    assert(jedi_nft.is_completed(task_id, caller) == true, 'is_minted failed');
    jedi_nft.mint_whitelist(token_id.into(), proof.clone(), token_metadata);
}

#[test]
#[available_gas(20000000)]
fn test_mint_sig() {
    let caller = OWNER();
    starknet::testing::set_contract_address(caller);
    let mut jedi_contract_address = setup_dispatcher(URI());
    let mut jedi_nft = IJediNFTDispatcher { contract_address: jedi_contract_address };
    let mut erc721 = ERC721ABIDispatcher { contract_address: jedi_contract_address };

    assert(erc721.name() == 'Jedi NFT', 'name failed');

    jedi_nft.set_mint_sig_pub_key(0x33f45f07e1bd1a51b45fc24ec8c8c9908db9e42191be9e169bfcac0c0d99745);
    let token_id = 1_u128;
    let task_id = 1_u128;
    let name = 'L1P1';
    let rank = 10;
    let score = 12000;
    let percentile = 1;
    let level = 6;
    let total_eligible_users = 120000;
    let token_metadata = TokenMetadata {
        task_id: task_id,
        name: name,
        rank: rank,
        score: score,
        percentile: percentile,
        level: level,
        total_eligible_users: total_eligible_users,
    };
    
    let mut sig = ArrayTrait::new();
    sig.append(0x3f65e72fe5b1f54277ecf22f54ecf69132700bf41f6918457457d5deab6577c);
    sig.append(0x672cc7e8839ce82b6887dd64df8f486a228fe418a5b4eaeab50dd588ce5a94c);
    jedi_nft.mint_sig(token_id, sig.span(), token_metadata);
}

#[test]
#[should_panic(expected: ('ALREADY_MINTED', 'ENTRYPOINT_FAILED', ))]
#[available_gas(20000000)]
fn test_mint_sig_already_mint() {
    let caller = OWNER();
    starknet::testing::set_contract_address(caller);
    let mut jedi_contract_address = setup_dispatcher(URI());
    let mut jedi_nft = IJediNFTDispatcher { contract_address: jedi_contract_address };
    let mut erc721 = ERC721ABIDispatcher { contract_address: jedi_contract_address };

    assert(erc721.name() == 'Jedi NFT', 'name failed');

    jedi_nft.set_mint_sig_pub_key(0x33f45f07e1bd1a51b45fc24ec8c8c9908db9e42191be9e169bfcac0c0d99745);
    let token_id = 1_u128;
    let task_id = 1_u128;
    let name = 'L1P1';
    let rank = 10;
    let score = 12000;
    let percentile = 1;
    let level = 6;
    let total_eligible_users = 120000;
    let token_metadata = TokenMetadata {
        task_id: task_id,
        name: name,
        rank: rank,
        score: score,
        percentile: percentile,
        level: level,
        total_eligible_users: total_eligible_users,
    };
    
    let mut sig = ArrayTrait::new();
    sig.append(0x3f65e72fe5b1f54277ecf22f54ecf69132700bf41f6918457457d5deab6577c);
    sig.append(0x672cc7e8839ce82b6887dd64df8f486a228fe418a5b4eaeab50dd588ce5a94c);
    jedi_nft.mint_sig(token_id, sig.span(), token_metadata);

    jedi_nft.mint_sig(token_id, sig.span(), token_metadata);
}

#[test]
#[should_panic(expected: ('MINT_SIG_PUBLIC_KEY_NOT_SET', 'ENTRYPOINT_FAILED', ))]
#[available_gas(20000000)]
fn test_mint_sig_not_set_pubkey() {
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
    let total_eligible_users = 120000;
    let token_metadata = TokenMetadata {
        task_id: task_id,
        name: name,
        rank: rank,
        score: score,
        percentile: percentile,
        level: level,
        total_eligible_users: total_eligible_users,
    };
    
    let mut sig = ArrayTrait::new();
    sig.append(0x3f65e72fe5b1f54277ecf22f54ecf69132700bf41f6918457457d5deab6577c);
    sig.append(0x672cc7e8839ce82b6887dd64df8f486a228fe418a5b4eaeab50dd588ce5a94c);
    jedi_nft.mint_sig(token_id, sig.span(), token_metadata);
}