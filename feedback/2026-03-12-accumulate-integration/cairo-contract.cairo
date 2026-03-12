// Accumulate Receipt Verifier for StarkNet
// Hierarchical proof verification:
//   1. Register anchor (proven to Bitcoin) - rare, expensive
//   2. Verify receipts against anchor - common, cheap
//   3. Query proven data - instant, free
//
// One anchor proves unlimited data chains.
// One receipt proves entire data chain.
// Transitive trust from Bitcoin → Accumulate → Data.

use core::sha256::compute_sha256_u32_array;
use core::array::ArrayTrait;
use core::option::OptionTrait;

// 32-byte hash represented as 8 u32 values
type Hash256 = [u32; 8];

#[derive(Drop, Serde, Clone)]
struct ReceiptEntry {
    right: bool,        // true = hash goes on right side
    hash: Hash256,      // 32-byte SHA-256 hash
}

#[derive(Drop, Serde)]
struct Receipt {
    start: Hash256,               // Entry hash being proven
    start_index: u64,             // Index in source chain
    end: Hash256,                 // Entry at anchor point
    end_index: u64,               // Index of anchor entry
    anchor: Hash256,              // Must match registered anchor
    entries: Array<ReceiptEntry>, // Merkle path
}

#[derive(Drop, Serde, starknet::Store)]
struct AnchorInfo {
    hash_0: u32,          // Anchor hash (split for storage)
    hash_1: u32,
    hash_2: u32,
    hash_3: u32,
    hash_4: u32,
    hash_5: u32,
    hash_6: u32,
    hash_7: u32,
    bitcoin_block: u64,   // Bitcoin block height
    registered_at: u64,   // StarkNet block when registered
    active: bool,         // Can be used for verification
}

#[starknet::interface]
trait IAccumulateVerifier<TContractState> {
    // Anchor management
    fn register_anchor(
        ref self: TContractState,
        anchor_id: felt252,
        anchor_hash: Hash256,
        bitcoin_block: u64,
    );
    fn deactivate_anchor(ref self: TContractState, anchor_id: felt252);
    fn get_anchor(self: @TContractState, anchor_id: felt252) -> AnchorInfo;
    fn is_anchor_active(self: @TContractState, anchor_id: felt252) -> bool;

    // Receipt verification
    fn verify_receipt(
        self: @TContractState,
        receipt: Receipt,
        anchor_id: felt252,
    ) -> bool;

    fn verify_and_register_chain(
        ref self: TContractState,
        receipt: Receipt,
        anchor_id: felt252,
        chain_id: felt252,
    ) -> bool;

    // Chain/entry queries
    fn is_chain_proven(self: @TContractState, chain_id: felt252) -> bool;
    fn get_chain_anchor(self: @TContractState, chain_id: felt252) -> felt252;
}

#[starknet::contract]
mod AccumulateVerifier {
    use super::{Receipt, ReceiptEntry, AnchorInfo, Hash256};
    use core::sha256::compute_sha256_u32_array;
    use core::array::ArrayTrait;
    use starknet::storage::{Map, StorageMapReadAccess, StorageMapWriteAccess};
    use starknet::get_block_number;

    #[storage]
    struct Storage {
        // Registered anchors (proven to Bitcoin)
        anchors: Map<felt252, AnchorInfo>,

        // Proven chains (receipt verified against anchor)
        chain_proven: Map<felt252, bool>,
        chain_anchor: Map<felt252, felt252>,
        chain_start_hash: Map<felt252, felt252>,  // First word of start hash

        // Admin
        owner: felt252,
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        AnchorRegistered: AnchorRegistered,
        AnchorDeactivated: AnchorDeactivated,
        ChainProven: ChainProven,
    }

    #[derive(Drop, starknet::Event)]
    struct AnchorRegistered {
        anchor_id: felt252,
        bitcoin_block: u64,
    }

    #[derive(Drop, starknet::Event)]
    struct AnchorDeactivated {
        anchor_id: felt252,
    }

    #[derive(Drop, starknet::Event)]
    struct ChainProven {
        chain_id: felt252,
        anchor_id: felt252,
    }

    #[constructor]
    fn constructor(ref self: ContractState, owner: felt252) {
        self.owner.write(owner);
    }

    #[abi(embed_v0)]
    impl AccumulateVerifierImpl of super::IAccumulateVerifier<ContractState> {

        /// Register an Accumulate anchor that has been proven to Bitcoin
        /// This is a privileged operation - anchor must be verified off-chain
        /// Future: Add Bitcoin SPV proof verification
        fn register_anchor(
            ref self: ContractState,
            anchor_id: felt252,
            anchor_hash: Hash256,
            bitcoin_block: u64,
        ) {
            // TODO: Verify caller is authorized
            // TODO: Verify Bitcoin SPV proof

            let info = AnchorInfo {
                hash_0: anchor_hash[0],
                hash_1: anchor_hash[1],
                hash_2: anchor_hash[2],
                hash_3: anchor_hash[3],
                hash_4: anchor_hash[4],
                hash_5: anchor_hash[5],
                hash_6: anchor_hash[6],
                hash_7: anchor_hash[7],
                bitcoin_block: bitcoin_block,
                registered_at: get_block_number(),
                active: true,
            };

            self.anchors.write(anchor_id, info);
            self.emit(AnchorRegistered { anchor_id, bitcoin_block });
        }

        /// Deactivate an anchor (e.g., for rotation)
        fn deactivate_anchor(ref self: ContractState, anchor_id: felt252) {
            // TODO: Verify caller is authorized
            let mut info = self.anchors.read(anchor_id);
            info.active = false;
            self.anchors.write(anchor_id, info);
            self.emit(AnchorDeactivated { anchor_id });
        }

