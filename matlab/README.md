# Métodos MATLAB — neuronal

**Status: rascunho exploratório, não validado para inferência científica.**

Este diretório contém funções MATLAB reutilizáveis extraídas das operações
matemáticas relevantes para métodos publicados em eletrofisiologia. A unidade
de implementação é **uma função pública por arquivo `.m`** em [path](path).
O arquivo [METHODS.tsv](METHODS.tsv) registra 97 entradas bibliográficas (incluindo 2 referências excluídas por escopo)
e associa artigos a primitivas, limitações e métodos ainda não reproduzidos.

## Um primer para aprender análise eletrofisiológica com a toolbox

O percurso começa com uma pergunta científica, explicita a quantidade a
estimar e acompanha sua construção até a interpretação. Os capítulos
combinam fundamentos, exemplos sintéticos pequenos e o uso das primitivas.
Para consultar argumentos e saídas exatos, use também `help nome_da_funcao`.

Cada capítulo de análise apresenta uma pergunta, a intuição e a expressão
matemática, um exemplo com mecanismo conhecido, o significado do resultado,
um caso que pode induzir erro e um exercício. Os capítulos de convenções,
armazenamento e revisão estabelecem as condições para aplicar esse percurso
com rastreabilidade. Os blocos intitulados “Toy experiment” ou “Toy example”
definem suas entradas; os exemplos com dados reais indicam pré-requisitos.
Execute cada exemplo em seu próprio workspace, a partir da raiz do repositório.

### Escolha uma primeira pergunta

| Pergunta | Percurso sugerido | Resultado a interpretar |
| --- | --- | --- |
| A atividade de um cluster muda entre condições? | 00 → 01 → 04 → 06 → 11 | Diferença de taxas com exposição e pareamento explícitos |
| Há atividade oscilatória em um intervalo? | 00 → 01 → 02 → 05 | Espectro, forma temporal e duração dos episódios |
| Dois sinais apresentam uma relação além do controle escolhido? | 02 → 05 → 07 → 10 → 11 | Efeito descritivo e comparação com um modelo nulo |
| A atividade populacional prediz uma condição nova? | 04 → 08 → 09 | Desempenho fora da amostra com separação adequada |

A inferência é planejada desde o capítulo 00. A ordem de leitura acompanha
a construção dos dados, mas não significa escolher a unidade experimental
somente depois de observar o resultado. Diferencie amostras, eventos,
clusters, canais, trials, sessões e animais em todas as etapas.

### Como usar um exemplo

1. Escreva o que espera observar antes de executar.
2. Confira dimensões, unidades, origem temporal e exposição.
3. Execute a configuração inicial e interprete cada saída.
4. Mude um parâmetro: ruído, tamanho amostral, janela ou dependência.
5. Identifique uma situação em que a interpretação inicial falha.
6. Só então adapte o exemplo a um recorte real, mantendo os identificadores.

Os exemplos são material de ensino e pontos de partida para validação.
Sua presença não significa execução confirmada ou equivalência com o
pipeline completo de um artigo. Consulte [12_REVIEW.md](12_REVIEW.md) para
o registro das verificações e limitações, e [11_INFERENCE.md](11_INFERENCE.md)
para separar eixo de reamostragem, dependência e construção do intervalo.

## Ordem de leitura

A documentação segue a ordem dos dados: armazenar e ler, limpar, reduzir a
spikes ou a sinais em banda, alinhar a eventos, relacionar, modelar e avaliar
incerteza. O desenho inferencial é definido desde o início. As funções de
[path](path) são apresentadas por família; os quatro aliases de compatibilidade
estão documentados no capítulo de alinhamento.

