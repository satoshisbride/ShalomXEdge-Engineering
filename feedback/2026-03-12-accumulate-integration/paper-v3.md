# Privacy-Preserving Batch Oracles: Hierarchical Proofs via Accumulate and zkSTARK

**Authors:** Annabelle Shalom, Christyanaviva, Paul Snow

**Submission Track:** Science of Blockchain Conference (SBC) 2026

**Date:** March 2026

**Keywords:** zkSTARK, privacy-preserving oracles, Accumulate, StarkNet, hierarchical proofs, selective disclosure, decentralized identity, authority provenance

---

## Abstract

Oracle systems face a fundamental tension: data must be verifiable on-chain, yet revealing raw data enables front-running, privacy violations, and competitive disadvantage. We present a two-layer architecture combining Accumulate's hierarchical batch proofs with zkSTARK's zero-knowledge computation. The first layer uses Accumulate to commit data off-chain and generate compact receipts proving data existence, with Bitcoin anchoring for security. Accumulate's URL-based addressing (`acc://authority/path`) cryptographically binds data to controlling identities, enabling authority verification without identity disclosure. The second layer uses Cairo/zkSTARK to prove properties of committed data without revealing values. This achieves: (1) batch proof efficiency—one receipt proves unlimited data entries with O(log N) verification; (2) hierarchical trust—one Bitcoin anchor validates unlimited receipts; (3) authority provenance—prove which entity authorized data without revealing their real-world identity; (4) selective disclosure—prove predicates ("balance > threshold") without revealing inputs. We present a Cairo reference implementation and identify deployment requirements for StarkNet.

---

## 1. Introduction

Decentralized oracles secure over $20 billion in DeFi protocols [7], yet face two persistent challenges:

**Efficiency:** Traditional oracles prove each data point individually, scaling linearly with data volume. For high-frequency feeds (prices, IoT, cross-chain state), verification costs become prohibitive.

**Privacy:** Raw oracle data enables exploitation. Price feeds enable front-running. Identity attestations leak personal information. Business data reveals competitive intelligence.

Existing solutions address these independently. Batch proving (rollups) improves efficiency but exposes data. Zero-knowledge proofs provide privacy but require per-proof computation. No system achieves both simultaneously with practical efficiency.

### 1.1 Contribution

We present a two-layer architecture:

**Layer 1: Accumulate Batch Proofs**
- Data committed to Accumulate Network chains via URL-addressed accounts
- URL structure (`acc://authority/path`) cryptographically binds data to ADI authorities
- Hierarchical Merkle DAG with Bitcoin anchoring
- Single receipt proves entire data chain (O(log N) hashes)
- Single anchor validates unlimited receipts

**Layer 2: zkSTARK Selective Disclosure**
- Cairo contracts verify Accumulate receipts on StarkNet
- zkSTARK proofs demonstrate properties of committed data
- Zero-knowledge: verifier learns predicate result, not input values

**Combined properties:**

| Property | Mechanism | Benefit |
|----------|-----------|---------|
| Batch efficiency | Hierarchical receipts | 99%+ cost reduction |
| Trust minimization | Bitcoin anchoring | PoW security |
| Authority provenance | URL/ADI binding | Prove who, not identity |
| Selective disclosure | zkSTARK predicates | Prove what, not values |

### 1.2 Paper Organization

Section 2 covers background on Accumulate and zkSTARK. Section 3 presents the hierarchical proof architecture. Section 4 details the privacy layer. Section 5 provides Cairo implementation. Section 6 analyzes security properties. Section 7 discusses deployment requirements, open problems, and future research directions.

---

## 2. Background

### 2.1 Accumulate Protocol

Accumulate is a delegated proof-of-stake network providing identity-based data management with Bitcoin anchoring [1]. Key features:

**Accumulate URLs:** All accounts are addressed via URLs following the pattern `acc://[identity]/[path]`. Examples:

```
acc://oracle.acme                      # ADI (identity root)
acc://oracle.acme/prices               # Sub-account for price data
acc://oracle.acme/prices/btc-usd       # Specific price feed chain
acc://gov.state/credentials/citizens   # Government credential chain
acc://bank.example/accounts/12345      # Bank account data
```

