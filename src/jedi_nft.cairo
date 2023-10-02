use core::clone::Clone;
use core::traits::TryInto;
use array::ArrayTrait;
use starknet::{Store, ContractAddress};

#[derive(Copy, Drop, Serde, PartialEq, starknet::Store)]
struct TokenMetadata {
    task_id: u128,
    name: felt252,
    rank: u128,
    score: u128,
    level: u8,
    total_eligible_users: u128,
}

#[starknet::interface]
trait IJediNFT<TContractState> {
    fn tokenURI(self: @TContractState, token_id: u256) -> Span<felt252>;

    fn contractURI(self: @TContractState) -> Span<felt252>;

    fn is_completed(self: @TContractState, task_id: u128, address: ContractAddress) -> bool;

    fn set_merkle_root(ref self: TContractState, task_id: u128, merkle_root: felt252);

    fn get_merkle_root(self: @TContractState, task_id: u128) -> felt252;

    fn set_mint_sig_pub_key(ref self: TContractState, mint_sig_public_key: felt252);

    fn get_mint_sig_pub_key(self: @TContractState) -> felt252;

    fn mint_sig(
        ref self: TContractState,
        token_id: u128,
        signature: Span<felt252>,
        token_metadata: TokenMetadata
    );

    fn mint_whitelist(
        ref self: TContractState,
        token_id: u128,
        proof: Array<felt252>,
        token_metadata: TokenMetadata
    );

    fn get_token_metadata(self: @TContractState, token_id: u128) -> TokenMetadata;
}

#[starknet::contract]
mod JediNFT {
    use option::OptionTrait;
    use traits::{Into, TryInto, Default, Felt252DictValue};
    use array::{SpanSerde, ArrayTrait};
    use clone::Clone;
    use array::SpanTrait;
    use box::BoxTrait;
    use ecdsa::check_ecdsa_signature;
    use hash::LegacyHash;
    use zeroable::Zeroable;
    use openzeppelin::token::erc721::ERC721;
    use openzeppelin::token::erc721::ERC721::InternalTrait as ERC721InternalTrait;
    use openzeppelin::introspection::interface::ISRC5;
    use openzeppelin::introspection::interface::ISRC5Camel;
    use openzeppelin::token::erc721::interface::{
        IERC721, IERC721CamelOnly, IERC721Metadata, IERC721MetadataCamelOnly
    };
    use jedinft::access::ownable::{Ownable, IOwnable};
    use jedinft::access::ownable::Ownable::{
        ModifierTrait as OwnableModifierTrait, InternalTrait as OwnableInternalTrait,
    };
    use starknet::ContractAddress;
    use starknet::get_caller_address;
    use alexandria_data_structures::merkle_tree::{
        Hasher, MerkleTree, pedersen::PedersenHasherImpl, MerkleTreeTrait, MerkleTreeImpl
    };
    use jedinft::storage::StoreSpanFelt252;
    use super::TokenMetadata;
    use rules_utils::introspection::src5::SRC5;

    const IERC721_ID_LEGACY: felt252 = 0x80ac58cd;
    const IERC721_METADATA_ID_LEGACY: felt252 = 0x5b5e139f;
    const IERC721_RECEIVER_ID_LEGACY: felt252 = 0x150b7a02;


    #[storage]
    struct Storage {
        _completed_tasks: LegacyMap::<(u128, ContractAddress), bool>,
        _merkle_roots: LegacyMap::<u128, felt252>,
        _uri: Span<felt252>,
        _contract_uri: Span<felt252>,
        _mint_sig_public_key: felt252,
        // (token_id) -> (task_id, name, rank, score, level, total_eligible_users)
        _token_metadata: LegacyMap::<u128, TokenMetadata>,
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        Transfer: Transfer,
        Approval: Approval,
        ApprovalForAll: ApprovalForAll,
    }

    #[derive(Drop, starknet::Event)]
    struct Transfer {
        from_: ContractAddress,
        to: ContractAddress,
        tokenId: u256,
    }

    #[derive(Drop, starknet::Event)]
    struct Approval {
        owner: ContractAddress,
        approved: ContractAddress,
        token_id: u256,
    }

    #[derive(Drop, starknet::Event)]
    struct ApprovalForAll {
        owner: ContractAddress,
        operator: ContractAddress,
        approved: bool,
    }

    //
    // Constructor
    //

