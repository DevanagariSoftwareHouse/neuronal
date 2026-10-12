# neuronal

Distribuição Python: `neuronal-rs`. Importação: `import neuronal`.

Pacote Python com núcleo numérico escrito em Rust. Esqueleto inicial para
simulação neuronal e, posteriormente, geração de registros extracelulares sintéticos.
Ainda não implementa neurônios LIF nem spike sorting.

## Estrutura

- `crates/neuronal-core`: núcleo Rust sem dependência de Python.
- `crates/neuronal-python`: interface PyO3; extensão `neuronal._native`.
- `python/neuronal`: API pública Python e tipos.
- `examples`: exemplos executáveis.
- `tests`: verificação da integração Python–Rust.

## Desenvolvimento

Requisitos: Rust estável (cargo/rustc), Python 3.10+ e compilador/linker do sistema.

```bash
python -m venv .venv
source .venv/bin/activate
python -m pip install 'maturin>=1.9,<2' 'pytest>=8'
maturin develop
python examples/time_axis.py
pytest
cargo fmt --all --check
cargo check --workspace
```

Exemplo:

```python
import neuronal

print(neuronal.time_axis(samples=5, dt_ms=0.1))
```

A função retorna uma lista Python; NumPy não é obrigatório nesta primeira etapa.
O número de amostras é explícito: o último instante é `(samples - 1) * dt_ms`.
Zero amostras produz uma lista vazia. O passo deve ser finito e positivo.

## Distribuição local

```bash
maturin build --release --out dist
python -m pip install dist/*.whl
```

A distribuição no PyPI se chama `neuronal-rs`; o módulo Python permanece
`neuronal` (`import neuronal`). A aceitação do nome será confirmada no upload.
Nenhum pacote foi publicado. Licença de distribuição: [MIT](LICENSE).

## Próxima entrega

Implementar LIF determinístico no núcleo, validar contra solução analítica e
expor potencial de membrana e tempos de disparo ao Python. Depois: populações,
entradas estocásticas e registros extracelulares com ground truth.

## Publicação

Veja [o guia de publicação](docs/publishing.md) para validar e publicar no PyPI.

## Pesquisa com JupyterLab

Veja [examples/README.md](examples/README.md) e o notebook
[01_hybrid_workflow.ipynb](examples/notebooks/01_hybrid_workflow.ipynb).

A preparação dos ambientes está em [scripts/README.md](scripts/README.md).

## Painel NiceGUI experimental

Nesta branch, NiceGUI é dependência do pacote. O painel reutilizável está em
`neuronal.panel.TimeAxisPanel`; veja
[02_nicegui_panel.ipynb](examples/notebooks/02_nicegui_panel.ipynb) para apresentação
no notebook e `python examples/panel.py` para execução no navegador.

## Livros do neuronal

Os [dois livros](books/README.md) pertencem a este projeto: eletrofisiologia
computacional com exemplos MATLAB e fundamentos matemáticos com Lean 4/Mathlib.
Fontes em `books/`, provas em `formal/lean/` e registros em `mathematics/`.
Compile com `make -C books all`; veja a [proveniência da migração](books/MIGRATION.md).
