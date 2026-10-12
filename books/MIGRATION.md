# Migration to neuronal

The canonical editorial home of both books is `ze-gois/neuronal`.
Imported from `ze-gois/paper_con2phys`, branch `feat/lean-formal-inventory-pilot`,
commit `97e1375116ab9281457f0fc74cdf045a863b58b0` (including work beyond its main branch).
`migration-source.json` records original source hashes. Original commit history
and verification-run URLs remain in the source repository; this import does not
rewrite that history or claim a new Lean verification. The original MIT notice
is preserved in `books/LICENSE`.

The import includes both manuscripts, bibliography, editorial audits, theorem
registries, Lean sources and lockfile, MATLAB/Lean examples, build tooling and CI.
Generated `.lake/` files and build outputs are deliberately excluded. Lean module
names remain `Con2physFormal` to preserve declaration identifiers and evidence.

The reusable MATLAB arsenal now lives in `neuronal/matlab/`, including its
methods catalogue, references, research notes and tests. Its original file hashes
are recorded in `matlab/migration-source.json`. The latest editorial bibliography
is retained too. Questionnaire-specific scripts remain in `paper_con2phys`, whose
startup loads `neuronal/matlab/path` from a sibling checkout or `NEURONAL_ROOT`.
The separate MATLAB and Lean editorial roles remain.

Import neuronal first, then merge the source-repository retirement PR. Do not
continue editing the old manuscript branch after that cutover.

## Validation at import

`make -C books all` compiled both PDFs successfully. Source checks validated
82 TeX files and 48 bridges, language boundaries passed, and the curated graph
and eight-bridge inventory checks passed. No MATLAB or Lean kernel execution
was performed in this migration environment.

Known inherited blocker: `python3 mathematics/audit_formal.py --check` reports
English-source fingerprint drift for LOGIC-001 through LOGIC-005. The imported
logic chapter was expanded after its recorded verification. Fingerprints and
verification evidence are preserved, so CI continues to report the discrepancy
until the correspondence is reviewed. This is not a successful full Lean gate.

## MATLAB directory migration

All 82 method function files are byte-for-byte identical to the source main
revision recorded in `matlab/migration-source.json`. Only the MATLAB README
and one smoke-test invocation comment were adapted among the original 97 files.
A startup script and original license notice were added; the later editorial
`all.bib` was also preserved. MATLAB is unavailable here, so the updated
questionnaire integration test has not been executed.

The import preserves empty final TSV fields and the original bibliography
whitespace; these trigger `git diff --check` whitespace warnings in imported
data files. Edited source and documentation pass whitespace checks.