    #[constructor]
    fn constructor(
        ref self: ContractState,
        name_: felt252,
        symbol_: felt252,
        uri_: Span<felt252>,
        contract_uri: Span<felt252>,
        owner_: ContractAddress,
    ) {
        self._uri.write(uri_);
        let mut erc721_self = ERC721::unsafe_new_contract_state();
        // ERC721 init
        erc721_self.initializer(name:name_, symbol:symbol_);
        self._contract_uri.write(contract_uri);

        let mut ownable_self = Ownable::unsafe_new_contract_state();
        ownable_self._transfer_ownership(new_owner: owner_);
    }


    #[external(v0)]
    impl JediNFTImpl of super::IJediNFT<ContractState> {
        fn tokenURI(self: @ContractState, token_id: u256) -> Span<felt252> {
            let base_uri = self._uri.read();
            let new_base_uri: Array<felt252> = base_uri.snapshot.clone();
            let mut tmp =  InternalImpl::append_number_ascii(new_base_uri, token_id);
            tmp.append('.json');
            return tmp.span();
        }

        fn contractURI(self: @ContractState) -> Span<felt252> {
            return self._contract_uri.read();
        }

        fn is_completed(self: @ContractState, task_id: u128, address: ContractAddress) -> bool {
            return self._completed_tasks.read((task_id, address));
        }

        fn set_merkle_root(ref self: ContractState, task_id: u128, merkle_root: felt252) {
            self._only_owner();
            self._merkle_roots.write(task_id, merkle_root);
        }

        fn get_merkle_root(self: @ContractState, task_id: u128) -> felt252 {
            return self._merkle_roots.read(task_id);
        }

        fn mint_whitelist(
            ref self: ContractState,
            token_id: u128,
            proof: Array<felt252>,
            token_metadata: TokenMetadata
        ) {
            let caller = get_caller_address();
            let merkle_root = self._merkle_roots.read(token_metadata.task_id);
            assert(merkle_root != 0, 'merkle root not set');
            let mut merkle_tree: MerkleTree<Hasher> = MerkleTreeTrait::new();
            let mut leaf: felt252 = merkle_tree.hasher.hash(caller.into(), token_id.into());
            leaf = merkle_tree.hasher.hash(leaf, token_metadata.task_id.into());
            leaf = merkle_tree.hasher.hash(leaf, token_metadata.name.into());
            leaf = merkle_tree.hasher.hash(leaf, token_metadata.rank.into());
            leaf = merkle_tree.hasher.hash(leaf, token_metadata.score.into());
            leaf = merkle_tree.hasher.hash(leaf, token_metadata.level.into());
            leaf = merkle_tree.hasher.hash(leaf, token_metadata.total_eligible_users.into());

            let result = merkle_tree.verify(merkle_root, leaf, proof.span());
            assert(result == true, 'verify failed');

            self._token_metadata.write(token_id, token_metadata);
            let is_minted = self._completed_tasks.read((token_metadata.task_id, caller));
            assert(!is_minted, 'ALREADY_MINTED');
            self._completed_tasks.write((token_metadata.task_id, caller), true);
            let mut erc721_self = ERC721::unsafe_new_contract_state();
            erc721_self._mint(to: caller, token_id: token_id.into());
        }

        fn get_token_metadata(self: @ContractState, token_id: u128) -> TokenMetadata {
            return self._token_metadata.read(token_id);
        }

        fn set_mint_sig_pub_key(ref self: ContractState, mint_sig_public_key: felt252) {
            self._only_owner();
            self._mint_sig_public_key.write(mint_sig_public_key);
        }

        fn get_mint_sig_pub_key(self: @ContractState) -> felt252 {
            return self._mint_sig_public_key.read();
        }

