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

The MATLAB arsenal and questionnaire analysis stay in `paper_con2phys`. References
to `arsenal/`, `path/` and questionnaire scripts in the manuscripts refer to that
external companion; they are not neuronal Python/Rust APIs. The books build without
a checkout of paper_con2phys. The separate MATLAB and Lean editorial roles remain.

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