| # | Capítulo | Funções |
|---|---|---|
| 00 | [Convenções](00_CONVENTIONS.md) | unidades, origem temporal, bins semiabertos, layouts, RNG |
| 01 | [Armazenamento](01_STORAGE.md) | `neuronal_*` |
| 02 | [Pré-processamento](02_PREPROCESSING.md) | referências, `bandpass_lfp`, CSD, lead fields |
| 03 | [Spikes](03_SPIKES.md) | detecção, waveforms, qualidade de unidades |
| 04 | [Trens de spikes](04_SPIKE_TRAINS.md) | contagens, taxas, ISI, correlogramas, Fano, Victor-Purpura |
| 05 | [Espectros e oscilações](05_SPECTRA_OSCILLATIONS.md) | PSD, 1/f, IRASA, wavelets, ciclos, EMD, BOSC, ripples |
| 06 | [Alinhamento a eventos](06_EVENT_ALIGNMENT.md) | fontes de eventos, `event_aligned_segments`, médias disparadas, PETH |
| 07 | [Acoplamento](07_COUPLING.md) | coerência, PLV/PLI/wPLI, estatística circular, PAC, informação, Granger |
| 08 | [Populações](08_POPULATION.md) | PCA, dimensionalidade, assemblies, dDR, RRR, jPCA, CP |
| 09 | [Modelos e decodificação](09_MODELS_DECODING.md) | GLM de Poisson, filtros de acoplamento, decoders, folds |
| 10 | [Surrogates](10_SURROGATES.md) | geradores nulos, testes Monte Carlo |
| 11 | [Inferência](11_INFERENCE.md) | bootstrap, jackknife, permutação, validação |
| 12 | [Revisão](12_REVIEW.md) | correções, pendências, estado de execução |

O alinhamento a eventos é genérico: qualquer timestamp em segundos (estímulo,
comportamento, cruzamento de fase, excursão de envelope, ripple ou spike)
define o atraso zero, e qualquer sinal na grade de amostras (contagens
esparsas, LFP, envelope, fase) pode ser recortado em torno dele. As antigas
`spike_raster_sparse`, `event_aligned_raster`, `plot_event_raster` e
`spike_triggered_average` passaram a `sparse_count_matrix`,
`event_aligned_segments`, `plot_event_aligned` e `event_triggered_average`.
Os nomes antigos continuam disponíveis como wrappers que preservam os
metadados e as convenções de alinhamento existentes.

## Organização

```text
matlab/
  README.md                  índice (este arquivo)
  00_CONVENTIONS.md ... 12_REVIEW.md
  METHODS.tsv
  resources.tsv
  searches.tsv
  research/
    consensus_methodological_review.md
    consensus_citation_index.tsv
  references/
    population_geometry.bib
    large_scale_ephys.bib
    consensus_verified.bib
    bosc_circular_glm.bib
  path/
    welch_psd.m
    multitaper_psd.m
    ...
  tests/
    run_scientific_suite.m
    test_event_alignment.m
    smoke_arsenal.m
    smoke_population.m
    smoke_ephys_methods.m
    smoke_consensus_methods.m
    smoke_bosc_circ_glm.m
    ...
  figures/
```

O diretório `path/` deve ser adicionado ao MATLAB path **na sessão que executa
os scripts**. O nome adotado pelo projeto e `path`, em minusculas.

```matlab
run('matlab/neuronal_startup.m') % a partir da raiz de neuronal
% Ou use um caminho absoluto, sem supor o current working directory.
```

Os scripts de `paper_con2phys` inicializam estes caminhos por `a00_startup`,
com `neuronal` em um checkout irmão ou indicado por `NEURONAL_ROOT`. Q08 reutiliza
`pairwise_phase_consistency`, e o binning do questionario reutiliza
`spike_counts_edges`. As primitivas recebem argumentos explicitos.

## Exemplo com o dataset carregado

```matlab
% Execute a rotina de carregamento original antes desta célula.
fs = data.srate;            % CON2PHYS LFP: 500 Hz
x = double(data.lfp_3(1,1:round(30*fs))); % Um canal, apenas 30 segundos
[f,p] = welch_psd(x,fs,4,.5);
aperiodic = aperiodic_slope(f,p,[2 180],[48 52;58 62]);
theta = bandpass_lfp(x,fs,[4 10],4);
[phase,amplitude] = analytic_phase(theta);
cycles = cycle_by_cycle(theta,fs);

% Somente spikes já extraídos; timestamps em segundos:
unit_id = data.waveform_cluster(1);
t = double(data.spike_timestamp(data.spike_cluster==unit_id));
rate = firing_rate(t,0,size(data.lfp_3,2)/fs);

% Alinhamento genérico: o mesmo recorte serve para spikes e para LFP.
stim = [data.behavior.trials.stim_start];
[counts,ids] = sparse_count_matrix(t,ones(size(t)),fs,size(data.lfp_3,2));
psth = event_aligned_segments(counts,stim,fs,[-.5 .5],1);
erp = event_aligned_segments(x,stim(stim<30),fs,[-.5 .5]);
sta = event_triggered_average(x,t(t<30),fs,.2,.2);
```

