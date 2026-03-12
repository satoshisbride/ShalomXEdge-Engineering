# Accumulate-StarkNet Oracle Architecture

## Core Innovation: Hierarchical Batch Proofs with Authority Binding

Traditional oracle systems prove each data point individually. Accumulate's architecture enables hierarchical proof efficiency with cryptographic authority provenance:

1. **Accumulate anchors to Bitcoin** - establishes trusted root
2. **Once anchor is proven on-chain** - it becomes reusable trust anchor
3. **Multiple data chains verify against that anchor** - no re-proving needed
4. **Each chain contains arbitrary entries** - all proven transitively
5. **URL structure binds data to ADI authority** - proves WHO authorized data

**Result: Prove once, validate unlimited data, verify authority without identity disclosure.**

## Accumulate URL Structure

All Accumulate accounts are addressed via URLs:

```
acc://[identity]/[path]

Examples:
acc://oracle.acme                      # ADI (identity root with keys)
acc://oracle.acme/prices               # Sub-account
acc://oracle.acme/prices/btc-usd       # Specific data chain
acc://gov.state/credentials/0x7f...    # Pseudonymous credential
```

**Key property:** The identity portion (`oracle.acme`) controls all sub-paths. A receipt for any URL proves which ADI authorized the data.

## Hierarchical Structure

```
Bitcoin Block (global trust root)
    │
    └── Accumulate Anchor (proven once on StarkNet)
            │
            ├── acc://oracle.acme                    [ADI authority]
            │       ├── /prices/btc-usd ─── Receipt ─── 10,000 entries
            │       ├── /prices/eth-usd ─── Receipt ─── 10,000 entries
            │       └── /prices/sol-usd ─── Receipt ─── 10,000 entries
            │
            ├── acc://sensor.network                 [ADI authority]
            │       └── /readings/zone-a ── Receipt ─── 50,000 IoT readings
            │
            ├── acc://bridge.protocol                [ADI authority]
            │       └── /txs/eth-to-btc ─── Receipt ─── 1,000 cross-chain txs
            │
            └── acc://gov.state                      [ADI authority]
                    └── /credentials ────── Receipt ─── 1M citizen creds
```

**Key insights:**
1. Once anchor is verified on StarkNet, any receipt proving to that anchor is valid
2. URL path proves which ADI authority controls the data
3. ADI can be pseudonymous - authority verified without real-world identity

## Economics: Compounding Efficiency

| Operation | Cost | Frequency |
|-----------|------|-----------|
| Prove Bitcoin anchor | ~1 verification | Once per anchor period |
| Prove data chain receipt | ~20 SHA-256 ops | Per chain update |
| Prove individual entry | 0 (already proven) | N/A |

### Comparison

| Scenario | Individual Proofs | Accumulate Hierarchical |
|----------|-------------------|------------------------|
| 10 chains × 10,000 entries | 100,000 verifications | 1 anchor + 10 receipts |
| 100 chains × 100,000 entries | 10,000,000 verifications | 1 anchor + 100 receipts |

**Cost reduction: 99.99%+ for multi-chain scenarios**

## Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                           BITCOIN                               │
│                    (Global Trust Anchor)                        │
└─────────────────────────────────────────────────────────────────┘
                              │
                    Accumulate anchor tx
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                     ACCUMULATE NETWORK                          │
│                                                                 │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │                    Anchor Chain                          │   │
│  │         (Periodic Bitcoin anchor commitments)            │   │
│  └─────────────────────────────────────────────────────────┘   │
│         │              │              │              │          │
│         ▼              ▼              ▼              ▼          │
│  ┌───────────┐  ┌───────────┐  ┌───────────┐  ┌───────────┐   │
│  │ Chain A   │  │ Chain B   │  │ Chain C   │  │ Chain N   │   │
│  │ (prices)  │  │ (IoT)     │  │ (txs)     │  │ (...)     │   │
│  │           │  │           │  │           │  │           │   │
│  │ entry 1   │  │ entry 1   │  │ entry 1   │  │ entry 1   │   │
│  │ entry 2   │  │ entry 2   │  │ entry 2   │  │ entry 2   │   │
│  │ ...       │  │ ...       │  │ ...       │  │ ...       │   │
│  │ entry M   │  │ entry M   │  │ entry M   │  │ entry M   │   │
│  └───────────┘  └───────────┘  └───────────┘  └───────────┘   │
│         │              │              │              │          │
│         └──────────────┴──────────────┴──────────────┘          │
│                              │                                   │
│                    Receipts (prove chain → anchor)              │
└──────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                      STARKNET L2                                │
│                                                                 │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │              AccumulateVerifier Contract                 │   │
│  │                                                          │   │
│  │  TRUSTED ANCHORS (proven once, reused forever):         │   │
│  │  ┌─────────────────────────────────────────────────┐    │   │
│  │  │ anchor_001: 0xabc123... (Bitcoin block 850000)  │    │   │
│  │  │ anchor_002: 0xdef456... (Bitcoin block 850100)  │    │   │
│  │  │ anchor_003: 0x789abc... (Bitcoin block 850200)  │    │   │
│  │  └─────────────────────────────────────────────────┘    │   │
│  │                                                          │   │
│  │  register_anchor(anchor, bitcoin_proof)                 │   │
│  │  - Verify anchor ties to Bitcoin                        │   │
│  │  - Store as trusted root                                │   │
│  │  - One-time operation per anchor                        │   │
│  │                                                          │   │
│  │  verify_receipt(receipt, anchor_id) → bool              │   │
│  │  - Check receipt.anchor matches stored anchor           │   │
│  │  - Walk merkle path (no anchor re-verification)         │   │
│  │  - ~20 SHA-256 ops regardless of data size              │   │
│  │                                                          │   │
│  │  verify_entry(entry_hash, receipt, anchor_id) → bool    │   │
│  │  - Prove specific entry exists in chain                 │   │
│  │  - Transitive trust from stored anchor                  │   │
│  └─────────────────────────────────────────────────────────┘   │
│                              │                                  │
│                              ▼                                  │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │              DeFi / Application Contracts                │   │
│  │                                                          │   │
│  │  if verifier.verify_entry(price_hash, receipt, anchor): │   │
│  │      execute_trade(price)                                │   │
│  │                                                          │   │
│  │  Trust model:                                            │   │
│  │  - Bitcoin secures anchor                                │   │
│  │  - Anchor secures all Accumulate chains                  │   │
│  │  - Receipt proves specific chain data                    │   │
│  │  - Entry hash proves specific value                      │   │
│  └─────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────┘
```

## Trust Model

```
Multiple Anchor Targets
    │
    ├── Bitcoin PoW ──────────── strongest finality, energy-intensive
    ├── Ethereum PoS ─────────── fast finality, economic security
    ├── StarkNet (direct) ────── native L2 access
    └── Others ───────────────── any chain accepting anchors
    │
    │ Accumulate anchors to one or more
    ▼
Accumulate Anchor Hash
    │
    │ stored as trusted root (verify once per target chain)
    ▼
Target Chain Contract Storage
    │
    │ validates via merkle path (per receipt)
    ▼
Data Chain Receipt
    │
    │ proves membership (hash comparison)
    ▼
Individual Entry
```

**Security assumption:** Trust derives from whichever anchor chain you verify against. Applications choose their trust model.

## Abstract Account Security

Beyond data attestation, Accumulate enables **anchor proofs as authorization**:

| Traditional | Accumulate Model |
|-------------|------------------|
| Private key signs tx | Data entry exists in chain |
| Signature verification | Receipt verification |
| Key compromise = full access | Entry-level authorization |
| Revocation = new keys | Remove entry = revoke |

**Combined with zkSTARK:**
```
Receipt proves: Some entry exists under acc://authority/credentials/*
zkSTARK proves: Entry satisfies predicate (role=admin, tier>=pro, etc.)
Result:         Authorized without revealing WHICH entry or WHO
```

This enables:
- Private access control (prove authorization without revealing identity)
- Conditional authorization (entry must exist AND satisfy predicate)
- Instant revocation (delete entry = authorization ends)
- Multi-authority approval (require entries from multiple ADIs)

## Accumulate Receipt Structure

From Accumulate source (`pkg/database/merkle/types.yml`):

```
Receipt:
  Start:      32 bytes   # Hash of entry being proven
  StartIndex: int64      # Position in chain
  End:        32 bytes   # Entry at anchor point
  EndIndex:   int64      # Position of anchor entry
  Anchor:     32 bytes   # Merkle DAG root (matches stored anchor)
  Entries:    []         # Path from start to anchor
    - Right:  bool       # Direction flag
    - Hash:   32 bytes   # Sibling hash
