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
use openzeppelin::token::erc721::ERC721;
use alexandria_data_structures::merkle_tree::{
    Hasher, MerkleTree, pedersen::PedersenHasherImpl, MerkleTreeTrait, MerkleTreeImpl
};
use openzeppelin::token::erc721::interface::{
    IERC721, IERC721CamelOnly, IERC721Metadata, IERC721MetadataCamelOnly, IERC721Dispatcher,
    IERC721DispatcherTrait
};
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
    let mut merkle_tree: MerkleTree<Hasher> = MerkleTreeTrait::new();
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
    return starknet::contract_address_const::<0x35742331cbd91fc4873c469ba52939db909efcf46b9c28e82d1baaa7078a6d6>();
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
#[should_panic(expected: ('merkle root not set', 'ENTRYPOINT_FAILED',))]
fn test_mint_whitelist_no_set_merkle_root() {
    let caller = OWNER();
    starknet::testing::set_contract_address(caller);
    let mut jedi_contract_address = setup_dispatcher(URI());
    let mut jedi_nft = IJediNFTDispatcher { contract_address: jedi_contract_address };
    let mut erc721 = IERC721Dispatcher { contract_address: jedi_contract_address };

    // data of 10,1,L1PW,10,406872312314,0,76769,[0x66e7169b0731c8eb021cf5e09a803d62a66cc01cdb42bedfbea9de90858b9e4, 0xb0e5a3fb482c4fa849ccf1b5df658765fc4d7c5098fe3d8a2b43d0f1af6edd, 0x923dca6d5438f31c9e1cc1b2cd08a5aebf79842a382cabb76ae4ed832d97be, 0x4081183b5464d63894bbd8769e6ffef977fe9669469d0e2a0e6b4d2d8298f36, 0x6cdf09187175a80b6cc4ad8dad44af7d65d5b22f51d3dd742a9bf2ce85d455b, 0x5b6eba0c456c58833fcb4be518d20dc6e2dc29079e2b61a5b1e10cbf9e46bfc, 0x25c2ab011f0339dfa5c810b6cd6daff0ccd78afc88758da6af890db7dd2f0aa, 0x7ff636821e88f5f9943a306579f7c5ea202402155ad89d9e8fc542eab34619f, 0x45c13f5d5211898c9bd9b5560a4d76a6ce7c36804e2eac3f8baa1197e7b12e7, 0xb37a422d6d1694a629eaf08ec7d81ee2c009655cae64000bf1ccf8261422f0, 0x4c5a9d1aeb7a93407504beec91e7256bbb8fa071bac32bc69bce019d471483e, 0x36bae232461bfecb202be7906fe406b7baaeae4ca4150cbb38d7c7a8adc2070, 0x30a1705efb2527295d44157202795133ba729dfb3e16ce9a63b0ecf90433e0b, 0x124bcbc7f61601e434e5fc5181982f9cc9441d77f9da68ac3bd5a17ecf0ce26, 0x4243240599db68c30370219713a8f9b0f3c978856082a0c6f20aa945ff9cf, 0x5561116dfd3500403473bcff6d291debdcc45b72ad44c4491a1e1b75b8c4e7f, 0x7b4427387cb6c04cdcb0f348186bd35ee678cd4b20598e66ecb73a5e906e1a5]

    let token_id = 10_u128;
    let task_id = 1_u128;
    let name = 'L1PW';
    let rank = 10;
    let score = 406872312314;
    let level = 0;
    let total_eligible_users = 76769;
    let token_metadata = TokenMetadata {
        task_id: task_id,
        name: name,
        rank: rank,
        score: score,
        level: level,
        total_eligible_users: total_eligible_users,
    };
    let mut proof = ArrayTrait::new();
    proof.append(0x66e7169b0731c8eb021cf5e09a803d62a66cc01cdb42bedfbea9de90858b9e4);
    proof.append(0xb0e5a3fb482c4fa849ccf1b5df658765fc4d7c5098fe3d8a2b43d0f1af6edd);
    proof.append(0x923dca6d5438f31c9e1cc1b2cd08a5aebf79842a382cabb76ae4ed832d97be);
    proof.append(0x4081183b5464d63894bbd8769e6ffef977fe9669469d0e2a0e6b4d2d8298f36);
    proof.append(0x6cdf09187175a80b6cc4ad8dad44af7d65d5b22f51d3dd742a9bf2ce85d455b);
    proof.append(0x5b6eba0c456c58833fcb4be518d20dc6e2dc29079e2b61a5b1e10cbf9e46bfc);
    proof.append(0x25c2ab011f0339dfa5c810b6cd6daff0ccd78afc88758da6af890db7dd2f0aa);
    proof.append(0x7ff636821e88f5f9943a306579f7c5ea202402155ad89d9e8fc542eab34619f);
    proof.append(0x45c13f5d5211898c9bd9b5560a4d76a6ce7c36804e2eac3f8baa1197e7b12e7);
    proof.append(0xb37a422d6d1694a629eaf08ec7d81ee2c009655cae64000bf1ccf8261422f0);
    proof.append(0x4c5a9d1aeb7a93407504beec91e7256bbb8fa071bac32bc69bce019d471483e);
    proof.append(0x36bae232461bfecb202be7906fe406b7baaeae4ca4150cbb38d7c7a8adc2070);
    proof.append(0x30a1705efb2527295d44157202795133ba729dfb3e16ce9a63b0ecf90433e0b);
    proof.append(0x124bcbc7f61601e434e5fc5181982f9cc9441d77f9da68ac3bd5a17ecf0ce26);
    proof.append(0x4243240599db68c30370219713a8f9b0f3c978856082a0c6f20aa945ff9cf);
    proof.append(0x5561116dfd3500403473bcff6d291debdcc45b72ad44c4491a1e1b75b8c4e7f);
    proof.append(0x7b4427387cb6c04cdcb0f348186bd35ee678cd4b20598e66ecb73a5e906e1a5);

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
    let mut erc721 = IERC721Dispatcher { contract_address: jedi_contract_address };

    let token_id = 10_u128;
    let task_id = 1_u128;
    let name = 'L1PW';
    let rank = 10;
    let score = 406872312314;
    let level = 0;
    let total_eligible_users = 76769;
    let token_metadata = TokenMetadata {
        task_id: task_id,
        name: name,
        rank: rank,
        score: score,
        level: level,
        total_eligible_users: total_eligible_users,
    };
    jedi_nft
        .set_merkle_root(
            task_id, 0x364416474922e527188122afdfa40a0eb0ed046369ce6a2365dac91113fbee0
        );
    let mut proof = ArrayTrait::new();
    proof.append(0x66e7169b0731c8eb021cf5e09a803d62a66cc01cdb42bedfbea9de90858b9e4);
    proof.append(0xb0e5a3fb482c4fa849ccf1b5df658765fc4d7c5098fe3d8a2b43d0f1af6edd);
    proof.append(0x923dca6d5438f31c9e1cc1b2cd08a5aebf79842a382cabb76ae4ed832d97be);
    proof.append(0x4081183b5464d63894bbd8769e6ffef977fe9669469d0e2a0e6b4d2d8298f36);
    proof.append(0x6cdf09187175a80b6cc4ad8dad44af7d65d5b22f51d3dd742a9bf2ce85d455b);
    proof.append(0x5b6eba0c456c58833fcb4be518d20dc6e2dc29079e2b61a5b1e10cbf9e46bfc);
    proof.append(0x25c2ab011f0339dfa5c810b6cd6daff0ccd78afc88758da6af890db7dd2f0aa);
    proof.append(0x7ff636821e88f5f9943a306579f7c5ea202402155ad89d9e8fc542eab34619f);
    proof.append(0x45c13f5d5211898c9bd9b5560a4d76a6ce7c36804e2eac3f8baa1197e7b12e7);
    proof.append(0xb37a422d6d1694a629eaf08ec7d81ee2c009655cae64000bf1ccf8261422f0);
    proof.append(0x4c5a9d1aeb7a93407504beec91e7256bbb8fa071bac32bc69bce019d471483e);
    proof.append(0x36bae232461bfecb202be7906fe406b7baaeae4ca4150cbb38d7c7a8adc2070);
    proof.append(0x30a1705efb2527295d44157202795133ba729dfb3e16ce9a63b0ecf90433e0b);
    proof.append(0x124bcbc7f61601e434e5fc5181982f9cc9441d77f9da68ac3bd5a17ecf0ce26);
    proof.append(0x4243240599db68c30370219713a8f9b0f3c978856082a0c6f20aa945ff9cf);
    proof.append(0x5561116dfd3500403473bcff6d291debdcc45b72ad44c4491a1e1b75b8c4e7f);
    proof.append(0x7b4427387cb6c04cdcb0f348186bd35ee678cd4b20598e66ecb73a5e906e1a5);

    jedi_nft.mint_whitelist(token_id.into(), proof, token_metadata);
    assert(erc721.owner_of(token_id.into()) == caller, 'owner_of failed');
    assert(jedi_nft.is_completed(task_id, caller) == true, 'is_minted failed');
}