        fn mint_sig(
            ref self: ContractState,
            token_id: u128,
            signature: Span<felt252>,
            token_metadata: TokenMetadata
        ) {
            let mint_sig_public_key = self._mint_sig_public_key.read();
            assert(mint_sig_public_key != 0, 'MINT_SIG_PUBLIC_KEY_NOT_SET');
            let caller = get_caller_address();
            let mut hashed = LegacyHash::hash(caller.into(), token_id);
            hashed = LegacyHash::hash(hashed, token_metadata.task_id);
            hashed = LegacyHash::hash(hashed, token_metadata.name);
            hashed = LegacyHash::hash(hashed, token_metadata.rank);
            hashed = LegacyHash::hash(hashed, token_metadata.score);
            hashed = LegacyHash::hash(hashed, token_metadata.level);
            hashed = LegacyHash::hash(hashed, token_metadata.total_eligible_users);
            assert(signature.len() == 2_u32, 'INVALID_SIGNATURE_LENGTH');
            assert(
                check_ecdsa_signature(
                    message_hash: hashed,
                    public_key: mint_sig_public_key,
                    signature_r: *signature[0_u32],
                    signature_s: *signature[1_u32],
                ),
                'INVALID_SIGNATURE',
            );
            let is_minted = self._completed_tasks.read((token_metadata.task_id, caller));
            assert(!is_minted, 'ALREADY_MINTED');
            self._completed_tasks.write((token_metadata.task_id, caller), true);
            let mut erc721_self = ERC721::unsafe_new_contract_state();
            erc721_self._mint(to: caller, token_id: token_id.into());
        }
    }


    //
    // ERC721 ABI impl
    //

    #[external(v0)]
    impl IERC721Impl of IERC721<ContractState> {
        fn balance_of(self: @ContractState, account: ContractAddress) -> u256 {
            let erc721_self = ERC721::unsafe_new_contract_state();

            erc721_self.balance_of(:account)
        }

        fn owner_of(self: @ContractState, token_id: u256) -> ContractAddress {
            let erc721_self = ERC721::unsafe_new_contract_state();

            erc721_self.owner_of(:token_id)
        }

        fn get_approved(self: @ContractState, token_id: u256) -> ContractAddress {
            let erc721_self = ERC721::unsafe_new_contract_state();

            erc721_self.get_approved(:token_id)
        }

        fn is_approved_for_all(
            self: @ContractState, owner: ContractAddress, operator: ContractAddress
        ) -> bool {
            let erc721_self = ERC721::unsafe_new_contract_state();

            erc721_self.is_approved_for_all(:owner, :operator)
        }

        fn approve(ref self: ContractState, to: ContractAddress, token_id: u256) {
            let mut erc721_self = ERC721::unsafe_new_contract_state();

            erc721_self.approve(:to, :token_id);
        }

        fn transfer_from(
            ref self: ContractState, from: ContractAddress, to: ContractAddress, token_id: u256
        ) {
            let mut erc721_self = ERC721::unsafe_new_contract_state();

            erc721_self.transfer_from(:from, :to, :token_id);
        }

        fn safe_transfer_from(
            ref self: ContractState,
            from: ContractAddress,
            to: ContractAddress,
            token_id: u256,
            data: Span<felt252>
        ) {
            let mut erc721_self = ERC721::unsafe_new_contract_state();

            erc721_self.transfer_from(:from, :to, :token_id);
            // assert(self._check_on_erc721_received(:from, :to, :token_id, :data), 'ERC721: safe transfer failed');
        }

        fn set_approval_for_all(
            ref self: ContractState, operator: ContractAddress, approved: bool
        ) {
            let mut erc721_self = ERC721::unsafe_new_contract_state();

            erc721_self.set_approval_for_all(:operator, :approved);
        }
    }

    #[external(v0)]
    impl ISRC5Impl of ISRC5<ContractState> {
        fn supports_interface(self: @ContractState, interface_id: felt252) -> bool {
            if (
                (interface_id == IERC721_ID_LEGACY) |
                (interface_id == IERC721_METADATA_ID_LEGACY)
            ) {
                true
            } else {
                let mut erc721_self = ERC721::unsafe_new_contract_state();
                erc721_self.supports_interface(:interface_id)
            }
            
        }
    }

    #[external(v0)]
    impl ISRC5CamelImpl of ISRC5Camel<ContractState> {
        fn supportsInterface(self: @ContractState, interfaceId: felt252) -> bool {
            self.supports_interface(interface_id: interfaceId)
        }
    }

    #[external(v0)]
    impl IERC721MetadataImpl of IERC721Metadata<ContractState> {
        fn name(self: @ContractState) -> felt252 {
            let erc721_self = ERC721::unsafe_new_contract_state();

            erc721_self.name()
        }

        fn symbol(self: @ContractState) -> felt252 {
            let erc721_self = ERC721::unsafe_new_contract_state();

            erc721_self.symbol()
        }

        fn token_uri(self: @ContractState, token_id: u256) -> felt252 {
            let erc721_self = ERC721::unsafe_new_contract_state();

            erc721_self.token_uri(:token_id)
        }
    }

