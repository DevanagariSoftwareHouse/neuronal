# Geradores de intervalos temporais

As 16 famílias têm implementações em `path/interval_*.m`. Todas usam `N`
(número de amostras), `fs` (Hz), segundos e limites temporais **[t0,t1)**.
Não são intervalos de confiança. Não exigem toolboxes adicionais.

## Contrato comum

Cada registro contém `t0`, `t1`, `duration_s`, `first`, `last`, `n_samples`,
`window`, `n_windows` e `source_index`. O relógio é `t=(0:N-1)/fs`.
`first:last` são índices MATLAB inclusivos; não materializamos máscaras.

- `interval_from_bounds` recebe uma matriz K×2, recorta em `[0,N/fs)` e remove
  interseções vazias. Preserva ordem e identidade das linhas em `source_index`.
- Um intervalo temporal positivo pode não conter amostras: nesse caso
  `n_samples=0` e `first:last` é vazio. Eventos e ondas muito curtas podem
  produzir isso. A família m-ádica exige largura nominal de pelo menos uma amostra.
- Coordenadas de amostras a até 8 ULP de um inteiro são arredondadas para ele,
  para estabilizar fronteiras calculadas em ponto flutuante.
- `duration_s` mede tempo; `n_samples/fs` mede exposição na grade amostral.
  Podem diferir para limites fora da grade. Use a primeira para timestamps
  contínuos, e a segunda para contagens explicitamente discretizadas.
- Sobreposição é geométrica; janelas que compartilham dados não são réplicas
  independentes. Uma cobertura sobreposta não tem necessariamente pai único.

## Famílias e assinaturas

| Família | Chamada | Comportamento |
|---|---|---|
| Uniforme | `interval_uniform(N,fs,n_parts,k)` | Partição igual; consulta O(1) |
| Sliding | `interval_sliding(N,fs,width_s,hop_s,k)` | Apenas janelas completas; O(1); aceita lacunas |
| Diádica | `interval_dyadic(N,fs,level,overlap,k)` | Largura T/2^level; O(1) |
| m-ádica | `interval_madic(N,fs,base,level,overlap,k)` | Largura T/base^level; O(1) |
| Geométrica | `interval_geometric(N,fs,first_width_s,ratio,k)` | Larguras crescentes, ratio≥1; inclui cauda parcial; O(1) |
| Periódica | `interval_periodic(N,fs,frequency_hz,phase_rad,duty,k)` | Cada trecho positivo individual, bordas recortadas; O(1) |
| Wavelet | `interval_wavelet(N,fs,support,scale_s,translation_s)` | Suporte afim; não calcula transformada |
| Eventos | `interval_event(N,fs,events_s,pre_s,post_s)` | Janelas em torno dos eventos; O(K) |
| Entre eventos | `interval_between_events(N,fs,events_s)` | Tempos não decrescentes; empates vazios removidos; O(K) |
| Quantílica | `interval_quantile(N,fs,timestamps_s,n_bins)` | Quantis temporais interpolados; O(K log K) pela ordenação |
| Adaptativa | `interval_adaptive(N,fs,mass,target)` | Fecha blocos ao acumular massa-alvo; O(N) |
| Change-point | `interval_changepoint(N,fs,x,penalty,min_samples)` | Segmentação binária gulosa da média; pior caso O(N²) |
| Limiar | `interval_threshold(N,fs,x,threshold,min_duration_s)` | Excursões estritamente acima; NaN interrompe; O(N) |
| Estocástica | `interval_stochastic(N,fs,n_windows,width_range_s,seed)` | Larguras e inícios uniformes condicionais; O(K) |
| Renewal / Poisson | `interval_renewal(N,fs,durations_s)` e `interval_poisson(N,fs,rate_hz,seed)` | Esperas fornecidas ou exponenciais; O(K) |
| Comportamental | `interval_behavioral(N,fs,starts_s,stops_s)` | Trials pareados, preservando sobreposição; O(K) |