Ao selecionar uma unidade, confira o vínculo entre cluster, brain area e timestamps.
Não derive duração do registro com `numel` sobre uma matriz multicanal.

## Contratos e limites

Versão completa em [00_CONVENTIONS.md](00_CONVENTIONS.md).

1. Funções usam valores e parâmetros explícitos; não acessam `data` nem
   variáveis do workspace por conta própria. Timestamps são segundos;
   amostragem em Hz; fase em radianos.
2. LFP CON²PHYS tem Nyquist de **250 Hz**. O spike detector opera apenas
   sobre sinal broadband na taxa real de aquisição, não sobre LFP a 500 Hz.
3. `spectral_peak_candidates` e `aperiodic_slope` **não** implementam
   o algoritmo completo FOOOF/specparam. `cycle_by_cycle` omite critérios
   de bursts. `current_source_density` é diferença finita, não iCSD.
4. `irasa_decomposition`, `empirical_mode_decomposition` e
   `ensemble_empirical_mode_decomposition` são formulações exploratórias,
   não reproduções auditadas dos artigos.
5. `template_match_waveforms` **não é Kilosort4**, e
   `population_pca` **não é** GPFA, LFADS, jPCA ou dPCA.
6. `modulation_index`, Granger, informação mútua e transfer entropy
   demandam surrogates, análise de viés e pressupostos específicos antes
   de conclusões sobre acoplamento, direção ou causalidade.
7. Processar LFP inteiro pode consumir muitos GiB: passar **blocos** de
   canais; não assumir que todas as funções são streaming ou memmap-ready.
8. Para inferência em múltiplos animais, o animal deve ser unidade
   experimental, não milhões de bins pseudorreplicados.

## Famílias presentes

Resumo por família; o capítulo correspondente traz exemplos, contratos e testes.

- **Espectro, oscilações e separação:** Welch, multitaper, Morlet,
  fase/amplitude de Hilbert, inclinação 1/f simples, candidatos a picos,
  IRASA simplificado, EMD/EEMD exploratórios, ciclos, CSD, entropias.
- **Acoplamento LFP–LFP e spike–LFP:** PLV, PPC, PLI, wPLI,
  MI fase-amplitude, coerência, PSI simplificado e controles surrogates.
- **Eventos e unidades:** detecção de candidatos ripple, threshold de spikes
  (somente broadband), forma de onda, PCA de waveforms e template similarity.
- **Alinhamento a eventos:** contagens esparsas rotuladas, cruzamentos de fase,
  excursões de envelope, segmentos alinhados de qualquer sinal, média
  disparada por eventos (STA) e PETH.
- **Spike trains:** binning, firing rate, ISI, ACG, CCG, Fano e
  distância de Victor-Purpura.
- **Populações:** PCA, participation ratio, PCA de assemblies,
  expressão de assemblies e noise correlations.
- **Modelos e inferência:** GLM de Poisson aproximado, Granger VAR,
  informação mútua, transfer entropy plug-in, bootstrap iid,
  randomização pareada e jitter de spikes.

## Armazenamento binário e digests

Os descritores de arquivos, o catálogo persistente e o digest CON²PHYS
estão documentados em [01_STORAGE.md](01_STORAGE.md). A interface pública fica
em `matlab/path/` e os testes sintéticos em
`matlab/tests/test_neuronal_raw_storage.m`.
## Expansões bibliográficas e de métodos

Registro histórico de cada rodada de incorporação, na ordem em que ocorreram.

### Buscas bibliográficas em avaliação