#[test]
#[should_panic(expected: ('ALREADY_MINTED', 'ENTRYPOINT_FAILED',))]
#[available_gas(20000000)]
fn test_mint_whitelist_already_mint() {
    let caller = OWNER();
    starknet::testing::set_contract_address(caller);
    let mut jedi_contract_address = setup_dispatcher(URI());
    let mut jedi_nft = IJediNFTDispatcher { contract_address: jedi_contract_address };
    let mut erc721 = IERC721Dispatcher { contract_address: jedi_contract_address };

    let token_id = 10_u128;
    let task_id = 1_u128;
    let name = 'L1PW';
    let rank = 10;
    let score = 406872312314;
    let level = 0;
    let total_eligible_users = 76769;
    let token_metadata = TokenMetadata {
        task_id: task_id,
        name: name,
        rank: rank,
        score: score,
        level: level,
        total_eligible_users: total_eligible_users,
    };
    jedi_nft
        .set_merkle_root(
            task_id, 0x364416474922e527188122afdfa40a0eb0ed046369ce6a2365dac91113fbee0
        );
    let mut proof = ArrayTrait::new();
    proof.append(0x66e7169b0731c8eb021cf5e09a803d62a66cc01cdb42bedfbea9de90858b9e4);
    proof.append(0xb0e5a3fb482c4fa849ccf1b5df658765fc4d7c5098fe3d8a2b43d0f1af6edd);
    proof.append(0x923dca6d5438f31c9e1cc1b2cd08a5aebf79842a382cabb76ae4ed832d97be);
    proof.append(0x4081183b5464d63894bbd8769e6ffef977fe9669469d0e2a0e6b4d2d8298f36);
    proof.append(0x6cdf09187175a80b6cc4ad8dad44af7d65d5b22f51d3dd742a9bf2ce85d455b);
    proof.append(0x5b6eba0c456c58833fcb4be518d20dc6e2dc29079e2b61a5b1e10cbf9e46bfc);
    proof.append(0x25c2ab011f0339dfa5c810b6cd6daff0ccd78afc88758da6af890db7dd2f0aa);
    proof.append(0x7ff636821e88f5f9943a306579f7c5ea202402155ad89d9e8fc542eab34619f);
    proof.append(0x45c13f5d5211898c9bd9b5560a4d76a6ce7c36804e2eac3f8baa1197e7b12e7);
    proof.append(0xb37a422d6d1694a629eaf08ec7d81ee2c009655cae64000bf1ccf8261422f0);
    proof.append(0x4c5a9d1aeb7a93407504beec91e7256bbb8fa071bac32bc69bce019d471483e);
    proof.append(0x36bae232461bfecb202be7906fe406b7baaeae4ca4150cbb38d7c7a8adc2070);
    proof.append(0x30a1705efb2527295d44157202795133ba729dfb3e16ce9a63b0ecf90433e0b);
    proof.append(0x124bcbc7f61601e434e5fc5181982f9cc9441d77f9da68ac3bd5a17ecf0ce26);
    proof.append(0x4243240599db68c30370219713a8f9b0f3c978856082a0c6f20aa945ff9cf);
    proof.append(0x5561116dfd3500403473bcff6d291debdcc45b72ad44c4491a1e1b75b8c4e7f);
    proof.append(0x7b4427387cb6c04cdcb0f348186bd35ee678cd4b20598e66ecb73a5e906e1a5);
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
    let mut erc721 = IERC721Dispatcher { contract_address: jedi_contract_address };


    jedi_nft
        .set_mint_sig_pub_key(0x33f45f07e1bd1a51b45fc24ec8c8c9908db9e42191be9e169bfcac0c0d99745);
    let token_id = 10_u128;
    let task_id = 1_u128;
    let name = 'L1PW';
    let rank = 10;
    let score = 406872312314;
    let level = 0;
    let total_eligible_users = 76769;
    let token_metadata = TokenMetadata {
        task_id: task_id,
        name: name,
        rank: rank,
        score: score,
        level: level,
        total_eligible_users: total_eligible_users,
    };

    let mut sig = ArrayTrait::new();
    sig.append(0x107d74eef104e85493aaef56a0a40c315e1ffc383ce67c26490880e170969b7);
    sig.append(0x5f09812077d2578a3609edf7fc914a1c1ea62848193bff4382b06c7360662e);
    jedi_nft.mint_sig(token_id, sig.span(), token_metadata);
}