`interval_at(N,fs,level,overlap,k)` continua disponível e mantém todos os
campos anteriores. Agora compartilha a implementação m-ádica e a conversão de
índices. Larguras nominais subamostrais são rejeitadas consistentemente.

## Consulta sob demanda e overlap

```matlab
N = 1000;
fs = 500;
get = @(level,o,k) interval_at(N,fs,level,o,k);
a = get(2,.5,1);
b = get(2,.5,2);
shared_s = max(0,min(a.t1,b.t1)-max(a.t0,b.t0));
fraction = shared_s/a.duration_s; % 0.5
shared_samples = max(0,min(a.last,b.last)-max(a.first,b.first)+1);

for k = 1:a.n_windows
    node = get(2,.5,k);
    % lfp_segment = lfp(:,node.first:node.last);
    % count = sum(spike_times >= node.t0 & spike_times < node.t1);
    % rate_hz = count/node.duration_s;
end
```

A onda quadrada usa `mod(2*pi*f*t+phase,2*pi) < 2*pi*duty`.
Para uma sessão inteira positiva, use `f=1/(2*T)`, **fase zero**, duty=0.5.
A fase pi/2 nesse exemplo encerraria o trecho positivo na metade da sessão.
Fases separadas por 2*pi são equivalentes; cinco fases distintas igualmente
espaçadas são `-(0:4)*2*pi/5`.

```matlab
T = N/fs;
for phase = -(0:4)*2*pi/5
    first_run = interval_periodic(N,fs,1/T,phase,.5,1);
    for k = 1:first_run.n_windows
        node = interval_periodic(N,fs,1/T,phase,.5,k);
        % Processar apenas node.first:node.last.
    end
end
```

O número de trechos positivos depende da fase e das bordas, não do número de
fases. `interval_periodic` enumera trechos de uma onda; `interval_sliding`
controla diretamente o overlap entre janelas consecutivas.

## Regras dependentes dos dados

```matlab
% Energia acumulada por bloco: target nas mesmas unidades de sum(mass).
x = sin(2*pi*8*(0:N-1)/fs);
energy_windows = interval_adaptive(N,fs,abs(x).^2/fs,.2);
excursions = interval_threshold(N,fs,x,.8,.01);
changes = interval_changepoint(N,fs,x,1,20);
events = interval_event(N,fs,[.2 .8 1.5],.1,.2);
trials = interval_behavioral(N,fs,[0 .7],[.5 1.9]);
```

A segmentação adaptativa inclui a amostra que cruza o alvo e conserva o excesso
nesse bloco. A change-point maximiza a redução da soma dos erros quadráticos
a cada divisão; não é uma otimização global nem um teste de significância.
Quantis coincidentes são colapsados: empates podem reduzir a quantidade de
intervalos e impedir contagens iguais. A wavelet exige suporte explícito;
wavelets de suporte infinito precisam de truncamento escolhido pelo chamador.

## Aleatoriedade e renovação

```matlab
random_windows = interval_stochastic(N,fs,20,[.1 .4],42);
poisson_windows = interval_poisson(N,fs,5,42);
renewal_windows = interval_renewal(N,fs,[.1 .2 .7 .5]);
```

As funções aleatórias restauram o estado global de `rng`, inclusive em erro.
A Poisson inclui o último intervalo censurado no fim da sessão. Renewal recebe
esperas positivas; para um processo de renovação aleatório, forneça esperas
iid da distribuição desejada. Se as esperas terminarem antes de T, a função
não inventa uma cauda. A família estocástica não implementa, por si só, um
bootstrap estacionário: reamostragem exige regras adicionais de concatenação.

## Validação

```matlab
run('matlab/tests/test_interval_at.m')
run('matlab/tests/test_interval_families.m')
```

A suíte científica existente descobre esses scripts automaticamente.
