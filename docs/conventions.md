# Convenções de unidades e eixos

Contrato compartilhado entre a referência MATLAB (`matlab/`), o núcleo Rust
(`crates/neuronal-core`) e a API Python (`neuronal`). Um método só é
considerado portado quando concorda com a referência nos valores **e** neste
contrato.

As convenções seguem o que o arsenal MATLAB já usa (`srate`, `segment_seconds`,
`halfwidth_s`, `channels x samples`), para que a paridade seja direta.

## Unidades

| Grandeza                | Unidade | Sufixo de nome   | Tipo Rust      |
| ----------------------- | ------- | ---------------- | -------------- |
| Duração, tempo, janela  | s       | `_s`             | `Seconds`      |
| Taxa de amostragem, freq. | Hz    | `_hz` / `fs`     | `Hertz`        |
| Passo em ms (legado)    | ms      | `_ms`            | `Milliseconds` |
| Potencial               | µV      | `_uv`            | —              |

- Unidades ficam no **nome** do parâmetro na fronteira Python/MATLAB e no
  **tipo** dentro do núcleo Rust. Os construtores (`Seconds::new`, etc.) rejeitam
  zero, negativo, NaN e infinito; funções que recebem esses tipos não revalidam.
- Conversões entre unidades são falíveis (`Milliseconds::from_seconds`,
  `Seconds::from_millis`); nunca saturam silenciosamente.
- Exceção atual: `time_axis(samples, dt_ms)` e `sampled_span(samples, dt_ms)`
  antecedem esta decisão e usam milissegundos, como o nome indica. Migrá-las
  para segundos é uma decisão em aberto.

## Eixos e layout

- Sinais multicanal: forma `(canal, tempo)`, `float64`, C-contíguos no Python
  (row-major). Um único canal continua `(1, tempo)` nas funções multicanal.
- Índices de amostra: zero-based em Rust/Python, one-based no MATLAB. A
  conversão acontece na fronteira, nunca dentro do método.
- Eixos de tempo começam em `0` e têm `t[i] = i * dt`; o número de amostras é
  sempre explícito, nenhum ponto final é inferido.
- Frequências retornadas vão de `0` a `fs / 2` inclusive.

## Erros

| Condição                         | Rust                     | Python          |
| -------------------------------- | ------------------------ | --------------- |
| Grandeza não finita/não positiva | `CoreError::NonPositive` | `ValueError`    |
| Resultado fora do intervalo finito | `CoreError::Overflow`  | `OverflowError` |
| Falha de alocação                | `CoreError::Allocation`  | `MemoryError`   |

## Fronteira Python

- Arrays retornados são `numpy.ndarray` donos do próprio buffer (o `Vec` do Rust
  é entregue ao NumPy sem cópia).
- O GIL é liberado durante o cálculo (`py.detach`).
