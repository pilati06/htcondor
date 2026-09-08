# Tutorial HTCondor — Job 4: Requisitando GPU e nomeando arquivos automaticamente

## O que muda em relação aos jobs anteriores?

Este job introduz três novidades importantes:

1. **`request_gpus`** — como pedir uma GPU para o seu job.
2. **Macros de submissão** (`$(Cluster)` e `$(Process)`) — para gerar nomes de arquivo de saída automaticamente, em vez de nomes fixos.
3. Pela primeira vez, temos **duas versões do mesmo job** — uma para Linux (`job.sub` + `gpu_check.sh`) e outra para Windows (`job_windows.sub` + `gpu_check.bat`) — o que é uma boa chance de comparar as duas abordagens lado a lado.

---

## 1. Os scripts de verificação de GPU

**`gpu_check.sh`** (versão Linux):
```bash
#!/bin/bash
echo "=== Verificação de GPU ==="
echo "Hostname: $(hostname)"
echo "Data: $(date)"
echo "CUDA_VISIBLE_DEVICES = $CUDA_VISIBLE_DEVICES"

if command -v nvidia-smi >/dev/null 2>&1; then
    nvidia-smi
else
    echo "nvidia-smi não encontrado (esperado se não houver GPU NVIDIA)"
fi
```

**`gpu_check.bat`** (versão Windows):
```bat
@echo off
echo === Verificacao de GPU ===
echo Hostname: %COMPUTERNAME%
echo Data: %DATE% %TIME%

where nvidia-smi >nul 2>nul
if %ERRORLEVEL% == 0 (
    nvidia-smi
) else (
    echo nvidia-smi nao encontrado
)
```

Os dois fazem a mesma coisa, cada um com a sintaxe do seu sistema operacional:
- Imprimem hostname e data/hora (já vimos isso nos jobs anteriores).
- Verificam se o comando `nvidia-smi` (a ferramenta padrão da NVIDIA para inspecionar GPUs) existe na máquina.
- Se existir, rodam `nvidia-smi`, que lista as GPUs disponíveis, uso de memória de vídeo, driver instalado, etc.
- Se não existir, imprimem um aviso — isso é útil como *diagnóstico*: mesmo que você tenha pedido uma GPU ao HTCondor, este script confirma se ela realmente está visível e utilizável dentro do job.

> 💡 A variável `CUDA_VISIBLE_DEVICES` (usada na versão Linux) é definida automaticamente por sistemas como o HTCondor/CUDA para indicar **quais** GPUs físicas da máquina foram reservadas para o seu job — importante quando a máquina tem várias GPUs e vários jobs rodando ao mesmo tempo, cada um enxergando só a(s) sua(s).

---

## 2. O arquivo de submissão — versão Linux (`job.sub`)

```
executable   = gpu_check.sh
output       = gpu.$(Cluster).$(Process).out
error        = gpu.$(Cluster).$(Process).err
log          = gpu.$(Cluster).log

request_cpus   = 1
request_memory = 1GB
request_disk   = 1GB
request_gpus   = 1

should_transfer_files = YES
when_to_transfer_output = ON_EXIT

queue
```

## E a versão Windows (`job_windows.sub`)

```
executable   = gpu_check.bat
requirements = (OpSys == "WINDOWS") && (Arch == "X86_64")
request_cpus   = 1
request_memory = 1GB
request_disk   = 1GB
request_gpus   = 1

should_transfer_files = YES
when_to_transfer_output = ON_EXIT
transfer_input_files = gpu_check.bat

output = gpu.$(Cluster).$(Process).out
error  = gpu.$(Cluster).$(Process).err
log    = gpu.$(Cluster).log

queue
```

### O que é novo aqui

| Linha | O que faz |
|---|---|
| `request_gpus = 1` | **A novidade principal deste job.** Pede ao HTCondor que aloque **1 GPU** para o job, da mesma forma que `request_cpus` pede CPUs e `request_memory` pede RAM. Sem esta linha, o job rodaria sem nenhuma GPU reservada, mesmo que a máquina tenha uma disponível. |
| `output = gpu.$(Cluster).$(Process).out` | Em vez de um nome fixo como `saida_windows.out`, o nome do arquivo é montado **dinamicamente** usando duas macros do próprio HTCondor: `$(Cluster)` e `$(Process)`. |
| `requirements = (OpSys == "WINDOWS") && (Arch == "X86_64")` (só na versão Windows) | Combina duas condições com `&&`: além de exigir Windows (como no Job 1), agora também exige arquitetura de 64 bits especificamente. |
---

