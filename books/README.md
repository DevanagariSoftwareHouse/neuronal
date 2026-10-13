# neuronal books

Two books, two different kinds of mathematical evidence:

| Book | Entry point | Intended role | Current state |
|---|---|---|---|
| [Computational Electrophysiology](electrophysiology/main.tex) | `books/electrophysiology/main.tex` | MATLAB-linked methods, simulations, and scientific interpretation | 98 pages; every chapter expanded with proofs, derivations, worked examples and exercises (Oct 2026); MATLAB executable examples still need expansion |
| [Formal Foundations](formal_foundations/main.tex) | `books/formal_foundations/main.tex` | Mathematics from ordinary language, eventually checked in Lean 4 / Mathlib | 176 pages; all chapters expanded with new proved results and exercises (Oct 2026); five verified Lean 4 logic proofs side by side with English; remaining formalizations pending |

No theorem is called formally proved by software unless it builds with Lean. Neither a MATLAB numerical test nor a TeX proof constitutes a machine-checked theorem.

## Build

From repository root:

```sh
make -C books check
make -C books all
make -C books electrophysiology
make -C books formal_foundations
```

Outputs: `books/electrophysiology/build/main.pdf` and `books/formal_foundations/build/main.pdf`.

Build commands are maintained exclusively in `books/`; the former `latex/` forwarding directory has been removed.

## Shared registry and code paths

- [shared/theorems.yml](shared/theorems.yml) is a seed registry for stable theorem identifiers; it does not claim all catalogue entries are formally proved.
- The reusable MATLAB methods live in [matlab/path](../matlab/path); questionnaire-specific scripts remain in paper_con2phys.
- [formal_foundations/lean](formal_foundations/lean) contains the pinned Lean/Mathlib project and verified logic pilot; [formal_registry.json](formal_foundations/mathematics/formal_registry.json) and [audit_formal.py](formal_foundations/mathematics/audit_formal.py) track the correspondence and pending work.
- Every function in [matlab/path](../matlab/path) is specified in [12_method_specifications.tex](electrophysiology/chapters/12_method_specifications.tex) and depends on `ARS-*` results proved in [formal_foundations/chapters/10_arsenal](formal_foundations/chapters/10_arsenal). `python3 tools/arsenal_registry.py --check` (part of `make check`) keeps functions, specifications, theorems and `shared/theorems.yml` in step; `--write` regenerates the registry block.
- [examples/matlab](../examples/matlab) is the designated place for future reproducible textbook demonstrations.
- [examples/lean](../examples/lean) is reserved for future verified examples.

The original editorial text is preserved in each migrated book. Some historical mentions of `latex/` or provisional method maps remain as provenance, not canonical build paths.

## Source-language separation

See [EDITORIAL_CONTRACT.md](EDITORIAL_CONTRACT.md). Computational
Electrophysiology embeds MATLAB files from `examples/matlab/`, while
Formal Foundations embeds Lean files from `books/formal_foundations/lean/`. A dedicated
source-boundary check runs before either PDF build.
