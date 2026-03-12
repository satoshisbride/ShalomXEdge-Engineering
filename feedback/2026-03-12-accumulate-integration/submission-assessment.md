# Paper Submission Assessment

**Paper:** Privacy-Preserving Batch Oracles: Hierarchical Proofs via Accumulate and zkSTARK

**Date:** 2026-03-12

---

## Executive Summary

The paper presents a legitimate technical architecture combining Accumulate's hierarchical batch proofs with zkSTARK privacy. The contribution is real but architectural—no novel cryptography, no implementation, no benchmarks. This limits academic venue options but makes it well-suited for grants, industry publication, and workshop discussion.

---

## Science of Blockchain Conference (SBC) 2026

### Main Track

| Criterion | Assessment | Score |
|-----------|------------|-------|
| Novel contribution | Architecture, not primitives | Weak |
| Formal rigor | Cites established results, proves composition | Adequate |
| Implementation | None | Fail |
| Evaluation | No benchmarks | Fail |
| Writing quality | Clear, well-structured | Strong |

**Odds of acceptance: 10-15%**

**Likely outcome:** Desk reject or early reject. SBC main track expects systems papers with implementation and evaluation, or theory papers with novel proofs. This paper is neither—it's a design paper.

**Reviewer concerns (predicted):**
- "No implementation or evaluation"
- "Security reduces entirely to existing work"
- "What is the research contribution beyond integration?"

### Workshop Track

| Criterion | Assessment | Score |
|-----------|------------|-------|
| Interesting direction | Yes—batch proofs + privacy + authority | Strong |
| Discussion potential | High—open problems identified | Strong |
| Completeness | Architecture complete, implementation future work | Adequate |

**Odds of acceptance: 30-40%**

**Better fit:** Workshop papers can present work-in-progress and architectural ideas. The open problems (Section 7.2) provide discussion fodder.

**Recommended workshops:**
- DeFi security workshops
- Privacy in blockchains
- Interoperability/bridges

---

## Alternative Academic Venues

### Financial Cryptography (FC)

| Fit | Assessment |
|-----|------------|
| Topic relevance | Strong—oracles, DeFi, privacy |
| Rigor expectations | Lower than SBC for systems |
| Industry track | Good fit for architectural work |

**Odds: 25-35%** for industry track

### IEEE Blockchain

| Fit | Assessment |
|-----|------------|
| Topic relevance | Strong |
| Rigor expectations | Moderate |
| Systems focus | Less demanding than SBC |

**Odds: 30-40%**

### ACM CCS Workshop (e.g., WPES, DeFi)

| Fit | Assessment |
|-----|------------|
| Topic relevance | Privacy + blockchain |
| Length | Short paper acceptable |
| Novelty bar | Lower for workshops |

**Odds: 35-45%**

### arXiv Preprint

| Fit | Assessment |
|-----|------------|
| Barrier | None |
| Visibility | High in crypto community |
| Citeability | Immediate |

**Recommendation:** Post regardless of other submissions. Establishes priority, enables citation.

---

## Non-Academic Uses

### Grant Applications

| Program | Fit | Notes |
|---------|-----|-------|
| StarkNet Seed Grants | Excellent | Cairo implementation, StarkNet ecosystem |
| StarkNet Growth Grants | Good | Needs prototype first |
| Chia Cultivation Fund | Good | VDF/anchoring angle |
| Ethereum Foundation | Moderate | Less direct fit |

**Recommendation:** Strong candidate for StarkNet grants. The paper serves as technical specification for grant proposal.

**What to emphasize:**
- Concrete Cairo implementation provided
- Clear roadmap (Section 7.1)
- Accumulate integration as differentiator
- Privacy use cases (credit, identity, front-running)

### Technical Blog Posts

| Platform | Fit | Audience |
|----------|-----|----------|
| StarkNet blog | Excellent | Cairo developers |
| Accumulate blog | Excellent | Accumulate community |
| Medium/Mirror | Good | Broader crypto audience |
| Company engineering blog | Good | Technical credibility |

**Recommendation:** Publish condensed version (2000-3000 words) on StarkNet or Accumulate blog. Establishes expertise, attracts collaborators.

### Whitepaper / Documentation

| Use | Fit |
|-----|-----|
| Project technical spec | Excellent |
| Integration guide | Good (needs expansion) |
| Investor materials | Good (needs non-technical summary) |

**Recommendation:** Paper serves as technical whitepaper for the project. Add executive summary for non-technical readers.

---

## Strengths

1. **Clear value proposition:** Four distinct properties (batch efficiency, trust minimization, authority provenance, selective disclosure)

2. **Proper citations:** Security reduces to established results with correct attribution (Merkle, STARK, MMR lineage)

3. **Concrete architecture:** Not vague—specific data structures, algorithms, Cairo code

4. **Honest scope:** Acknowledges limitations, identifies future work

5. **Novel combination:** While primitives aren't new, the integration is genuinely useful

---

## Weaknesses

1. **No implementation:** Cairo code is reference/sketch, not deployed

2. **No benchmarks:** Gas estimates are speculative

3. **No formal proofs of novel claims:** Composition proof is informal

4. **Unknown authors:** No academic track record (for academic venues)

5. **Missing test vectors:** "To be generated" in Appendix B

---

## Recommendations by Goal

### Goal: Academic Publication

1. Build prototype on StarkNet Sepolia
2. Generate real benchmarks
3. Submit to workshop (FC, CCS workshop, IEEE)
4. If accepted, expand for main track later

**Timeline:** 3-6 months

### Goal: Grant Funding

1. Submit paper as-is to StarkNet Seed Grants
2. Use architecture.md as technical specification
3. Propose 3-month prototype timeline
4. Budget for Cairo developer if needed

**Timeline:** Immediate

### Goal: Industry Credibility

1. Post to arXiv immediately
2. Publish blog post on StarkNet/Accumulate
3. Present at meetups/conferences
4. Open-source Cairo contract

**Timeline:** 1-2 weeks

### Goal: Attract Collaborators

1. Post to arXiv
2. Share in StarkNet Discord, Accumulate community
3. Identify Cairo developers interested in oracles
4. Offer co-authorship for implementation work

**Timeline:** 2-4 weeks

---

## Summary Table

| Venue/Use | Odds/Fit | Effort Required |
|-----------|----------|-----------------|
| SBC main track | 10-15% | High (need implementation) |
| SBC workshop | 30-40% | Low (submit as-is) |
| FC industry track | 25-35% | Low |
| IEEE Blockchain | 30-40% | Low |
| CCS workshop | 35-45% | Low |
| arXiv | 100% | None |
| StarkNet grant | 60-70% | Low |
| Blog post | 100% | Low |
| Technical whitepaper | 100% | None (already done) |

---

## Bottom Line

**Don't submit to SBC main track.** The paper lacks implementation and benchmarks required for a top systems venue.

**Do submit to:**
- arXiv (immediately, establishes priority)
- StarkNet grants (strong fit, clear deliverables)
- Workshop venues (FC, CCS workshops)

**Best ROI:** Use paper for grant application. If funded, build prototype, then submit to academic venue with real results.