O arquivo [searches.tsv](searches.tsv) registra as pesquisas externas que
alimentam a triagem metodológica, separadas dos artigos verificados de
[METHODS.tsv](METHODS.tsv). Uma busca compartilhada do Consensus
(`Métodos em eletrofisiologia computacional`) foi recuperada por
integração com a conta Consensus em 2026-10-11. O relatório original
com citações preservadas está em [research/consensus_methodological_review.md](research/consensus_methodological_review.md).
O relatório principal vincula **54 publicações** no índice
[research/consensus_citation_index.tsv](research/consensus_citation_index.tsv).
**10 referências** foram triadas individualmente e tiveram seus DOI e dados
editoriais conferidos, registradas em
[references/consensus_verified.bib](references/consensus_verified.bib).
As outras **44 referências** estão em estágio de rastreabilidade, não ainda
aprovadas para inclusão metodológica individual.

As duas funções adicionais são
`victor_purpura_distance.m` (métrica de edição para spike trains,
custo de deslocamento q/s) e `pac_mean_vector_length.m`
(estimativa de vetor médio fase-amplitude, bruta e normalizada).
As versões científicas completas de eMI, MRCSA, sliceTCA, PAC multitaper,
modelos calibrados de contaminação e testes de permutação clusterizados
permanecem explicitamente pendentes. A coluna status em METHODS.tsv não
deve ser interpretada como garantia de fidelidade à implementação publicada.

Teste sintético adicional:
```matlab
run('matlab/tests/smoke_consensus_methods.m')
run('matlab/tests/smoke_bosc_circ_glm.m')
```

### Geometria e dinâmica de populações (seleção complementar)

O catálogo `references/population_geometry.bib` reúne as 20 referências
fornecidas para esta expansão, com anos e autores revisados. Quatro trabalhos
já constavam no índice e foram atualizados sem duplicação por DOI.
Uma preprint de Heller & David (2021) é identificada como predecessora
do artigo publicado em 2022; Do & Yau (2010) e Juavinett et al. (2017)
permanecem registrados por proveniência, mas **fora do critério
de método de análise eletrofisiológica**.

Primitivas adicionadas, uma por arquivo: `eigenspectrum_powerlaw`,
`population_dimension_scaling`, `condition_marginalization`,
`targeted_dimensionality_reduction`, `linear_discriminability`,
`reduced_rank_regression`, `communication_subspace_projection`,
`jpca_dynamics`, `tensor_cp_als`, `gaussian_process_smoothing`,
`crossvalidated_ridge_decoder`.

#### Exemplo sintético

```matlab
rng(17)
x = randn(100,20);
labels = [zeros(50,1); ones(50,1)];
x(51:end,1) = x(51:end,1) + 2;

projection = targeted_dimensionality_reduction(x,labels);
result = crossvalidated_ridge_decoder(x,labels,5,1);
scale = population_dimension_scaling(x,[5 10 20],10,42);
```

**Não há equivalência automática** entre os arquivos pequenos e os
algoritmos originais. `tensor_cp_als` é apenas CP/ALS sem todo o
pipeline TCA, `gaussian_process_smoothing` não é GPFA,
`condition_marginalization` não é dPCA completo, `jpca_dynamics`
não reproduz todo o pipeline jPCA, e o decodificador ridge não é o
Gaussian-Process Multiclass Regression de Greenidge et al.

Para resultados publicáveis, selecionar posto, regularização, projeções
e hiperparâmetros exclusivamente no conjunto de treinamento. A estrutura
de trials deve ser preservada na validação cruzada para evitar leakage.

### Spike sorting em larga escala e field potentials

Os seis artigos checados nesta rodada estão em
[large_scale_ephys.bib](references/large_scale_ephys.bib).
O artigo de Buccino et al. (2026) já constava em METHODS.tsv e foi
atualizado, não duplicado. Recursos externos e seus estados de manutenção
constam em [resources.tsv](resources.tsv). Em particular, a antiga biblioteca
Allen ecephys_spike_sorting é **legada e sem manutenção**. O pipeline atual
da Allen Neural Dynamics utiliza SpikeInterface/Nextflow e permite Kilosort4.

**Funções novas (13):**

- `spike_refractory_violations`, `spike_presence_ratio`,
  `spike_sorting_agreement`, `spike_waveform_snr`,
  `spike_waveform_extraction`, `spike_waveform_average`;
- `common_median_reference`, `bipolar_reference_lfp`,
  `spike_field_coherence`, `multitaper_coherence`,
  `wavelet_coherence`;