        /// Get anchor info
        fn get_anchor(self: @ContractState, anchor_id: felt252) -> AnchorInfo {
            self.anchors.read(anchor_id)
        }

        /// Check if anchor is active
        fn is_anchor_active(self: @ContractState, anchor_id: felt252) -> bool {
            self.anchors.read(anchor_id).active
        }

        /// Verify a receipt against a registered anchor
        /// Returns true if merkle path is valid and matches anchor
        fn verify_receipt(
            self: @ContractState,
            receipt: Receipt,
            anchor_id: felt252,
        ) -> bool {
            // Get stored anchor
            let anchor_info = self.anchors.read(anchor_id);
            if !anchor_info.active {
                return false;
            }

            // Reconstruct anchor hash from storage
            let stored_anchor: Hash256 = [
                anchor_info.hash_0,
                anchor_info.hash_1,
                anchor_info.hash_2,
                anchor_info.hash_3,
                anchor_info.hash_4,
                anchor_info.hash_5,
                anchor_info.hash_6,
                anchor_info.hash_7,
            ];

            // Receipt anchor must match stored anchor
            if !hashes_equal(receipt.anchor, stored_anchor) {
                return false;
            }

            // Walk merkle path
            verify_merkle_path(receipt.start, @receipt.entries, receipt.anchor)
        }

        /// Verify receipt and register chain as proven
        fn verify_and_register_chain(
            ref self: ContractState,
            receipt: Receipt,
            anchor_id: felt252,
            chain_id: felt252,
        ) -> bool {
            // Verify the receipt
            let start_hash_0 = receipt.start[0];

            if !Self::verify_receipt(@self, receipt, anchor_id) {
                return false;
            }

            // Register chain as proven
            self.chain_proven.write(chain_id, true);
            self.chain_anchor.write(chain_id, anchor_id);
            self.chain_start_hash.write(chain_id, start_hash_0.into());

            self.emit(ChainProven { chain_id, anchor_id });
            true
        }

        /// Check if a chain has been proven
        fn is_chain_proven(self: @ContractState, chain_id: felt252) -> bool {
            self.chain_proven.read(chain_id)
        }

        /// Get the anchor a chain was proven against
        fn get_chain_anchor(self: @ContractState, chain_id: felt252) -> felt252 {
            self.chain_anchor.read(chain_id)
        }
    }

    /// Verify merkle path from start to anchor
    fn verify_merkle_path(
        start: Hash256,
        entries: @Array<ReceiptEntry>,
        anchor: Hash256,
    ) -> bool {
        let mut current = start;
        let mut i: u32 = 0;
        let len = entries.len();

        loop {
            if i >= len {
                break;
            }

            let entry = entries.at(i);
            current = apply_entry(current, entry);
            i += 1;
        };

        // Computed root must match anchor
        hashes_equal(current, anchor)
    }

    /// Apply a single merkle path entry
    /// SHA256(left || right) where position determined by entry.right
    fn apply_entry(current: Hash256, entry: @ReceiptEntry) -> Hash256 {
        let mut input: Array<u32> = ArrayTrait::new();

        if *entry.right {
            // current on left, entry.hash on right
            append_hash(ref input, current);
            append_hash_ref(ref input, entry.hash);
        } else {
            // entry.hash on left, current on right
            append_hash_ref(ref input, entry.hash);
            append_hash(ref input, current);
        }

        compute_sha256_u32_array(input)
    }

    fn append_hash(ref input: Array<u32>, hash: Hash256) {
        input.append(hash[0]);
        input.append(hash[1]);
        input.append(hash[2]);
        input.append(hash[3]);
        input.append(hash[4]);
        input.append(hash[5]);
        input.append(hash[6]);
        input.append(hash[7]);
    }

    fn append_hash_ref(ref input: Array<u32>, hash: @Hash256) {
        input.append(*hash[0]);
        input.append(*hash[1]);
        input.append(*hash[2]);
        input.append(*hash[3]);
        input.append(*hash[4]);
        input.append(*hash[5]);
        input.append(*hash[6]);
        input.append(*hash[7]);
    }

    fn hashes_equal(a: Hash256, b: Hash256) -> bool {
        a[0] == b[0]
            && a[1] == b[1]
            && a[2] == b[2]
            && a[3] == b[3]
            && a[4] == b[4]
            && a[5] == b[5]
            && a[6] == b[6]
            && a[7] == b[7]
    }
}

// ============================================================================
// USAGE EXAMPLE
// ============================================================================
//
// 1. REGISTER ANCHOR (once per Bitcoin anchor period)
//
//    Off-chain: Verify Accumulate anchor is in Bitcoin block 850000
//    On-chain:  register_anchor('anchor_001', anchor_hash, 850000)
//
// 2. VERIFY DATA CHAIN (once per chain update)
//
//    Off-chain: Get receipt from Accumulate for chain "prices/btc-usd"
//    On-chain:  verify_and_register_chain(receipt, 'anchor_001', 'btc-usd')
//
// 3. USE PROVEN DATA (unlimited, free queries)
//
//    On-chain:  if is_chain_proven('btc-usd') { use_price_data() }
//
// ============================================================================
// COST ANALYSIS
// ============================================================================
//
// register_anchor:          ~1 storage write, minimal compute
// verify_and_register_chain: ~20 SHA-256 calls + 3 storage writes
// is_chain_proven:          1 storage read (free in view call)
//
// For 1000 price feeds updated hourly:
// - Traditional: 1000 proofs/hour = 24000 proofs/day
// - Accumulate:  1 anchor/day + 24 receipts = 25 proofs/day
// - Reduction:   99.9%
//
// ============================================================================
