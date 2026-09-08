# Tutorial HTCondor — Job 5: Exemplo completo (batch de processamento de dados)

## Um cenário mais próximo do real

Chegamos ao último job da série. Ele junta praticamente tudo o que vimos nos jobs anteriores — container, transferência de arquivos, argumentos, macros — e adiciona a peça que faltava: **submeter vários jobs de uma vez, cada um processando um arquivo de entrada diferente**, com um único comando `condor_submit`.

O cenário: temos três arquivos CSV com dados de sensores de umidade/temperatura/NDVI de três talhões agrícolas (`talhao_001.csv`, `talhao_002.csv`, `talhao_003.csv`), e queremos rodar a **mesma análise** em cada um deles.

---

## 1. Os arquivos de entrada

**`lista_arquivos.txt`** — uma simples lista de nomes de arquivo, um por linha:
```
talhao_001.csv
talhao_002.csv
talhao_003.csv
```

**`talhao_001.csv`** (e os outros dois, com a mesma estrutura) — dados de sensor:
```
data_hora,sensor_id,umidade_solo_pct,temperatura_c,ph_solo,ndvi
2026-03-01 08:00:00,SENS-01,28.5,24.2,6.2,0.78
2026-03-01 09:00:00,SENS-01,27.8,25.1,6.2,0.78
...
```

---

## 2. O programa de análise — `analyse.py`

```python
import sys
import os
import pandas as pd

def main():
    # Garante que o argumento com o nome do arquivo foi passado
    if len(sys.argv) < 2:
        print("Erro: Nome do arquivo não fornecido.")
        sys.exit(1)

    nome_arquivo = sys.argv[1]

    print(f"=== Iniciando processamento: {nome_arquivo} ===")

    # Leitura do CSV
    df = pd.read_csv(nome_arquivo)

    # Conversão de coluna de data
    df['data_hora'] = pd.to_datetime(df['data_hora'])

    # Cálculo de métricas agregadas
    total_registros = len(df)
    umidade_media = df['umidade_solo_pct'].mean()
    temp_max = df['temperatura_c'].max()
    temp_min = df['temperatura_c'].min()
    ndvi_medio = df['ndvi'].mean()

    # Saída padrão (será capturada pelo HTCondor no arquivo .out definido)
    print(f"Registros processados: {total_registros}")
    print(f"Umidade média do solo: {umidade_media:.2f}%")
    print(f"Temperatura máxima: {temp_max:.1f}°C")
    print(f"Temperatura mínima: {temp_min:.1f}°C")
    print(f"NDVI médio: {ndvi_medio:.3f}")

    # Alerta simples de estresse hídrico
    if umidade_media < 25.0:
        print("ALERTA: Umidade média do solo abaixo do limite ideal (25%).")

    print("=== Processamento concluído com sucesso ===")

if __name__ == "__main__":
    main()
```

Este script já reúne boas práticas que valem para qualquer job real:
- **Valida os argumentos** recebidos (`sys.argv`), em vez de assumir que tudo vai dar certo.
- Usa `pandas` para calcular métricas agregadas (média, máximo, mínimo) — um processamento de dados de verdade, não apenas um "hello world".
- Imprime um **alerta condicional** (umidade abaixo do limite), simulando uma regra de negócio real.

---

## 3. O wrapper — `run.sh`

```bash
#!/bin/bash

# Se a imagem docker padrão do Python não tiver o pandas, instala rapidamente no contêiner
pip install --no-cache-dir pandas > /dev/null 2>&1

# Executa o script repassando o nome do arquivo recebido como argumento
python3 analyse.py "$1"
```

Duas coisas novas em relação aos wrappers dos jobs anteriores:
- **Instala uma dependência em tempo de execução** (`pip install pandas`), já que a imagem `python:3.10-slim` (veja a seguir) é minimalista e não vem com bibliotecas de terceiros. Isso evita ter que construir uma imagem Docker customizada apenas para adicionar o `pandas`.
- Usa `"$1"` (o **primeiro argumento** recebido pelo `.sh`) para repassar o nome do arquivo ao `analyse.py` — o equivalente em Linux ao `%*` que vimos no Job 3 no Windows (aqui só o primeiro argumento é necessário, então `$1` é suficiente).

---

## 4. O arquivo de submissão — `job.sub`

```
universe        = container
container_image = docker://python:3.10-slim

executable      = run.sh
arguments       = $(arquivo)

should_transfer_files = YES
when_to_transfer_output = ON_EXIT
transfer_input_files = analyse.py, dados/$(arquivo)

output = saida_$(arquivo).out
error  = erro_$(arquivo).err
log    = job_$(arquivo).log

request_cpus   = 1
request_memory = 1GB
request_disk   = 1GB

queue arquivo from lista_arquivos.txt
```

Praticamente todas as linhas já são familiares dos jobs 2, 3 e 4 (container, transferência de arquivos, argumentos, recursos). A grande novidade está na **última linha**.

