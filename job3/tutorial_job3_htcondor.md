# Tutorial HTCondor — Job 3: Passando argumentos para o executável

## O que muda em relação aos jobs anteriores?

Este job volta a rodar no **Windows** (como o Job 1), sem container, mas introduz duas ideias novas:

1. **`arguments`** — como passar parâmetros de linha de comando para o seu executável.
2. Um **wrapper genérico** (`run.bat`) que repassa esses argumentos para o Python, em vez de chamar um script fixo.

Também é uma boa oportunidade para falar sobre o que acontece quando você **não** define `request_cpus` / `request_memory` explicitamente.

---

## 1. Os arquivos do job

**`teste.py`** — o mesmo script Python do Job 2, sem alterações:
```python
import platform
import socket
from datetime import datetime

print(f"Nó: {socket.gethostname()}")
print(f"Sistema: {platform.system()} {platform.release()}")
print(f"Data: {datetime.now()}")
```

**`run.bat`** — agora um wrapper **genérico**, não mais amarrado a um script específico:
```bat
@echo off
python %*
```

Aqui está a diferença-chave em relação ao Job 2:
- No Job 2, `run.sh` tinha o nome do script **fixo dentro dele**: `python3 teste.py`.
- Aqui, `run.bat` usa `%*`, que no Windows significa **"todos os argumentos recebidos por este `.bat`"**. Ou seja, o `run.bat` não sabe (e não precisa saber) qual script Python vai rodar — quem decide isso é o `job.sub`, através de `arguments`.

Isso torna o `run.bat` **reutilizável** para rodar qualquer script Python, sem precisar editar o `.bat` toda vez.

---

## 2. O arquivo de submissão — `job.sub`

```
executable = run.bat
arguments  = teste.py
transfer_input_files = teste.py, run.bat

output     = saida_windows.out
error      = saida_windows.err
log        = job_windows.log

requirements = (OpSys == "WINDOWS")

should_transfer_files = YES
when_to_transfer_output = ON_EXIT

queue
```

### O que é novo aqui

| Linha | O que faz |
|---|---|
| `executable = run.bat` | O programa disparado pelo HTCondor continua sendo o wrapper. |
| `arguments = teste.py` | **Novidade central deste job.** Define os argumentos de linha de comando passados ao executável. Na prática, o HTCondor roda algo equivalente a `run.bat teste.py`. Dentro do `run.bat`, `%*` captura esse `teste.py` e o repassa para `python`, resultando em `python teste.py`. |
| `transfer_input_files = teste.py, run.bat` | Lista os dois arquivos a transferir. Note que `run.bat` aparece aqui **mesmo sendo o `executable`** — normalmente o executável já é transferido automaticamente, então listá-lo de novo não causa problema, mas também não é estritamente necessário.|

### O que ficou de fora (e por quê importa)

Repare que este `job.sub`, ao contrário do Job 1 e do Job 2, **não define** `request_cpus` nem `request_memory`. Isso não é um erro — o HTCondor usa **valores padrão** quando essas linhas não são especificadas. Podemos ver o efeito disso direto no log (seção 4 abaixo): o job recebeu apenas **128 MB de memória**, bem menos que os 512 MB e 1024 MB dos jobs anteriores, porque esse é o valor padrão do sistema, não algo que pedimos.

> ⚠️ **Boa prática:** para jobs pequenos como este exemplo, o padrão costuma ser suficiente. Mas para jobs reais (principalmente os mais pesados, como veremos no Job 5), é importante **sempre declarar explicitamente** `request_cpus`, `request_memory` e `request_disk`, para não depender de um padrão que pode não ser adequado ao seu programa — um script que precisa de mais memória do que o padrão permite pode ser encerrado à força pelo sistema.

---

## 3. Como isso se conecta: do `job.sub` até a execução

```
job.sub:      executable = run.bat
              arguments  = teste.py
                    │
HTCondor executa:   run.bat teste.py
                    │
run.bat:      python %*        →       python teste.py
                    │
Resultado:    executa teste.py com o Python instalado na máquina Windows
```

Se, no futuro, você quiser rodar outro script com o mesmo `run.bat`, basta trocar a linha `arguments` no `job.sub` — por exemplo, `arguments = outro_script.py` — sem tocar em nenhum outro arquivo.

---

## 4. A saída — `saida_windows.out` e `saida_windows.err`

**`saida_windows.out`:**
```
Nó: DESKTOP-MOQMNFK
Sistema: Windows 11
Data: 2026-07-31 10:25:11.388815
```

Confirma que o script rodou corretamente, no Windows, via `run.bat teste.py` → `python teste.py`.

**`saida_windows.err`:** vazio, sem erros.

---

## 5. Resumindo o fluxo deste job

```
teste.py (lógica)  +  run.bat (wrapper genérico, usa %*)  +  job.sub (define arguments = teste.py)
                          │
                 condor_submit job.sub
                          │
         HTCondor escolhe uma máquina Windows (requirements)
         com os recursos padrão (já que não pedimos explicitamente)
                          │
         Transfere run.bat e teste.py
                          │
         Executa: run.bat teste.py  →  python %*  →  python teste.py
                          │
         Captura stdout/stderr, traz de volta e registra no .log
```