URLs are not merely paths—they encode cryptographic authority. The identity root (`acc://oracle.acme`) controls all sub-paths.

**Accumulate Digital Identifiers (ADI):** The identity portion of a URL (e.g., `oracle.acme`) is an ADI with associated key hierarchies. ADIs can:

- Define multiple key pages with different signing thresholds
- Delegate authority to sub-identities
- Control all accounts and chains under their URL path

**Authority Binding:** Any data at `acc://oracle.acme/prices/*` is cryptographically controlled by the `acc://oracle.acme` ADI. A receipt proving data exists at a URL implicitly proves which authority created it—without revealing the authority's real-world identity if the ADI is pseudonymous.

**Data Chains:** Each URL path can have multiple chains (main chain, scratch chains, etc.) storing arbitrary data entries. Chains are append-only Merkle DAGs.

**Receipts:** Compact proofs that a specific entry exists in a chain, verifiable against a root anchor. Receipt size is O(log N) for N entries. Receipts include the full URL path, binding data to authority.

**Multi-Protocol Anchoring:** Accumulate periodically commits network state to multiple protocols:
- Bitcoin (proof-of-work finality)
- Smart contract chains (Ethereum, StarkNet, etc.)
- Future: any protocol accepting anchors

This enables receipts to be verified against anchors stored on whichever chain the application uses.

**Abstract Account Security:** Beyond data attestation, Accumulate enables a paradigm where data entries authorize actions and anchor proofs replace signatures:

| Traditional Model | Accumulate Model |
|-------------------|------------------|
| Private key signs tx | Data entry exists in chain |
| Signature verification | Receipt verification |
| Key compromise = full access | Entry-level authorization |
| Revocation requires new keys | Remove entry = revoke |

This enables:
- **Policy-based authorization:** Action allowed if entry matches policy
- **Multi-authority approval:** Multiple entries from different ADIs required
- **Conditional authorization:** Entry must exist AND satisfy predicate
- **Instant revocation:** Delete entry from chain, authorization ends

### 2.2 Hierarchical Receipt Structure

Accumulate receipts have structure:

```
Receipt:
  start:       Hash256    // Entry being proven
  start_index: u64        // Position in chain
  end:         Hash256    // Entry at anchor point
  end_index:   u64        // Anchor entry position
  anchor:      Hash256    // Merkle DAG root
  entries:     []Entry    // Path from start to anchor
    - right:   bool       // Direction flag
    - hash:    Hash256    // Sibling hash
```

Verification: Walk path from `start` to computed root, compare with `anchor`.

```
current = start
for entry in entries:
    if entry.right:
        current = SHA256(current || entry.hash)
    else:
        current = SHA256(entry.hash || current)
return current == anchor
```

**Key property:** Receipt proves entry exists without revealing other chain contents.

### 2.3 zkSTARK Fundamentals

Scalable Transparent Arguments of Knowledge [2] provide:

- **Transparency:** No trusted setup; randomness from public transcript
- **Zero-knowledge:** Verifier learns statement truth, not witness values
- **Scalability:** Prover O(N log N), verifier O(log² N)
- **Post-quantum:** Based on hash functions, not elliptic curves

Cairo [5] compiles to AIR (Algebraic Intermediate Representation) for STARK proving.

### 2.4 Related Work

**Chainlink [10]:** Attestation-based oracles. No batch efficiency or privacy.

**DECO [3]:** TLS-based private attestation. Proves web data without revealing content. Single-source, no batching.

**Town Crier [4]:** TEE-based oracle privacy. Hardware trust assumption.

**Mina [9]:** Recursive SNARK state proofs. Different trust model (no Bitcoin anchor).

Our work combines Accumulate's batch efficiency with zkSTARK privacy, avoiding trusted hardware and setup ceremonies.

---

## 3. Hierarchical Proof Architecture

### 3.1 Trust Hierarchy