### `queue arquivo from lista_arquivos.txt` — o coração deste job

Nos jobs anteriores, `queue` sozinho submetia **um único job**. Aqui, a sintaxe é diferente:

```
queue arquivo from lista_arquivos.txt
```

Isso diz ao HTCondor:
1. Leia o arquivo `lista_arquivos.txt` linha por linha.
2. Para **cada linha**, crie um job separado, atribuindo o conteúdo daquela linha à variável `$(arquivo)`.
3. Submeta todos esses jobs de uma vez, como parte do **mesmo cluster**.

Como `lista_arquivos.txt` tem 3 linhas, isso gera **3 jobs**:

| `$(arquivo)` | Processo | Efeito |
|---|---|---|
| `talhao_001.csv` | Process 0 | `arguments = talhao_001.csv`, `output = saida_talhao_001.csv.out`, etc. |
| `talhao_002.csv` | Process 1 | `arguments = talhao_002.csv`, `output = saida_talhao_002.csv.out`, etc. |
| `talhao_003.csv` | Process 2 | `arguments = talhao_003.csv`, `output = saida_talhao_003.csv.out`, etc. |

Ou seja, **`$(arquivo)` é uma macro personalizada**, assim como `$(Cluster)` e `$(Process)` do Job 4 — só que, em vez de vir de um contador automático do HTCondor, seu valor vem de uma lista fornecida por você. Isso é extremamente poderoso: com uma única submissão, você processa quantos arquivos quiser, bastando adicionar linhas ao `.txt`.

> 📌 Cada um desses 3 jobs recebe o **mesmo Cluster ID**, mas um **Process ID diferente** (`0`, `1`, `2`) — exatamente a mesma lógica de `$(Cluster).$(Process)` que vimos no Job 4, só que agora gerada automaticamente pelo `queue ... from`.

---

## 6. As saídas

**`saida_talhao_001.csv.out`:**
```
=== Iniciando processamento: talhao_001.csv ===
Registros processados: 7
Umidade média do solo: 25.59%
Temperatura máxima: 32.1°C
Temperatura mínima: 24.2°C
NDVI médio: 0.764
=== Processamento concluído com sucesso ===
```

**`saida_talhao_002.csv.out`** — este talhão dispara o alerta de negócio:
```
=== Iniciando processamento: talhao_002.csv ===
Registros processados: 7
Umidade média do solo: 20.17%
Temperatura máxima: 34.2°C
Temperatura mínima: 25.8°C
NDVI médio: 0.659
ALERTA: Umidade média do solo abaixo do limite ideal (25%).
=== Processamento concluído com sucesso ===
```

**`saida_talhao_003.csv.out`:**
```
=== Iniciando processamento: talhao_003.csv ===
Registros processados: 7
Umidade média do solo: 31.66%
Temperatura máxima: 28.7°C
Temperatura mínima: 22.1°C
NDVI médio: 0.840
=== Processamento concluído com sucesso ===
```

Todos os três `.err` estão vazios — nenhum job teve erro de execução. É assim que um lote de processamento bem-sucedido se parece: mesma lógica, três conjuntos de dados, três resultados independentes, um único comando de submissão.

---

## 7. Resumindo o fluxo completo deste job

```
lista_arquivos.txt (talhao_001.csv, talhao_002.csv, talhao_003.csv)
                          │
       queue arquivo from lista_arquivos.txt
                          │
       Gera 3 jobs (mesmo Cluster, Process 0/1/2)
       cada um com $(arquivo) = uma linha da lista
                          │
       Para cada job:
         - Sobe container python:3.10-slim
         - Transfere analyse.py + dados/$(arquivo)
         - Executa: run.sh $(arquivo)
              → pip install pandas
              → python3 analyse.py $(arquivo)
         - Salva saida_$(arquivo).out / erro_$(arquivo).err
         - Registra tudo em job_$(arquivo).log
```

---

## 8. Juntando tudo: os 5 jobs desta série

| Job | Conceito principal introduzido |
|---|---|
| **Job 1** | Estrutura básica: `executable`, `output`/`error`/`log`, `request_cpus`/`request_memory`, `requirements`, `queue` |
| **Job 2** | `universe = container`, imagem Docker, `transfer_input_files`, wrapper de script |
| **Job 3** | `arguments`, wrapper genérico reutilizável, valores padrão de recursos |
| **Job 4** | `request_gpus`, macros automáticas `$(Cluster)`/`$(Process)`, jobs Linux vs. Windows |
| **Job 5** | `queue ... from arquivo.txt` (batch de jobs), macro personalizada, paralelismo |

Com esses cinco exemplos, você já tem o suficiente para: escrever seu próprio executável/wrapper, descrever recursos necessários, transferir os arquivos certos, rodar em containers quando precisar de um ambiente controlado, passar argumentos dinâmicos, pedir GPU quando necessário, e — o mais valioso para uso real — **submeter um lote inteiro de jobs de uma vez**, um por arquivo de entrada.