- `field_potential_forward`, `field_potential_inverse_tikhonov`.

Essas funções são **primitivas**, não um sorter profundo, um pipeline
de Neuropixels ou implementações equivalentes ao Kilosort4 e ao SpikeInterface.
A comparação de eventos `spike_sorting_agreement` pressupõe que uma unidade
de referência já esteja pareada a uma unidade predita; não resolve matching
entre múltiplas unidades. `spike_presence_ratio` depende dos bins e taxa de
disparo; a fração de violação refratária não é estimativa calibrada de
contaminação. Para `spike_waveform_extraction`, usar exclusivamente
sinal **broadband AP** (por exemplo, 30 kHz) e amostras com índice **MATLAB
iniciado em 1**, nunca LFP CON2PHYS a 500 Hz.

As funções de referência e coerência aceitam recortes finitos por canal.
`wavelet_coherence` usa suavização temporal apenas, sem suavização entre
escalas ou tratamento integral do cone de influência; deve permanecer
exploratória. `field_potential_forward` e
`field_potential_inverse_tikhonov` exigem matriz de sensibilidade
física fornecida externamente. A reconstrução por Tikhonov **não recupera
uma fonte fisiológica única**. Dados de EEG/LFP não permitem deduzir
excitação/inibição ou neuromodulação diretamente a partir de uma simples
regressão inversa.