## 3. Entendendo as macros `$(Cluster)` e `$(Process)`

Esta é a novidade mais importante deste job em termos de organização.

Nos jobs anteriores, usamos nomes de arquivo **fixos**: `saida_windows.out`, `teste.out`, etc. Isso funciona bem quando você só submete **um job por vez** — mas se você rodar o mesmo `job.sub` de novo, o novo resultado **sobrescreve** o anterior!

As macros resolvem isso:
- `$(Cluster)` → é substituído pelo **ID do cluster** daquela submissão específica (o mesmo número que vimos entre parênteses no `.log`, ex.: `012`).
- `$(Process)` → é substituído pelo número do **processo dentro do cluster** (útil principalmente quando se usa `queue N` para submeter várias cópias de uma vez — cada cópia recebe um `$(Process)` diferente, começando em 0).

No nosso exemplo, o cluster foi o `012` e o processo foi `0` (só havia um `queue`, sem número), então o HTCondor gerou:
```
gpu.12.0.out
gpu.12.0.err
```

Note que `log = gpu.$(Cluster).log` usa só `$(Cluster)`, sem `$(Process)` — isso é comum quando se quer **um único log por submissão**, mesmo que ela gere vários processos.

> 💡 Usar `$(Cluster)` e `$(Process)` nos nomes de saída é uma prática recomendada assim que você começa a submeter jobs repetidamente ou em lote — evita perder resultados por sobrescrita, e facilita saber, só pelo nome do arquivo, a qual submissão ele pertence.

---

## 4. Entendendo o `gpu.12.log`

A estrutura de eventos é a mesma que já conhecemos (000, 040, 001, 006, 005), mas repare em duas linhas novas dentro do evento **001**:

```
001 ... Job executing on host: ...
	AvailableGPUs = { GPUs_GPU0 }
	...
	GPUs = 1
```

- `AvailableGPUs = { GPUs_GPU0 }` → mostra **qual** GPU física da máquina foi alocada para este job (aqui, a GPU identificada como `GPU0`).
- `GPUs = 1` → confirma que 1 unidade de GPU foi de fato alocada, batendo com o que pedimos em `request_gpus = 1`.

E no evento final (005), a tabela de recursos agora tem uma coluna a mais, **Assigned**:
```
Partitionable Resources :    Usage  Request Allocated Assigned
   GPUs                 :                 1         1 "GPU0"
```
- **Usage** — em branco, porque o script só *verificou* a GPU, sem de fato usá-la para processamento.
- **Request** — pedimos 1 GPU.
- **Allocated** — 1 GPU foi reservada para o job.
- **Assigned** — mostra qual GPU especificamente, pelo nome (`"GPU0"`) — só faz sentido essa coluna existir para GPUs, já que CPU/memória/disco são recursos "genéricos", mas GPUs são fisicamente distintas entre si.

---

## 5. A saída — `gpu_12_0.out`

```
=== Verificacao de GPU ===
Hostname: DESKTOP-MOQMNFK
Data: 04/08/2026 18:55:50,88
nvidia-smi nao encontrado
```

Isso corresponde à execução da versão **Windows** (`gpu_check.bat`), na máquina `DESKTOP-MOQMNFK`. O resultado mostra que, embora o HTCondor tenha **alocado** 1 GPU para o job (confirmado no log), o comando `nvidia-smi` não foi encontrado — ou seja, aquela máquina específica não tem os drivers/ferramentas NVIDIA instalados, mesmo participando da pool com uma entrada de GPU disponível. Isso ilustra bem por que scripts de diagnóstico como este são úteis: eles revelam a diferença entre "o HTCondor *diz* que aloquei uma GPU" e "o ambiente realmente tem uma GPU utilizável".

`gpu_12_0.err` está vazio, sem erros.

---

## 6. Resumindo o fluxo deste job

```
gpu_check.sh / gpu_check.bat  +  job.sub / job_windows.sub (com request_gpus = 1)
                          │
                 condor_submit job_windows.sub
                          │
         HTCondor escolhe uma máquina Windows x64 com 1 GPU disponível
                          │
         Aloca GPU0 para o job (visível no evento 001 do log)
                          │
         Executa gpu_check.bat, que tenta rodar nvidia-smi
                          │
         Salva saída em gpu.$(Cluster).$(Process).out → gpu.12.0.out
```