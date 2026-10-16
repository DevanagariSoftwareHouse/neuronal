# CON2PHYS: battle test do arsenal MATLAB

17 análises temáticas, preparação compartilhada e executor, exclusivamente em scripts. Cobertura estática de **131/131 funções** de `matlab/path`, enumeradas em [COVERAGE.md](COVERAGE.md) e `coverage.csv`. A presença de uma chamada não implica validação numérica nem validação científica do método.

## Executar

Na raiz do repositório, após o digest do CON2PHYS gerar `data/neuronal/catalog.mat`:

```matlab
cfg = struct('session',1,'seconds',60,'start_s',0, ...
    'draws',199,'plots',true,'seed',42);
run('analysis/+con2phys/path/z00_run_all.m')
```

O executor salva um MAT por módulo, metadados, seeds e `ledger.csv` em `analysis/results/con2phys_battle_<data>`. Os estados são `passed`, `skipped` (pré-requisito explicitamente ausente) e `failed`. Continua após falhas para levantar o inventário completo e termina com erro se houve falha. Resultados parciais de módulos que falharam continuam identificados como tal. `passed` significa execução e verificações locais concluídas, não validade científica.

Para inspecionar interativamente:

```matlab
run('analysis/+con2phys/path/a00_prepare.m')
a03_spectrum
r
```

Cada módulo usa o contexto `c` e grava seu resultado em `r`; execute a preparação primeiro. Para outra sessão/janela, altere `cfg` e repita a preparação. O contexto contém LFP de até quatro canais por área, apenas na janela escolhida; timestamps de spikes são lidos para a sessão completa. Os métodos populacionais usam até 12 clusters variáveis, selecionados por ordem de catálogo, sem seleção de qualidade implícita. Isso é um recorte exploratório, não amostragem representativa da população.

## Análises e o que inspecionar

| Script | Dados / pergunta | Resultado e limite |
|---|---|---|
| a01_storage | Excerto real: gravação e leitura mantêm valores? | Igualdade exata; catálogo temporário isolado, diretório em `r.directory`. |
| a02_spike_statistics | Como variam taxas, ISIs e coincidências? | Taxa da sessão completa; ISI, presença, Fano e correlogramas da janela. |
| a03_spectrum | Picos sobrevivem à escolha do estimador? | Welch, multitaper, IRASA, slope e entropias; comparar frequências/resoluções. |
| a04_oscillations_events | Quando ocorrem oscilações e eventos? | BOSC, ciclos, envelopes, raster/PSTH e STA; ripples são candidatos. |
| a05_phase_connectivity | Há estrutura de fase e amplitude compartilhada? | PAC com null de deslocamento, PPC, PLV, PLI, wPLI, coerências e PSI. |
| a06_predictive_dependence | O passado melhora a predição? | VAR/Granger, GLMs, TE discreta e sensibilidade ao passo temporal. |
| a07_population | Qual a geometria da atividade? | PCA, assemblies, dimensão, jPCA, GP, RRR com erro held-out e grafo. |
| a08_trials_decoding | Uma coluna comportamental é decodificável? | Requer `cfg.label_field`; compara folds intercalados/contíguos; dDR treinado dentro do fold. |
| a09_waveforms_control | Controle sintético AP com eventos conhecidos | Detecção, extração, template, SNR, PCA, agreement; não é sorting real. |
| a10_fields_control | Referência real e geometria sintética | Mediana entre canais reais; bipolar/CSD/inversão apenas com geometria sintética. |
| a11_surrogate_invariants | O que cada null conserva? | Distribuição, módulo de Fourier e contagens por janela; jitter não é dither. |
| a12_animal_uncertainty | Como estimar incerteza entre animais? | Taxas por área em todas as sessões, bootstrap, jackknife, pareamento e folds por grupo. |
| a13_inference_controls | Testes distinguem grupos simulados? | Permutação, maxstat, clusters e Monte Carlo sob desenho independente explícito. |
| a14_count_models | Um Poisson IID reproduz média e variância? | Bootstrap paramétrico e posterior preditiva Gamma–Poisson; pressuposto a avaliar. |
| a15_adaptive_decomposition | Decomposição adaptativa do LFP | EMD/EEMD em quatro segundos; identidade de reconstrução EMD. |
| a16_trial_tensor | Estrutura cluster × tempo × trial | CP-ALS em até 30 trials com um segundo completo, sem padding. |
| a17_average_waveforms | Morfologia dos templates reais | PCA e trough-to-peak; templates médios não dão isolamento nem SNR de spikes individuais. |

