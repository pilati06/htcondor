# Tutorial HTCondor — Job 2: Rodando em um container com transferência de arquivos

## O que muda em relação ao Job 1?

No Job 1 rodamos um `.bat` simples, direto em uma máquina Windows da pool. Neste Job 2, três coisas novas aparecem:

1. O job roda dentro de um **container Docker** (não direto no sistema operacional da máquina).
2. O executável é um **script shell** (`run.sh`) que, por sua vez, chama um **script Python** (`teste.py`) — ou seja, temos um arquivo adicional que precisa ser **transferido** para a máquina de execução.
3. O arquivo de log passa a registrar eventos de **mais de um job**, o que é uma boa oportunidade para entender como o HTCondor identifica cada job unicamente.

Vamos por partes.

---

## 1. Os arquivos do job

**`teste.py`** — o programa de verdade, que faz o trabalho:
```python
import platform
import socket
from datetime import datetime

print(f"Nó: {socket.gethostname()}")
print(f"Sistema: {platform.system()} {platform.release()}")
print(f"Data: {datetime.now()}")
```
Imprime o nome do nó, o sistema operacional e a data/hora atual.

**`run.sh`** — o executável que o HTCondor de fato dispara:
```bash
#!/bin/bash
python3 teste.py
```
Repare que ele não faz nada além de chamar `python3 teste.py`. Isso é um padrão muito comum: em vez de apontar o `executable` diretamente para um script Python (o que pode dar problema se a máquina remota tiver um `python3` em outro caminho, ou exigir variáveis de ambiente antes), usa-se um pequeno *wrapper* em shell script que prepara o ambiente e só então chama o programa real.

> 💡 Isso também facilita adicionar passos extras no futuro (ex.: `pip install`, ativar um `virtualenv`, etc.) sem mexer no `job.sub`.

---

## 2. O arquivo de submissão — `job.sub`

```
universe       = container
container_image = docker://python:3.10

executable      = run.sh
should_transfer_files = YES
when_to_transfer_output = ON_EXIT
transfer_input_files = teste.py

output = teste.out
error  = teste.err
log    = teste.log

request_cpus   = 1
request_memory = 1GB
request_disk   = 1GB

queue
```

### O que é novo aqui

| Linha | O que faz |
|---|---|
| `universe = container` | Diz ao HTCondor que este job deve rodar **dentro de um container**, e não diretamente no sistema operacional da máquina de execução. No Job 1, por padrão, era usado o universo `vanilla` (execução direta). |
| `container_image = docker://python:3.10` | Especifica **qual imagem de container** usar — aqui, a imagem oficial `python:3.10` do Docker Hub. É essa imagem que já vem com Python 3.10 instalado, então não precisamos nos preocupar se a máquina física tem Python ou não. |
| `executable = run.sh` | Assim como no Job 1, é o programa que o HTCondor dispara — mas agora ele roda *dentro* do container. |
| `should_transfer_files = YES` | Avisa o HTCondor para usar o mecanismo de **transferência de arquivos**: copiar os arquivos necessários para a máquina remota antes de rodar, e trazer os resultados de volta depois. |
| `when_to_transfer_output = ON_EXIT` | Define **quando** trazer os arquivos de saída de volta: neste caso, assim que o job terminar (`ON_EXIT`). |
| `transfer_input_files = teste.py` | Lista os arquivos **adicionais** que precisam ser copiados para a máquina de execução além do próprio `executable`. Sem esta linha, o `teste.py` nunca chegaria até lá, e o `run.sh` falharia ao tentar chamá-lo. |
| `request_disk = 1GB` | Assim como `request_cpus` e `request_memory`, reserva espaço em disco para o job (novo em relação ao Job 1, que usava o padrão). |

Note que `output`, `error`, `log`, `request_cpus` e `request_memory` já apareceram no Job 1 — a lógica é a mesma.

---

## 3. Por que preciso do `transfer_input_files`?

Este é o conceito central deste job. Pense assim:

- O `executable` (`run.sh`) é **sempre** transferido automaticamente pelo HTCondor — não precisa listá-lo.
- **Qualquer outro arquivo** do qual seu programa depende (dados de entrada, scripts auxiliares, bibliotecas locais, etc.) precisa ser explicitamente declarado em `transfer_input_files`, separado por vírgula se houver mais de um:
  ```
  transfer_input_files = teste.py, dados.csv, config.json
  ```

Se você esquecer de listar um arquivo necessário, o job vai falhar (geralmente com um erro de "arquivo não encontrado" no `.err`), mesmo que o arquivo esteja certinho na sua pasta local.

---

## 4. Container vs. Vanilla — por que isso importa

No Job 1, o job rodava direto no Windows da máquina escolhida, então dependíamos de que aquela máquina específica já tivesse tudo instalado (e usamos `requirements` para garantir que fosse Windows).

Aqui, ao usar `universe = container` com uma imagem Docker, **o ambiente de execução vem junto com o job**: não importa se a máquina física roda Linux, tem Python 2.7 instalado ou nenhum Python — dentro do container sempre haverá exatamente o Python 3.10 da imagem `python:3.10`. Isso torna o job **reproduzível** em qualquer máquina da pool que suporte containers.

---

## 5. A saída — `teste.out` e `teste.err`

**`teste.out`:**
```
Nó: node01
Sistema: Linux 7.0.0-28-generic
Data: 2026-07-31 13:11:52.652798
```
Exatamente o que o `print()` do `teste.py` gerou — confirmando, inclusive, que desta vez o sistema é **Linux** (dentro do container), diferente do Windows do Job 1.

**`teste.err`:** vazio, sem erros.

---

## 6. Resumindo o fluxo deste job

```
teste.py (lógica)  +  run.sh (wrapper)  +  job.sub (instruções)
                          │
                 condor_submit job.sub
                          │
         HTCondor sobe um container docker://python:3.10
         na máquina escolhida (node01)
                          │
         Transfere run.sh (automático) e teste.py (via transfer_input_files)
                          │
         Executa: bash run.sh  →  python3 teste.py
                          │
         Captura stdout/stderr e traz de volta (ON_EXIT)
                          │
         Registra tudo em teste.log (cuidado: cluster 008 é o nosso!)
```