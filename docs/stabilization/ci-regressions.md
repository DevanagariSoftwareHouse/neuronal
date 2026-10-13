# Runtime-discovered regressions

Initial CI: https://github.com/ze-gois/neuronal/actions/runs/38332243363

- MATLAB R2024b Update 10 with Signal Processing Toolbox executes the ARS
  checks successfully but the subsequent script rejects the legacy generator.
  Replaced `rand('state',...)` with an explicitly selected twister and reset
  the generator before each script. No assertion removed.
- Rust formatting found one extra blank line in the inherited core; removed.
- Diff integrity found whitespace in the imported bibliography; stripped
  trailing whitespace only. Original import hashes remain historical evidence
  for the byte-for-byte import, not hashes of later editorial corrections.
- TSV final empty fields are semantic delimiters, not accidental whitespace.
  A scoped `.gitattributes` rule preserves their column count. Other whitespace
  checks and the no-gitlink/no-Lake-artifact checks remain enabled.

The Lean runtime failure and correction are in `formal-correspondence.md`.