```
Anchor Targets (one or more)
    │
    ├── Bitcoin ────── PoW finality
    ├── Ethereum ───── PoS finality
    └── StarkNet ───── Direct L2 access
    │
    └── Accumulate Anchor ─────────────── verified once per target chain
            │
            ├── acc://oracle.acme           (ADI authority)
            │       │
            │       ├── /prices/btc-usd ─── Receipt ─── 10,000 price entries
            │       ├── /prices/eth-usd ─── Receipt ─── 10,000 price entries
            │       └── /prices/sol-usd ─── Receipt ─── 10,000 price entries
            │
            ├── acc://gov.state             (ADI authority)
            │       │
            │       └── /credentials ────── Receipt ─── 1M citizen credentials
            │
            └── acc://bank.example          (ADI authority)
                    │
                    └── /accounts ────────── Receipt ─── account attestations
```

Accumulate anchors to multiple protocols. Applications verify receipts against whichever anchor target suits their trust requirements.

**Trust propagation:**
1. Anchor target (Bitcoin, Ethereum, etc.) provides finality guarantees
2. Accumulate anchor is committed to one or more targets (one verification per target)
3. Receipts prove to stored anchor (no re-verification of anchor)
4. URL path binds data to controlling ADI (authority provenance)
5. Entries are proven via receipt (no per-entry cost)

### 3.2 Authority Provenance

The URL structure provides cryptographic authority binding without trusted registries:

| What Receipt Proves | What URL Proves |
|---------------------|-----------------|
| Data exists in Accumulate | Which ADI authorized the data |
| Data is Bitcoin-anchored | Authority hierarchy (parent controls children) |
| Data hasn't been modified | Pseudonymous authority (no real-world identity leak) |

**Example:** A receipt for `acc://oracle.acme/prices/btc-usd` proves:
- The price data exists and is anchored to Bitcoin
- The `acc://oracle.acme` ADI authorized this data
- No one without `oracle.acme` keys could have written it

The verifier learns the authority without learning:
- Who controls `oracle.acme` (pseudonymous)
- What other data exists under `oracle.acme/*`
- The content of other entries in the same chain

### 3.3 Efficiency Analysis

| Operation | Verification Cost | Frequency |
|-----------|-------------------|-----------|
| Anchor registration | O(1) | Per anchor period |
| Receipt verification | O(log N) SHA-256 | Per chain update |
| Entry membership | O(1) lookup | Per query |

**Comparison with linear verification:**

| Data Volume | Linear Proofs | Hierarchical |
|-------------|---------------|--------------|
| 100 entries × 10 chains | 1,000 | 1 anchor + 10 receipts |
| 10,000 entries × 100 chains | 1,000,000 | 1 anchor + 100 receipts |
| 1M entries × 1,000 chains | 1,000,000,000 | 1 anchor + 1,000 receipts |

### 3.4 Data Flow

```
┌─────────────────┐
│  Data Sources   │  (prices, credentials, IoT, cross-chain)
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│   Accumulate    │  Commit to ADI chain
│   Network       │  Generate receipt against anchor
└────────┬────────┘
         │ Receipt (~1KB)
         ▼
┌─────────────────┐
│    StarkNet     │  Verify receipt (public)
│  Cairo Contract │  Prove property (zero-knowledge)
└────────┬────────┘
         │ Boolean result
         ▼
┌─────────────────┐
│   Application   │  "User qualifies" / "Price in range"
└─────────────────┘
```

---

## 4. Privacy Layer: Selective Disclosure

### 4.1 Problem Statement

Proving data exists (via receipt) is necessary but insufficient. Applications need to prove *properties* of data without revealing *values*.

**Examples:**
- Credit: "Income > $50,000" without revealing exact income
- Trading: "Price moved > 1%" without revealing price (prevents front-running)
- Identity: "Age ≥ 18" without revealing birthdate
- Compliance: "Passed sanctions check" without revealing identity

### 4.2 Commitment-Based Privacy

Data is stored in Accumulate as commitments, not plaintext:

```
commitment = Hash(value || blinding_factor)
```

The receipt proves the commitment exists. A separate zkSTARK proves knowledge of the preimage satisfying some predicate.

**Workflow:**