#[test]
#[should_panic(expected: ('ALREADY_MINTED', 'ENTRYPOINT_FAILED',))]
#[available_gas(20000000)]
fn test_mint_sig_already_mint() {
    let caller = OWNER();
    starknet::testing::set_contract_address(caller);
    let mut jedi_contract_address = setup_dispatcher(URI());
    let mut jedi_nft = IJediNFTDispatcher { contract_address: jedi_contract_address };
    let mut erc721 = IERC721Dispatcher { contract_address: jedi_contract_address };


    jedi_nft
        .set_mint_sig_pub_key(0x33f45f07e1bd1a51b45fc24ec8c8c9908db9e42191be9e169bfcac0c0d99745);
    let token_id = 10_u128;
    let task_id = 1_u128;
    let name = 'L1PW';
    let rank = 10;
    let score = 406872312314;
    let level = 0;
    let total_eligible_users = 76769;
    let token_metadata = TokenMetadata {
        task_id: task_id,
        name: name,
        rank: rank,
        score: score,
        level: level,
        total_eligible_users: total_eligible_users,
    };

    let mut sig = ArrayTrait::new();
    sig.append(0x107d74eef104e85493aaef56a0a40c315e1ffc383ce67c26490880e170969b7);
    sig.append(0x5f09812077d2578a3609edf7fc914a1c1ea62848193bff4382b06c7360662e);
    jedi_nft.mint_sig(token_id, sig.span(), token_metadata);

    jedi_nft.mint_sig(token_id, sig.span(), token_metadata);
}

