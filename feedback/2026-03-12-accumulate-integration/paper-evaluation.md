# Evaluation: BitDMX SBC 2026 Paper Submission

**Document:** zkSTARK-Infused Ethical Oracles: Expanding AnnabelleShalom-BitDMX as a Non-Speculative Derivative of BitVMX via Cairo and Collaborative Ecosystem Grants
**Authors:** Annabelle Shalom, with contributions from Christyanaviva (@actxdesign), Paul Snow
**Target:** Science of Blockchain Conference (SBC) 2026
**Evaluation Date:** 2026-03-12

## Summary

This paper is not suitable for SBC submission in its current form. It combines real technologies with incorrect technical details, unverified benchmarks, and no implementation evidence.

---

## Critical Technical Problems

### 1. Invalid Cairo Code

The pseudocode is not valid Cairo syntax:

| Issue | Paper Claims | Actual Cairo |
|-------|--------------|--------------|
| Function keyword | `func` | `fn` |
| Pointer syntax | `felt*` | Not valid in Cairo 2.0+ |
| Builtin function | `zkstark_verify` | Does not exist |
| Overall syntax | Mixed Cairo 0/1/invented | Should be consistent Cairo 2.0+ |

### 2. BitVMX Misrepresentation

**Paper claims:**
> "BitVMX compiles UPLC (Untyped Plutus Core) to RISC-V bytecode"

**Actual:**
BitVMX enables arbitrary RISC-V execution verified on Bitcoin through fraud proofs. It has no special relationship to UPLC or Cardano. The paper conflates multiple unrelated IOG projects.

### 3. Unsubstantiated Benchmarks

Claimed results (no methodology provided):
- 10s prover time for 10^6 entries
- 50ms verification time
- "5x vs. Chainlink baseline"

**Missing:**
- Test environment specifications
- Reproducible code or repository
- Comparison methodology
- Statistical analysis

### 4. No Novel Contribution

The O(N log N) prover / O(log² N) verifier complexity is standard zkSTARK behavior—not a contribution. The paper describes combining existing technologies without demonstrating any implementation.

---

## Structural Issues

| Issue | Problem |
|-------|---------|
| Marketing language | "Simon Sinek-inspired manifesto" inappropriate for technical papers |
| Business projections | "$2B TVL by 2030" belongs in pitch deck, not research |
| No implementation | Claims "MVP architecture" with no code repository |
| Citation quality | Twitter handles and self-references instead of peer-reviewed sources |
| Abstract format | "Engineering Abstract Manifesto" not a standard academic format |

---

## Factual Accuracy Assessment

| Component | Accuracy | Notes |
|-----------|----------|-------|
| zkSTARK claims | Accurate | Transparent setup, quantum resistance correct |
| Chia claims | Accurate | Proof-of-space/time, low energy correct |
| Accumulate claims | Accurate | But vague on integration details |
| BitVMX claims | Incorrect | Conflates with Cardano/UPLC |
| Integration claims | Unverified | No evidence any integration exists |
| Cairo code | Incorrect | Does not compile |
| Benchmark data | Unverified | No methodology or reproducibility |

---

## Verdict

**Not suitable for SBC submission.**

The paper reads as a concept pitch rather than research. It combines real technologies (zkSTARK, Cairo, Accumulate, Chia) with incorrect technical details, unverified benchmarks, and no actual implementation. The philosophical framing, while perhaps sincere, is inappropriate for a technical venue.

---

## Recommendations for Revision

1. **Build working prototype** before claiming benchmarks
2. **Fix Cairo code** to actually compile on Cairo 2.0+
3. **Correct BitVMX description** or remove entirely
4. **Remove business projections** and marketing language
5. **Add methodology** for any claimed measurements
6. **Identify novel contribution** beyond "combining existing tech"
7. **Use standard academic format** for abstract and structure
8. **Add code repository** with reproducible implementation
9. **Replace Twitter citations** with peer-reviewed sources

---

## References Checked

- [1] BitVMX: Paper does not accurately describe this project
- [2] Cairo Language: Pseudocode does not match actual syntax
- [3] Accumulate: Description is accurate but integration unverified
- [5] zkSTARK: Standard properties correctly described
- [6-7] Grant programs: Exist but paper provides no grant application details