Os frameworks e cursos usados como fontes de comparação:
[SpikeInterface](https://github.com/SpikeInterface/spikeinterface),
[Kilosort4](https://github.com/MouseLand/Kilosort),
[AIND Ephys Pipeline](https://github.com/AllenNeuralDynamics/aind-ephys-pipeline) e
[iBOTS LFP Analysis](https://learn.ibots-bonn.de/docs/lfp_analysis/).

#### Teste complementar

```matlab
run('matlab/tests/smoke_ephys_methods.m')
run('matlab/tests/smoke_consensus_methods.m')
```

Esse teste gera dados sintéticos e confere contratos básicos. Não substitui
verificação contra waveforms com ground truth, testes de unidades duplicadas,
efeitos da geometria laminar ou comparações com código de referência.

### Oscilações BOSC, estatística circular e GLM acoplado

Seis novas referências foram registradas em
[references/bosc_circular_glm.bib](references/bosc_circular_glm.bib),
incluindo correções bibliográficas de Whitten, Kajikawa e Linderman.

- `bosc_detect`: triagem de episódios oscilatórios com wavelets Morlet,
  modelo global de fundo espectral em log-log, limite de potência da
  distribuição exponencial e duração mínima em ciclos.
- `oscillation_episode`: converte excedências binárias por amostra
  em episódios sustentados, com início, fim, duração e fração temporal.
- `circular_mean`, `rayleigh_test`: média circular (com pesos, quando
  aplicável) e teste de não uniformidade de Rayleigh. Entradas em radianos;
  observações dependentes exigem testes que respeitem a correlação temporal.
- `spike_history_design`: matriz causal de regressores defasados,
  sem observar spikes presentes/futuros.
- `coupling_filters`: ajusta um GLM Poisson por unidade usando apenas
  o histórico dos disparos de todas as unidades; devolve coeficientes
  alvo x fonte x lag. Os coeficientes são dependências preditivas
  condicionais, **não sinapses nem evidência de causalidade física**.

A função BOSC é uma **versão exploratória**: o ajuste global do
fundo pode ser contaminado por picos, não há adaptação a mudanças de
estado, e episódios próximos das bordas da wavelet são excluídos.
A implementação não equivale a eBOSC. Os estimadores circulares não
reproduzem a toolbox CircStat inteira, e a inferência do coupled GLM
não reproduz a reconstrução/decodificação populacional de Pillow et al.

O método rSLDS de Linderman et al. permanece **planejado**:
`slds_inference.m` não foi criado artificialmente como placeholder,
pois dependerá de inferência aproximada probabilística e validação
com estados latentes simulados. O estudo de Cunningham & Yu foi
atualizado no catálogo com aplicações a manifolds, sem duplicação.

Os DOIs enviados para Whitten, Kajikawa e Linderman não
correspondiam aos artigos citados. As referências corretas são:
Whitten (2011) `10.1016/j.neuroimage.2010.08.064`;
Kajikawa & Schroeder (2011) `10.1016/j.neuron.2011.09.029`;
Linderman et al. (2017) está em PMLR 54, pp. 914-922, AISTATS,
com URL bibliográfica, sem reutilizar o DOI IEEE informado.

```matlab
run('matlab/tests/smoke_bosc_circ_glm.m')
```

A existência desses testes **não significa que tenham sido executados**.
O arquivo `METHODS.tsv` contém seis colunas separadas por TAB,
inclusive DOI vazio quando não confirmado.

## Integração com paper_con2phys

### Incremento de integracao

`spike_counts_edges(spike_times,edges)` conta eventos em bins explicitos,
inclusive irregulares, retornando um vetor coluna. Todos os bins sao
`[esquerda,direita)`: o ultimo timestamp na borda final e excluido. Unidades
silenciosas retornam zeros; timestamps nao finitos sao descartados.
`spike_bin_counts` reutiliza essa rotina e agora aceita um spike train vazio.
A integracao e coberta por `tests/test_path_integration.m` em `paper_con2phys`.

### Consolidação das branches do paper_con2phys

A [auditoria de branches](../books/BRANCH_REVIEW_2026_10_12.md) registra
as origens e decisões. Foram incorporadas as correções de covariância,
binning decimal, histogramas peri-evento e waveforms de um canal, com regressões.

Também estão disponíveis `lfp_envelope_moments` (momentos multicanal de
envelopes com metadados temporais), `decode_trials` (ridge com cinco folds
contíguos), `decoded_mi`, `greedy_modularity`, `spike_bins` e `trial_features`.
Estas cinco últimas funções preservam os contratos simples dos auxiliares
originais: forneça vetores-coluna de rótulos, janelas Nx2 em segundos e,
para modularidade, matrizes simétricas não negativas. O resultado de modularidade
é heurístico; a informação é a informação decodificada; as probabilidades softmax
do decoder não são calibradas. O argumento seed do decoder é apenas metadado:
os folds e o ajuste são determinísticos.

```matlab
run('matlab/neuronal_startup.m')
run('matlab/tests/test_lfp_envelope_moments.m')
run('matlab/tests/smoke_imported_helpers.m')
```

MATLAB não está disponível no ambiente de migração; execução numérica pendente.

## Compatibilidade e validação

Alvo: MATLAB R2019a ou superior; várias rotinas dependem da
**Signal Processing Toolbox** (`pwelch`, `dpss`, `hilbert`,
`butter`, `filtfilt`, `findpeaks`, `resample`).

```matlab
run('matlab/tests/smoke_arsenal.m')
run('matlab/tests/smoke_population.m')
run('matlab/tests/smoke_ephys_methods.m')
```

O smoke test é sintético; não substitui testes de referência, comparação
com implementações originais, experimentos surrogates e análise estatística.
**MATLAB não estava disponível no ambiente de autoria, portanto o smoke test
não foi executado.** Nenhuma convergência, acurácia ou equivalência numérica
entre implementações e artigos é afirmada.

## Próxima fase

Implementar testes de referência por artigo, aferir streaming/memmap,
controle de borda em convoluções, qualidade de unidade, jitter condicional
rigoroso, null models para assemblies, surrogates de PAC, ICSD inversa,
cluster permutations, GPFA/LFADS/dPCA e benchmarking de spike sorting.

Consulte [INTERVALS.md](INTERVALS.md) para as 16 famílias de geradores temporais,
consulta sob demanda, overlap e convenções de indexação.

## Layered filter family

See [FILTERS.md](FILTERS.md) for lazy frequency geometry, FIR/IIR design,
stateful application, decompositions, artifact/spatial methods, and typed
binary persistence. Start with `help filter_dyadic` and the executable
[`filter_family_demo.m`](../examples/matlab/filters/filter_family_demo.m).

## Persistência de arrays e catálogo

Veja [STORAGE.md](STORAGE.md) para a família `storage_*`: HDF5, binário, MAT,
catálogo SQLite e armazenamento híbrido, com leitura por intervalo e testes.