    #[external(v0)]
    impl JediERC721CamelImpl of IERC721CamelOnly<ContractState> {
        fn balanceOf(self: @ContractState, account: ContractAddress) -> u256 {
            IERC721::balance_of(self, account: account)
        }

        fn ownerOf(self: @ContractState, tokenId: u256) -> ContractAddress {
            IERC721::owner_of(self, token_id: tokenId)
        }

        fn getApproved(self: @ContractState, tokenId: u256) -> ContractAddress {
            IERC721::get_approved(self, token_id: tokenId)
        }

        fn isApprovedForAll(
            self: @ContractState, owner: ContractAddress, operator: ContractAddress
        ) -> bool {
            IERC721::is_approved_for_all(self, owner: owner, operator: operator)
        }

        fn transferFrom(
            ref self: ContractState, from: ContractAddress, to: ContractAddress, tokenId: u256
        ) {
            IERC721::transfer_from(ref self, :from, :to, token_id: tokenId);
        }

        fn safeTransferFrom(
            ref self: ContractState,
            from: ContractAddress,
            to: ContractAddress,
            tokenId: u256,
            data: Span<felt252>
        ) {
            IERC721::safe_transfer_from(ref self, :from, :to, token_id: tokenId, :data);
        }

        fn setApprovalForAll(ref self: ContractState, operator: ContractAddress, approved: bool) {
            IERC721::set_approval_for_all(ref self, :operator, :approved);
        }
    }

    // #[external(v0)]
    // impl IERC721MetadataCamelImpl of IERC721MetadataCamelOnly<ContractState> {
    //     fn tokenUri(self: @ContractState, tokenId: u256) -> felt252 {
    //         IERC721Metadata::token_uri(self, token_id: tokenId)
    //     }
    // }


    #[generate_trait]
    impl InternalImpl of InternalTrait {
        fn append_number_ascii(mut uri: Array<felt252>, mut number_in: u256) -> Array<felt252> {
            // TODO: replace with u256 divide once it's implemented on network
            let mut number: u128 = number_in.try_into().unwrap();
            let mut tmpArray: Array<felt252> = ArrayTrait::new();
            loop {
                if number == 0 {
                    break;
                }
                let digit: u128 = number % 10;
                number /= 10;
                tmpArray.append(digit.into() + 48);
            };
            let mut i: u32 = tmpArray.len();
            if i == 0 { // deal with 0 case
                uri.append(48);
            }
            loop {
                if i == 0 {
                    break;
                }
                i -= 1;
                uri.append(*tmpArray.get(i.into()).unwrap().unbox());
            };
            return uri;
        }
        // fn _check_on_erc721_received(
        //     self: @ContractState,
        //     from: starknet::ContractAddress,
        //     to: starknet::ContractAddress,
        //     token_id: u256,
        //     data: Span<felt252>
        // ) -> bool {
        //     let SRC5 = DualCaseSRC5 { contract_address: to };

        //     if (SRC5.supports_interface(IERC721_RECEIVER_ID_LEGACY)) {
        //         let ERC721Receiver = DualCaseERC721Receiver { contract_address: to };

        //         let caller = starknet::get_caller_address();

        //         ERC721Receiver.on_erc721_received(operator: caller, :from, :token_id, :data) == IERC721_RECEIVER_ID_LEGACY
        //     } else {
        //         SRC5.supports_interface(0x150b7a02)
        //     }
        // }
    }

    #[generate_trait]
    impl ModifierImpl of ModifierTrait {
        fn _only_owner(self: @ContractState) {
            let mut ownable_self = Ownable::unsafe_new_contract_state();

            ownable_self.assert_only_owner();
        }
    }

    #[external(v0)]
    impl IOwnableImpl of IOwnable<ContractState> {
        fn owner(self: @ContractState) -> ContractAddress {
            let ownable_self = Ownable::unsafe_new_contract_state();

            ownable_self.owner()
        }

        fn transfer_ownership(ref self: ContractState, new_owner: ContractAddress) {
            let mut ownable_self = Ownable::unsafe_new_contract_state();

            ownable_self.transfer_ownership(:new_owner);
        }

        fn renounce_ownership(ref self: ContractState) {
            let mut ownable_self = Ownable::unsafe_new_contract_state();

            ownable_self.renounce_ownership();
        }
    }
}