```

**Key field:** `Anchor` must match a pre-registered trusted anchor on StarkNet.

## Verification Modes

### Mode 1: Anchor Registration (rare, expensive)

```cairo
fn register_anchor(
    anchor_hash: [u32; 8],
    bitcoin_block: u64,
    bitcoin_proof: BitcoinProof,  // SPV or similar
) {
    // Verify anchor ties to Bitcoin
    assert(verify_bitcoin_inclusion(anchor_hash, bitcoin_proof));

    // Store as trusted
    self.trusted_anchors.write(anchor_id, anchor_hash);
    self.anchor_bitcoin_block.write(anchor_id, bitcoin_block);
}
```

### Mode 2: Receipt Verification (common, cheap)

```cairo
fn verify_against_anchor(
    receipt: Receipt,
    anchor_id: felt252,
) -> bool {
    // Get stored anchor
    let trusted = self.trusted_anchors.read(anchor_id);

    // Walk merkle path
    let computed = walk_merkle_path(receipt.start, receipt.entries);

    // Must match trusted anchor
    computed == trusted
}
```

### Mode 3: Entry Verification (instant, free)

```cairo
fn is_entry_proven(
    entry_hash: [u32; 8],
    chain_id: felt252,
) -> bool {
    // If chain was verified against anchor, entry is proven
    self.proven_chains.read(chain_id)
        && self.chain_contains.read((chain_id, entry_hash))
}
```

## Cost Analysis

| Operation | SHA-256 Calls | Gas (est.) | Frequency |
|-----------|---------------|------------|-----------|
| Register anchor | 1-10 | High | Weekly/daily |
| Verify receipt | ~20 | Medium | Per chain update |
| Check entry | 0 | Minimal | Per query |

**For 1000 data chains with 1M entries each:**
- Traditional: 1 billion verifications
- Accumulate: 1 anchor + 1000 receipts = ~20,000 SHA-256 calls

## Use Cases

### 1. Multi-Asset Oracle
- 1000 price feeds across 50 chains
- One anchor registration per day
- 50 receipt verifications per update
- All 1000 prices proven

### 2. Cross-Chain Bridge
- Prove transactions from multiple source chains
- Each source chain = one receipt
- Single anchor covers all chains
- Sub-second verification

### 3. Data Availability Attestation
- Large datasets committed to Accumulate
- Receipts prove data exists
- Full data off-chain, proof on-chain
- Bitcoin-grade security

### 4. IoT Sensor Networks
- Millions of readings per day
- Batched into chains by sensor/region
- One receipt per batch
- Immutable audit trail

## Comparison to Alternatives

| System | Trust Root | Per-Chain Cost | Multi-Chain Efficiency |
|--------|------------|----------------|------------------------|
| Chainlink | Reputation | O(n) attestations | None |
| LayerZero | Relayer/Oracle | Per-message | None |
| Wormhole | Guardian set | Per-message | None |
| **Accumulate** | **Bitcoin PoW** | **O(log n) hashes** | **Shared anchor** |

## Minimal Prototype Scope

### Phase 1: Single Anchor Demo
- [ ] Cairo contract with hardcoded anchor
- [ ] `verify_receipt()` against stored anchor
- [ ] Test vectors from Accumulate testnet
- [ ] Deploy to StarkNet Sepolia

### Phase 2: Anchor Registration
- [ ] `register_anchor()` with Bitcoin proof
- [ ] Multiple anchors in storage
- [ ] Receipt routing to correct anchor

### Phase 3: Multi-Chain Demo
- [ ] 10+ data chains in Accumulate
- [ ] Batch receipt verification
- [ ] Gas benchmarks
- [ ] Comparison metrics

## Open Questions

1. **Anchor frequency:** How often should new anchors be registered? (tradeoff: freshness vs. cost)

2. **Bitcoin proof format:** SPV proof? Header chain? What's minimal for StarkNet?

3. **Receipt batching:** Can multiple receipts be verified in single transaction?

4. **Chain discovery:** How do consumers know which chain contains their data?

5. **Anchor rotation:** Policy for retiring old anchors?

## Implementation Files

- `2026-03-12-accumulate-cairo-contract.cairo` - Core verification logic
- `2026-03-12-bitdmx-paper-v2.md` - Academic paper draft

## References

- Accumulate Protocol: https://accumulatenetwork.io
- Accumulate Merkle: `gitlab.com/AccumulateNetwork/accumulate/pkg/database/merkle/`
- Bitcoin SPV: BIP-37
- Cairo SHA-256: `core::sha256::compute_sha256_u32_array`
- StarkNet: https://docs.starknet.io
