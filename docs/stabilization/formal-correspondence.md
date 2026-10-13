# Logic correspondence review — 2026-10-13

Baseline: paper_con2phys `efd3d26eca266703e27156d067e2f72406ce36b0`,
`books/formal_foundations/chapters/00_language/02_logic.tex` (FNV `6b2fd5e6`).
Compared with neuronal integration `151e78fb627d470d7278ae5d35a212ce880b5bd5`.
The old chapter was recovered from Git and its fingerprint independently matched.
The diff adds sections after the existing null-hypothesis example and exercises;
the five original statements are unchanged. The current side-by-side panel and
all five Lean declarations were read individually.

| ID | Declaration | Review decision |
| --- | --- | --- |
| LOGIC-001 | deMorganAnd | Arbitrary propositions; both directions agree. English forward proof uses excluded middle, matching classical Lean. |
| LOGIC-002 | deMorganOr | Arbitrary propositions; each disjunct is refuted separately. Both directions constructive. |
| LOGIC-003 | contrapositive | Both directions retained; converse explicitly classical in English and Lean. No causal implication claimed. |
| LOGIC-004 | notForall | Arbitrary type and predicate, including empty type; failure of a universal is existence of a counterexample classically. Predicate name R/P is immaterial. |
| LOGIC-005 | notExists | Arbitrary type and predicate; both directions constructive and empty domain allowed. |

Classification: additive exposition outside the mapped statements, not a change
to their hypotheses or conclusions. Fingerprints renewed only after this review.
No Lean declaration or proof was altered. Historical kernel evidence remains
historical; a successful current Formal Lean run is still required before merge.
New chapter propositions and ARS statements are not covered by these five proofs.