1. **Commit:** Store `commitment = Hash(value || r)` in Accumulate chain
2. **Prove existence:** Accumulate receipt proves commitment is anchored to Bitcoin
3. **Prove property:** zkSTARK proves "I know (value, r) such that Hash(value || r) = commitment AND predicate(value) = true"

Verifier learns: commitment exists (from receipt) and predicate holds (from STARK). Verifier does not learn: value or blinding factor.

### 4.3 Cairo Implementation: Private Threshold Check

```cairo
// Fragment - see Appendix A for complete implementation
use core::sha256::compute_sha256_u32_array;

type Hash256 = [u32; 8];  // 256-bit hash as 8 × 32-bit words

/// Prove: "I know value and blinding such that:
///   1. Hash(value || blinding) = commitment
///   2. value > threshold"
/// Without revealing value or blinding.
#[derive(Drop, Serde)]
struct ThresholdProof {
    commitment: Hash256,      // Public: the commitment
    threshold: u128,          // Public: the threshold
    // value and blinding are private witness, not in struct
}

/// Verification function (called in STARK context)
/// Private inputs come from prover's witness
fn verify_threshold_private(
    commitment: Hash256,
    threshold: u128,
    // Private witness:
    value: u128,
    blinding: Hash256,
) -> bool {
    // Recompute commitment
    let computed = compute_commitment(value, blinding);

    // Check commitment matches
    if !hashes_equal(computed, commitment) {
        return false;
    }

    // Check threshold
    value > threshold
}

fn compute_commitment(value: u128, blinding: Hash256) -> Hash256 {
    let mut input: Array<u32> = ArrayTrait::new();

    // Encode value as 4 × 32-bit words (big-endian)
    input.append(((value >> 96) & 0xFFFFFFFF).try_into().unwrap());
    input.append(((value >> 64) & 0xFFFFFFFF).try_into().unwrap());
    input.append(((value >> 32) & 0xFFFFFFFF).try_into().unwrap());
    input.append((value & 0xFFFFFFFF).try_into().unwrap());

    // Append 8-word blinding factor
    let mut i: u32 = 0;
    loop {
        if i >= 8 { break; }
        input.append(blinding[i]);
        i += 1;
    };

    compute_sha256_u32_array(input)
}
```

### 4.4 Privacy Use Cases

The combination of Accumulate URLs and zkSTARK proofs enables three types of privacy:

1. **Value privacy:** Prove properties without revealing values (zkSTARK)
2. **Authority verification:** Prove who authorized data without revealing their identity (URL + pseudonymous ADI)
3. **Selective disclosure:** Prove membership without revealing which entry (receipt structure)

#### 4.4.1 Private Credit Scoring

**Scenario:** DeFi lending protocol needs to verify borrower creditworthiness without accessing raw financial data.

**Accumulate URL structure:**
```
acc://equifax.bureau                    # Credit bureau ADI (known authority)
acc://equifax.bureau/scores             # Scores sub-account
acc://equifax.bureau/scores/0x7f3a...   # User's score (keyed by hash of user pubkey)
```

**Flow:**
1. Credit bureau commits score: `commitment = Hash(score || r)`
2. Commitment stored at `acc://equifax.bureau/scores/{hash(user_pubkey)}`
3. Receipt proves: commitment exists AND was written by `acc://equifax.bureau` authority
4. zkSTARK proves: "score > 650" without revealing score

**What verifier learns:**
- Score exceeds threshold ✓
- Equifax authorized this score ✓ (from URL authority)

**What verifier does NOT learn:**
- Actual score value ✗
- User's real identity ✗ (only pubkey hash in URL)
- Other scores in the bureau ✗

#### 4.4.2 Front-Running Resistant Price Feeds

**Scenario:** DEX needs price data but raw prices enable sandwich attacks.

**Accumulate URL structure:**
```
acc://chainlink.oracle                  # Oracle provider ADI
acc://chainlink.oracle/feeds            # Price feeds
acc://chainlink.oracle/feeds/btc-usd    # Specific pair (append-only chain)
```