#[test]
#[should_panic(expected: ('MINT_SIG_PUBLIC_KEY_NOT_SET', 'ENTRYPOINT_FAILED',))]
#[available_gas(20000000)]
fn test_mint_sig_not_set_pubkey() {
    let caller = OWNER();
    starknet::testing::set_contract_address(caller);
    let mut jedi_contract_address = setup_dispatcher(URI());
    let mut jedi_nft = IJediNFTDispatcher { contract_address: jedi_contract_address };
    let mut erc721 = IERC721Dispatcher { contract_address: jedi_contract_address };


    let token_id = 10_u128;
    let task_id = 1_u128;
    let name = 'L1PW';
    let rank = 10;
    let score = 406872312314;
    let level = 0;
    let total_eligible_users = 76769;
    let token_metadata = TokenMetadata {
        task_id: task_id,
        name: name,
        rank: rank,
        score: score,
        level: level,
        total_eligible_users: total_eligible_users,
    };

    let mut sig = ArrayTrait::new();
    sig.append(0x107d74eef104e85493aaef56a0a40c315e1ffc383ce67c26490880e170969b7);
    sig.append(0x5f09812077d2578a3609edf7fc914a1c1ea62848193bff4382b06c7360662e);
    jedi_nft.mint_sig(token_id, sig.span(), token_metadata);
}
