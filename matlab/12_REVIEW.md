# Revisao manual: correcoes e execucao pendente

## Correcoes desta rodada

- `linear_discriminability`: `nb=size(b,1)`; regressao com grupos de tamanhos diferentes e covariancia calculada independentemente.
- `spike_bin_counts`: tolerancia de 1e-9 na contagem de bins completos; borda final limitada por `stop_s` para preservar exclusao do endpoint.
- `spike_waveform_average`: `reshape` preserva canais x amostras quando ha um canal; regressao verifica tambem o consumo por `spike_waveform_snr` (que nao usa squeeze).
- `peri_event_histogram`, `spike_bin_counts` e `spike_counts_edges`: trens vazios aceitos, timestamps nao finitos descartados e bins semiabertos. Eventos de alinhamento nao finitos continuam invalidos.

## Tentativa de execucao em 2026-10-11

As cinco chamadas a `matlab -batch` foram impedidas antes de iniciar o MATLAB:
executavel `matlab` ausente. Nenhum destes testes passou ou falhou numericamente.

| Teste | Estado |
|---|---|
| smoke_arsenal | Nao executado: runtime ausente |
| smoke_population | Nao executado: runtime ausente |
| smoke_ephys_methods | Nao executado: runtime ausente |
| smoke_consensus_methods | Nao executado: runtime ausente |
| smoke_bosc_circ_glm | Nao executado: runtime ausente |

## Pontos da revisao ainda abertos

- Oferecer folds contiguos no crossvalidated_ridge_decoder; manter avaliacao temporal explicita.
- Uniformizar seed/stream em jitter, randomizacao de fase, EEMD e CP/ALS, sem alterar o RNG global.
- Permitir bandas excluidas do ajuste de fundo do BOSC e avaliar o caso da senoide de 8 Hz.
- Conferir no artigo Heller & David a ordem PCA/projecao na reducao direcionada.
- Usar a forma dual de Tikhonov quando houver mais fontes que eletrodos.
- Vetorizar permutation_entropy, preservando a convencao para empates.
- Acrescentar normalizacao, seed, parada e testes de recuperacao mais fortes ao CP/ALS.
- Verificar os DOI sugeridos para Lachaux (1999) e Vinck (2011) antes de modificar METHODS.tsv.

Estes itens nao foram resolvidos pela correcao imediata dos bugs acima.

## Revisao para os livros (2026-10-12)

Leitura linha a linha das 88 funcoes. Todas tem especificacao em
`books/electrophysiology/chapters/12_method_specifications.tex`, que cita
resultados `ARS-*` provados em `books/formal_foundations/chapters/10_arsenal/`.
`books/tools/arsenal_registry.py --check` (em `make -C books check`) mantem
funcoes, especificacoes, teoremas e `books/shared/theorems.yml` sincronizados.

`tests/check_arsenal_identities.m` confere numericamente os teoremas contra o
codigo. Executado e aprovado no GNU Octave 8, com um substituto externo de
`histcounts`; ainda nao executado no MATLAB.

Achados adicionais (documentados nas especificacoes; nao corrigidos no codigo):

- Indice de amostra a partir de timestamp: `spike_triggered_average` (agora `event_triggered_average`) usa
  round(t*fs)+1 (amostra mais proxima); `spike_field_coherence` usa
  floor(t*fs)+1 (amostra que contem t); `spike_field_ppc` interpola.
- `irasa_decomposition`: valido apenas abaixo de fs/(2*max h); devolve todas as
  frequencias ate Nyquist.
- `reduced_rank_regression`: minimo exato com posto restrito so com ridge 0;
  com ridge, "ridge e depois projecao" e heuristica (ARS-RRR-001).
- `phase_slope_index`: o sinal depende da convencao de `cpsd`; fixar com teste
  de atraso conhecido.
- `phase_lag_index`: sin(pi) ~ 1.2e-16 em ponto flutuante, entao diferencas
  exatamente +/-pi contam como defasadas.
- `empirical_mode_decomposition`: os dois envelopes sao presos ao sinal nas
  extremidades.
- `poisson_spike_glm`: o corte de eta em [-20,20] muda o objetivo quando ativo.
- `decode_trials`: folds sem todas as classes no treino sao pulados em silencio;
  `seed` e registrado mas nao usado (procedimento deterministico); softmax de
  escores de minimos quadrados nao e probabilidade calibrada.

## Ordenacao da documentacao e alinhamento generico (2026-10-20)

Os arquivos `.md` de `matlab/` passaram a seguir a ordem dos dados, com
prefixo numerico (`00_CONVENTIONS` a `12_REVIEW`); o README e o indice.
Cada uma das 131 funcoes de `path/` esta documentada em exatamente um
capitulo. `EVENT_ALIGNMENT.md` virou `06_EVENT_ALIGNMENT.md` e deixou de
supor que o sinal alinhado e uma contagem de spikes.

Renomeacoes (sem aliases; chamadas externas, por exemplo em
`paper_con2phys`, precisam ser atualizadas):

| Antes | Depois | Mudanca |
|---|---|---|
| `spike_raster_sparse` | `sparse_count_matrix` | qualquer timestamp rotulado; campos `events_input/kept/discarded` |
| `event_aligned_raster` | `event_aligned_segments` | qualquer sinal linha x amostra, denso ou esparso; varias linhas; `'Anchor'` (`containing`/`nearest`); `'SampleDim'` 1 ou 2 |
| `plot_event_raster` | `plot_event_aligned` | `'Scale'` `auto`/`log1p`/`linear`, `'ValueLabel'`; aceita LFP |
| `spike_triggered_average` | `event_triggered_average` | mesma conta; agora delega a `event_aligned_segments` |

`ripple_candidate_events` ganhou a coluna `peak_s` (maximo do envelope),
acrescentada ao fim da tabela. `decode_trials`, `decoded_mi`,
`greedy_modularity`, `spike_bins` e `trial_features` ganharam texto de
ajuda no estilo das demais. `test_event_alignment.m` cobre os novos casos
(linhas multiplas, LFP denso, `SampleDim`, vetores, ancoras, igualdade com
o laco explicito do STA); os valores esperados foram conferidos por um
espelho numerico, nao pelo MATLAB.

Achados desta revisao (documentados nos capitulos; nao corrigidos no codigo):

- `interval_jitter_surrogate` e `jitter_spike_surrogate` sao numericamente
  identicas.
- Timestamps nao finitos: os contadores descartam; `firing_rate`,
  `interspike_intervals` e `spike_field_coherence` rejeitam.
  `spike_field_coherence` tambem rejeita eventos fora do registro.
- `greedy_modularity` devolve apenas Q, sem rotulos de comunidade.
- `plot_event_aligned` nao e exercitada por nenhum teste (sem graficos no CI).
- Sem teste de regressao: `phase_slope_index`, os geradores de surrogates
  exceto deslocamento circular, randomizacao de fase e jitter, os testes
  Monte Carlo, os folds de validacao e quase todo o bootstrap.

MATLAB nao estava disponivel nesta sessao; nenhum teste foi executado.