**Flow:**
1. Oracle commits prices: `commitment = Hash(price || timestamp || r)`
2. Commitments appended to `acc://chainlink.oracle/feeds/btc-usd`
3. During time T: Receipt proves commitment exists under known oracle authority
4. zkSTARK proves: "price ∈ [low, high]" without exact value
5. After time T+Δ: Reveal exact price (front-running window passed)

**Authority benefit:** Verifier confirms data came from `acc://chainlink.oracle` without the oracle revealing which specific feed or timestamp until safe.

#### 4.4.3 Private Identity Attestation

**Scenario:** Service requires age verification without collecting birthdate.

**Accumulate URL structure:**
```
acc://dmv.california                    # Government authority ADI
acc://dmv.california/credentials        # Credential issuance chain
acc://dmv.california/credentials/0xab...  # Citizen credential (pseudonymous)
```

**Flow:**
1. DMV issues credential: `commitment = Hash(birthdate || license_class || r)`
2. Credential stored at `acc://dmv.california/credentials/{hash(citizen_pubkey)}`
3. Receipt proves credential exists under government authority
4. zkSTARK proves: "birthdate implies age ≥ 21"

**Privacy layers:**
- **Value privacy:** Birthdate never revealed (zkSTARK)
- **Authority verification:** Credential is from California DMV (URL authority)
- **Identity privacy:** Citizen identified only by pubkey hash (pseudonymous URL path)

**What verifier learns:**
- User is 21+ ✓
- California DMV issued the credential ✓

**What verifier does NOT learn:**
- Exact birthdate ✗
- Real name or address ✗
- License number ✗

#### 4.4.4 Multi-Authority Credentials

**Scenario:** Loan application requires proof of employment AND credit score from different authorities.

**Accumulate URL structure:**
```
acc://employer.corp/hr/employees/0x1a...     # Employment attestation
acc://experian.bureau/scores/0x1a...         # Credit score
```

**Flow:**
1. User obtains receipts from both URLs
2. Both receipts verify against same Accumulate anchor (single anchor verification)
3. zkSTARK proves: "employed = true AND score > 700"

**Efficiency:** Two authorities, two receipts, one anchor, one STARK proof.

**Privacy:** Neither authority learns what the other attested. Verifier learns only the combined predicate result.

### 4.5 Private Authorization via Anchor Proofs

Traditional smart contract authorization uses signatures: "This transaction is valid because key K signed it." Accumulate enables a different model: "This action is authorized because entry E exists in chain C."

Combined with zkSTARK, this becomes: "This action is authorized because *some* entry exists satisfying predicate P" — without revealing which entry.

**Example: Private Access Control**

```
acc://corp.access/employees/           # Employee credential chain
acc://corp.access/employees/0x1a...    # Alice's credential (pseudonymous)
acc://corp.access/employees/0x2b...    # Bob's credential (pseudonymous)
```

**Traditional approach:**
1. Alice signs request with employee key
2. System learns: Alice specifically is requesting access

**Accumulate + zkSTARK approach:**
1. Alice provides receipt proving *some* entry exists under `acc://corp.access/employees/*`
2. zkSTARK proves: "I know entry E where E.department = 'engineering' AND E.clearance >= 'secret'"
3. System learns: *Someone* with engineering + secret clearance is requesting access
4. System does NOT learn: Which employee, name, ID, or other attributes

**Applications:**

| Use Case | Authorization Entry | zkSTARK Predicate |
|----------|---------------------|-------------------|
| Building access | Employee credential | department = X |
| API rate limiting | Subscription tier | tier >= 'pro' |
| Voting | Voter registration | registered = true AND NOT voted |
| Trading | KYC attestation | kyc_passed AND jurisdiction ≠ 'banned' |

### 4.6 Composing Receipts and STARKs

Full verification requires both layers:

```cairo
/// Combined verification: existence + property
fn verify_private_oracle(
    receipt: Receipt,
    anchor_id: felt252,
    threshold: u128,
    // Private witness provided to prover:
    value: u128,
    blinding: Hash256,
) -> bool {
    // Layer 1: Verify receipt (commitment exists in Accumulate)
    if !verify_receipt(receipt, anchor_id) {
        return false;
    }

    // Layer 2: Verify property (value satisfies predicate)
    // commitment is receipt.start (the entry being proven)
    verify_threshold_private(receipt.start, threshold, value, blinding)
}
```