## Configuração e interpretação

- `cfg.label_field` começa vazio deliberadamente. Confira `d.behavior.variable_names` e a documentação comportamental antes de selecionar uma coluna numérica com duas classes. Não se adivinha significado de A/C. O módulo a08 registra `skipped` sem essa configuração.
- a12 pressupõe um registro por animal independente, verifica unicidade de `source_id` e exige seis animais completos. Confirme a correspondência biológica dos IDs. As taxas por área têm peso igual por animal; o bootstrap hierárquico reamostra animais e clusters na área 1. Não trata clusters como réplicas independentes entre animais.
- CIs IID operam sobre resumos de animais. Bootstrap temporal em blocos opera sobre bins; 1 segundo é um parâmetro exploratório a ajustar à dependência temporal. A estabilidade de seleção é descritiva.
- As duas áreas do mesmo animal são pareadas. Testes entre grupos independentes e cluster-permutation são demonstrados em controles sintéticos, evitando uma permutação incorreta de animais pareados ou bins temporais.
- No a05, Rayleigh usa fases de spikes e ainda pressupõe independência; bursts violam essa aproximação. Coerência e PAC podem refletir sinal comum, referência, harmônicos ou transientes. wPLI usa segmentos de Fourier não sobrepostos, sem garantir independência fisiológica. Coerência wavelet conserva bordas para inspeção; não são usadas para inferência.
- Há corte de dois segundos para fases/envelopes; não é garantia universal de ausência de efeitos de borda. BOSC tem sua própria máscara. Ciclos usam tempo relativo ao trecho cortado; metadados do executor preservam a origem da janela.
- O limite de Nyquist do LFP a 500 Hz é 250 Hz. Candidatos de ripple usam 100–200 Hz (ou banda menor conforme fs), não toda a faixa possível de ripples. Nenhuma identidade de interneurônio/piramidal é inferida automaticamente.
- Scripts de controles sintéticos identificam seu modo em `r.mode`. Taxas de aquisição de waveform vêm do digest e precisam ser conferidas na fonte. Nenhum dado sintético substitui silenciosamente dados reais ausentes.
- `draws=199` é exploração rápida (resolução mínima Monte Carlo 1/200). Para resultados finais, aumente draws, examine calibração/estabilidade e corrija multiplicidade conforme a família de hipóteses.

## Dependências e validação

MATLAB moderno com `memmapfile`, `table`, `subplot` e Signal Processing Toolbox; a14 requer Statistics and Machine Learning Toolbox. Sem esse toolbox a14 registra `skipped`. Os algoritmos existentes mantêm suas próprias limitações: slope não é specparam completo, GP smoothing não é GPFA, marginalização não é dPCA, EMD/BOSC são implementações exploratórias.

Validação na implementação: parser/lint MISS_HIT dos 19 scripts e inventário estático 131/131. **Não executado em MATLAB nem contra os binários reais**, indisponíveis no ambiente de autoria. Os asserts verificam round trip, contagens, invariantes de surrogates, reconstrução e limites de p; o ledger é o registro de execução a produzir na máquina com os dados. Os artigos anexados não são apresentados como reproduzidos por estes scripts.

## Correções após a primeira execução real

O primeiro ledger reportado teve 14 módulos concluídos, dois com falha e um sem configuração de labels. O gráfico de a02 agora usa `subplot`, pois `tiledlayout` não estava disponível. Em a12, o callback de `paired_permutation_test` agora recebe o vetor B−A via `@mean`. O executor registra `error_file` e `error_line` no CSV e conserva `error_stack` e `error_report` no MAT de cada módulo. Essas correções ainda precisam ser reexecutadas no MATLAB do usuário.
