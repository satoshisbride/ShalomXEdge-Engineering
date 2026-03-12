# Formal Security Analysis

## Approach

We do not reprove established cryptographic results. We:
1. Cite standard Merkle tree security
2. Cite STARK soundness and zero-knowledge
3. Show our construction reduces to these primitives
4. Prove only what's novel: composition and authority binding

---

## Cited Results

### Merkle Tree Security

**Theorem (Merkle, 1980; see [1]):** For a Merkle tree constructed with hash function H, if H is collision-resistant, then an adversary cannot produce a valid proof for an element not in the tree except with negligible probability.

Formally: Given tree T with root r and elements {e₁...eₙ}, no PPT adversary can output (e*, π*) where e* ∉ T and Verify(r, e*, π*) = 1, except with probability ≤ Adv^CR_H.

**Merkle Mountain Range Variant:** Accumulate uses a Merkle Mountain Range (MMR) structure [4, 5] rather than a balanced tree. MMR is an append-only structure invented by Peter Todd [5] for Bitcoin UTXO commitments, adopted by Accumulate [4] for chain state management. Cevallos [6] provides recent formal analysis of MMR security properties. Sub-trees combine as they reach equal height, requiring only log₂(n) storage. Security still reduces to collision resistance—the proof path verification is equivalent to standard Merkle proofs.

**Application to Accumulate:** Accumulate receipts are MMR proofs using SHA-256. Receipt soundness follows from [1, 4, 5].

### STARK Security

**Theorem (Ben-Sasson et al., 2018 [2]):** STARK proofs satisfy:
- **Soundness:** No PPT adversary can produce accepting proof for false statement except with probability 2^(-λ)
- **Zero-Knowledge:** Verifier learns nothing beyond statement truth

**Application:** Cairo programs compile to STARK proofs. Properties inherited directly.

---

## Novel Claims Requiring Proof

Only two claims are specific to our construction:

### Claim 1: Authority Binding

**Statement:** Data at URL `acc://adi/path` can only be written by keys authorized by ADI `acc://adi`.

**Proof:** By Accumulate protocol specification:
1. Each ADI has associated key pages defining authorized signers
2. Transactions modifying `acc://adi/*` require valid signature from key page
3. Signature scheme (Ed25519) is EUF-CMA secure [3]
4. Therefore: unauthorized write requires forging signature or compromising key

This is authentication, not a novel cryptographic claim. Security reduces to signature scheme security. □

### Claim 2: Composition

**Statement:** Verifying an Accumulate receipt, then proving a predicate over the receipt's contents via STARK, preserves both soundness and zero-knowledge.

**Proof sketch:**

Let R = Accumulate receipt verification (deterministic, public)
Let S = STARK proof of predicate P over committed value

The composed system runs:
1. Verify(receipt, anchor) → accept/reject
2. If accept: STARK.Prove(P(value), commitment) → π

**Soundness:**
- If receipt is invalid, step 1 rejects (Merkle soundness)
- If receipt is valid but P(value) is false, step 2 cannot produce accepting proof (STARK soundness)
- Composition: Adversary must break either Merkle OR STARK soundness

**Zero-Knowledge:**
- Receipt verification is public (no secrets)
- STARK proof reveals only P(value), not value (STARK ZK)
- No information leakage between layers since receipt is public input to STARK

The layers compose because:
- Layer 1 output (receipt validity) is boolean, public
- Layer 2 takes public input (commitment from receipt) and private witness (value)
- Standard composition of public preprocessing + ZK proof □

---

## Security Model (For Completeness)

### System Model

- **Accumulate Network:** DPoS network anchoring to Bitcoin
- **Anchor:** Merkle root of Accumulate state, committed to target chain
- **Receipt:** Merkle proof from entry to anchor
- **Verifier Contract:** Cairo contract on StarkNet

### Adversary Model

Adversary A can:
- Control minority of Accumulate validators (< 1/3)
- Observe all on-chain transactions
- Submit arbitrary receipts and proofs to verifier

Adversary A cannot:
- Break SHA-256 collision resistance
- Break STARK soundness
- Forge Ed25519 signatures

### Security Games

**Game 1: Receipt Forgery**
1. Challenger maintains honest Accumulate state S
2. A may query receipts for any entry in S
3. A outputs (entry*, receipt*, anchor)
4. A wins if: entry* ∉ S AND Verify(receipt*, entry*, anchor) = 1

**Theorem:** Pr[A wins Game 1] ≤ Adv^CR_SHA256

**Proof:** Reduction to Merkle security. See [1]. □

**Game 2: Predicate Forgery**
1. Challenger commits value v as c = Commit(v, r)
2. A gets c and oracle access to STARK.Prove for true predicates
3. A outputs (P, π) where P(v) = false
4. A wins if: STARK.Verify(P, c, π) = 1

**Theorem:** Pr[A wins Game 2] ≤ 2^(-λ)

**Proof:** Direct from STARK soundness [2]. □

**Game 3: Witness Extraction**
1. Challenger commits value v as c = Commit(v, r)
2. A gets c and proof π that P(v) = true
3. A outputs guess v'
4. A wins if: v' = v

**Theorem:** Pr[A wins Game 3] ≤ Pr[random guess] + negl(λ)

**Proof:** STARK zero-knowledge [2] ensures π reveals nothing beyond P(v). Commitment hiding ensures c reveals nothing. □

---

## References

[1] Merkle, R. (1980). Protocols for Public Key Cryptosystems. IEEE Symposium on Security and Privacy.

[2] Ben-Sasson, E., Bentov, I., Horesh, Y., & Riabzev, M. (2018). Scalable, transparent, and post-quantum secure computational integrity. IACR Cryptology ePrint Archive.

[3] Bernstein, D. J., et al. (2012). High-speed high-security signatures. Journal of Cryptographic Engineering.

[4] Accumulate Network. (2022). Accumulate Protocol Whitepaper. Section 4: Consensus and Security.

[5] Todd, P. (2016). Making UTXO Set Growth Irrelevant With Low-Latency Delayed TXO Commitments. https://petertodd.org/2016/delayed-txo-commitments

[6] Cevallos, A. (2025). The Merkle Mountain Belt. arXiv preprint. https://arxiv.org/abs/2511.13582

---

## Summary

| Claim | Proof Method | Novelty |
|-------|--------------|---------|
| Receipt soundness | Cite Merkle [1] | None |
| STARK soundness | Cite Ben-Sasson [2] | None |
| STARK zero-knowledge | Cite Ben-Sasson [2] | None |
| Authority binding | Reduce to EUF-CMA [3] | None |
| Composition | Simple argument above | Minor |

**Conclusion:** No novel cryptography. Security inherits from standard primitives. The contribution is architectural integration, not cryptographic.