The entire function executes in STARK context. Verifier receives:
- Receipt (public)
- anchor_id (public)
- threshold (public)
- STARK proof (public, proves execution was correct)

Verifier does NOT receive: value, blinding (private witness).

---

## 5. Implementation

### 5.1 Contract Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                 AccumulateVerifier Contract                 │
├─────────────────────────────────────────────────────────────┤
│  Storage:                                                   │
│    anchors: Map<felt252, AnchorInfo>                       │
│    proven_chains: Map<felt252, bool>                        │
│                                                             │
│  Functions:                                                 │
│    register_anchor(id, hash, bitcoin_block)                │
│    verify_receipt(receipt, anchor_id) → bool               │
│    verify_and_store(receipt, anchor_id, chain_id)          │
├─────────────────────────────────────────────────────────────┤
│                 PrivateOracle Contract                      │
├─────────────────────────────────────────────────────────────┤
│  Functions:                                                 │
│    verify_threshold(receipt, anchor_id, threshold) → bool  │
│    verify_range(receipt, anchor_id, low, high) → bool      │
│    verify_membership(receipt, anchor_id, set_root) → bool  │
└─────────────────────────────────────────────────────────────┘
```

### 5.2 Gas Estimates

Preliminary estimates pending StarkNet testnet benchmarks:

| Operation | SHA-256 Calls | Estimated Gas |
|-----------|---------------|---------------|
| register_anchor | 0 | ~50,000 |
| verify_receipt (20 levels) | 20 | ~200,000–400,000 |
| threshold_check (private) | 1 + STARK overhead | ~300,000–500,000 |
| combined verification | 21 | ~500,000–900,000 |

*Note: SHA-256 is more expensive than Pedersen in Cairo. Actual costs depend on StarkNet fee market and SHARP batching.*

### 5.3 Reference Implementation

Full Cairo source provided in Appendix A. Key components:

- `AccumulateVerifier`: Receipt verification against stored anchors
- `PrivateThreshold`: Commitment verification with threshold predicate
- `PrivateRange`: Range proof on committed value
- `PrivateMembership`: Set membership proof

---

## 6. Security Analysis

### 6.1 Threat Model

**Adversary capabilities:**
- Controls minority of Accumulate validators
- Observes all on-chain transactions
- Cannot break SHA-256 or discrete log

**Security goals:**
- Soundness: Cannot prove false statements
- Privacy: Cannot learn private witness values
- Data integrity: Cannot forge receipts

### 6.2 Security Properties

**Theorem 1 (Receipt Soundness):** An adversary cannot produce a valid receipt for data not in the Accumulate chain except with probability 2^(-256) (SHA-256 collision).

**Theorem 2 (Anchor Integrity):** Receipts verify only against stored anchors. Accumulate anchors commit to Bitcoin with PoW finality.

**Theorem 3 (Zero-Knowledge):** STARK proofs reveal nothing about private witness beyond the statement being proven. Security reduction to random oracle model.

**Theorem 4 (Binding):** Once commitment is in Accumulate, prover cannot open to different value (collision resistance).

**Theorem 5 (Authority Binding):** Data at URL `acc://adi/path` can only be written by keys authorized by ADI `acc://adi`. Receipt for a URL cryptographically proves which authority created the data.

**Corollary (Pseudonymous Authority):** An ADI can be pseudonymous (e.g., `acc://0x7f3a8b...`). Authority is verifiable without real-world identity linkage. This enables:
- Proving "data from known oracle" without oracle revealing internal structure
- Proving "credential from government" without revealing which citizen
- Proving "attestation from employer" without revealing which employee

### 6.3 Limitations

**Data availability:** Accumulate must remain available for receipt generation. Proofs don't provide data recovery.

**Trusted setup for anchors:** Anchor registration currently requires trusted operator. Future work: Bitcoin SPV verification in Cairo.

**Commitment scheme:** Current design uses SHA-256 commitments. Pedersen commitments would enable homomorphic properties (additive proofs).

---

## 7. Discussion

### 7.1 Deployment Requirements

**Immediate (Phase 1):**
- Cairo contract deployment on StarkNet Sepolia
- Test vector generation from Accumulate testnet
- Basic receipt verification benchmarks

**Near-term (Phase 2):**
- Accumulate SDK integration for receipt generation
- Private predicate library (threshold, range, membership)
- Gas optimization

**Future (Phase 3):**
- Bitcoin SPV verification in Cairo (trustless anchors)
- Recursive proof aggregation (SHARP)
- Pedersen commitments for homomorphic proofs

### 7.2 Open Problems

1. **Optimal commitment scheme:** SHA-256 is simple but non-algebraic. Pedersen enables addition/multiplication proofs. Poseidon is STARK-friendly but less standard.

2. **Proof aggregation:** Can multiple private oracle queries batch into single STARK?

3. **Data availability incentives:** Who stores raw data, and why?

4. **Cross-chain privacy:** Proving properties of data on Chain A to Chain B without revealing data to either.

### 7.3 Future Directions

**Multi-Protocol Anchoring**

Accumulate's architecture supports anchoring to multiple protocols simultaneously:

*Direct Smart Contract Anchoring:*
- Anchor Accumulate state directly to Ethereum, StarkNet, Solana, etc.
- Applications verify receipts against local anchor (no bridge required)
- Each chain has native access to Accumulate proofs

*Parallel Anchoring for Redundancy:*
- Anchor to Bitcoin (PoW finality) AND Ethereum (PoS finality) AND others
- Applications choose trust model appropriate for their use case
- No single chain dependency

*Proof-of-Space/Time (Chia) [6]:*
- Alternative to PoW with reduced energy footprint (~1-10W vs. kW scale)
- Different security/finality tradeoffs
- Eco-sustainability without sacrificing decentralization

**Bitcoin-Native Verification via BitVMX**

BitVMX [8] enables RISC-V program verification on Bitcoin through fraud proofs. Future work could implement Accumulate receipt verification directly in BitVMX, enabling:
- Trustless Bitcoin ↔ StarkNet bridges using Accumulate as intermediate layer
- Bitcoin script verification of oracle data without L2 dependency
- 1-of-n honest verifier assumption for Bitcoin-native oracle consumption

**Private Credential Ecosystems**

The architecture enables privacy-preserving credential systems beyond simple attestations:

*Employment and Income Verification:*
- Employers commit salary/role data: `acc://employer.corp/hr/employees/0x...`
- zkSTARK proves: "employed AND salary > threshold" for loan applications
- Privacy: Exact salary, employer identity, employment dates not revealed

*Freelancer Reputation:*
- Clients commit project ratings: `acc://platform.gig/ratings/0x...`
- zkSTARK proves: "average rating > 4.5 AND projects > 10"
- Privacy: Individual project details, client identities not revealed
- Enables portable reputation across platforms

*Undercollateralized DeFi Lending:*
- Combine income proof, credit score, employment verification from multiple ADIs
- Single STARK proves compound eligibility predicate
- Enables credit-based DeFi without doxxing borrowers

**AI and Machine Learning Integration**

As AI-generated content proliferates, provenance becomes critical:

*Model Output Attestation:*
- AI provider commits outputs: `acc://openai.models/gpt5/outputs/0x...`
- Receipt proves output originated from known model
- zkSTARK proves properties: "confidence > 0.9" without revealing full output

*Training Data Provenance:*
- Data providers commit training sets to Accumulate
- Models prove "trained on data from acc://provider.data/*"
- Enables verifiable AI supply chains

**Tokenized Real-World Assets**

For privacy in RWA markets:
- Asset ownership committed with blinding: `acc://registry.land/parcels/0x...`
- zkSTARK proves: "owner controls parcel" without revealing which parcel
- Enables private real estate, securities, collectibles markets

**Recursive STARK Aggregation**

StarkNet's SHARP (Shared Prover) enables recursive proof composition:
- Batch 1000 private oracle queries into single proof
- Amortize prover costs across users
- Target: sub-cent verification cost per oracle query

### 7.4 Comparison Summary

| System | Batch Efficient | Private | Authority Provenance | Trust Assumption |
|--------|-----------------|---------|---------------------|------------------|
| Chainlink | No | No | Reputation-based | Node reputation |
| DECO | No | Yes | TLS certificate | TLS/Web PKI |
| Town Crier | No | Yes | TEE attestation | Intel SGX |
| Mina | Yes | Yes | None | Recursive SNARK |
| **This work** | **Yes** | **Yes** | **URL/ADI binding** | **Bitcoin PoW** |

**Authority provenance** answers: "Who authorized this data?" Accumulate URLs cryptographically bind data to ADI authorities without requiring real-world identity disclosure or trusted third parties.

---

## 8. Conclusion

We presented a two-layer architecture for privacy-preserving batch oracles achieving four properties not previously combined:

1. **Batch efficiency:** Accumulate's hierarchical Merkle DAG enables one anchor to validate unlimited data chains, each receipt proving unlimited entries. Verification costs reduce by 99%+ compared to per-entry proofs.

2. **Trust minimization:** Multi-protocol anchoring (Bitcoin, Ethereum, StarkNet) provides finality guarantees without centralized intermediaries. Applications choose their trust model.

3. **Authority provenance:** Accumulate's URL-based addressing (`acc://authority/path`) cryptographically binds data to controlling ADIs. Verifiers learn which entity authorized data without requiring real-world identity disclosure.

4. **Selective disclosure:** zkSTARK proofs demonstrate properties of committed data without revealing values. Combined with anchor proofs replacing signatures, this enables private authorization where systems verify "someone with property P is authorized" without learning who.

The architecture addresses efficiency and privacy challenges simultaneously. Zero-knowledge predicates prevent front-running, protect user privacy, and enable compliant identity verification—all while maintaining sub-linear verification costs.

Reference implementation is provided in Cairo for StarkNet deployment. We identify deployment phases and open research problems for community contribution.

---

## References

[1] Accumulate Network. (2022). Accumulate Protocol Whitepaper. https://accumulatenetwork.io

[2] Ben-Sasson, E., Bentov, I., Horesh, Y., & Riabzev, M. (2018). Scalable, transparent, and post-quantum secure computational integrity. *IACR Cryptology ePrint Archive*.

[3] Zhang, F., et al. (2020). DECO: Liberating Web Data Using Decentralized Oracles. *ACM CCS*.

[4] Zhang, F., Cecchetti, E., Croman, K., Juels, A., & Shi, E. (2016). Town Crier: An Authenticated Data Feed for Smart Contracts. *ACM CCS*.

[5] StarkWare. (2024). The Cairo Programming Language Book. https://book.cairo-lang.org

[6] Cohen, B., & Pietrzak, K. (2019). The Chia Network Blockchain. *Chia Network*.

[7] Bonneau, J., et al. (2015). SoK: Research Perspectives and Challenges for Bitcoin and Cryptocurrencies. *IEEE S&P*.

[8] Lerner, S. D., et al. (2024). BitVMX: A CPU for Bitcoin. *RootstockLabs*. https://bitvmx.org

[9] Mina Foundation. (2020). Mina Protocol: A Succinct Blockchain. https://minaprotocol.com

[10] Breidenbach, L., et al. (2021). Chainlink 2.0: Next Steps in the Evolution of Decentralized Oracle Networks. *Chainlink Labs*.

---

## Appendix A: Cairo Reference Implementation

See accompanying file: `2026-03-12-accumulate-cairo-contract.cairo`

Key contracts:
- `AccumulateVerifier`: Anchor registration and receipt verification
- `PrivateOracle`: Threshold and range proofs over committed data

---

## Appendix B: Test Vectors

To be generated from Accumulate testnet. Required:
- Sample chain with 1000+ entries
- Receipt proving entry at various positions
- Anchor hash matching testnet state

---

## Acknowledgments

We thank the Accumulate and StarkNet communities for technical input. This work proposes an architecture for community implementation and welcomes collaboration.
