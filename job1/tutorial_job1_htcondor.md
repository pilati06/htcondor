# Tutorial HTCondor — Job 1: Seu primeiro job

## Objetivo deste job

Este é o exemplo mais simples possível de um job no HTCondor: rodar um script `.bat` no Windows que apenas imprime algumas informações na tela (nome da máquina, data/hora e uma mensagem de sucesso). O objetivo aqui não é o script em si, mas entender **os quatro arquivos que compõem um job** e como eles se relacionam.

Um job no HTCondor sempre envolve, no mínimo:

1. **O programa/script que você quer executar** (aqui, `teste.bat`)
2. **O arquivo de submissão** (`job.sub`) — as instruções para o HTCondor
3. **Os arquivos de saída** — onde o resultado, os erros e o histórico de execução aparecem

---

## 1. O script a ser executado — `teste.bat`

```bat
@echo off
echo Ola do HTCondor no Windows!
echo Hostname: %COMPUTERNAME%
echo Data/Hora: %DATE% %TIME%
echo Job concluido com sucesso.
```

É um `.bat` comum do Windows, sem nada específico do HTCondor. Ele:
- Desliga o eco de comandos (`@echo off`)
- Imprime um texto fixo
- Imprime o nome do computador onde está rodando (útil para confirmar em qual máquina da pool o job caiu)
- Imprime a data e hora
- Imprime uma mensagem de conclusão

**Ponto-chave:** o HTCondor não sabe nada sobre o *conteúdo* do seu script. Ele só sabe executá-lo como um processo comum e capturar o que ele imprime.

---

## 2. O arquivo de submissão — `job.sub`

Este é o arquivo que você entrega ao HTCondor com o comando `condor_submit`. Ele descreve **o que** rodar e **como**.

```
executable = teste.bat
arguments  =
output     = saida_windows.out
error      = saida_windows.err
log        = job_windows.log
request_cpus   = 1
request_memory = 512MB
requirements = (OpSys == "WINDOWS")
queue
```

Explicando linha por linha:

| Linha | O que faz |
|---|---|
| `executable = teste.bat` | Diz ao HTCondor qual arquivo executar. Precisa estar no mesmo diretório da submissão (ou você indica o caminho). |
| `arguments =` | Argumentos de linha de comando para o executável. Aqui está vazio, pois o `.bat` não recebe parâmetros. |
| `output = saida_windows.out` | Arquivo onde o HTCondor vai salvar tudo que o programa imprimir na **saída padrão** (stdout) — no caso, os `echo`. |
| `error = saida_windows.err` | Arquivo onde vai qualquer mensagem de **erro** (stderr) do programa. |
| `log = job_windows.log` | Arquivo de **log do próprio HTCondor**: registra o ciclo de vida do job (quando foi submetido, para qual máquina foi, quando terminou, etc.). Não é o log do seu programa, é o log do sistema. |
| `request_cpus = 1` | Quantos núcleos de CPU o job precisa. |
| `request_memory = 512MB` | Quanta memória RAM reservar para o job. |
| `requirements = (OpSys == "WINDOWS")` | Uma condição que a máquina de execução precisa satisfazer. Aqui, exige que seja uma máquina Windows. |
| `queue` | Comando que efetivamente **enfileira o job**. Sem essa linha, nada é submetido. |

> 💡 **Dica:** `queue` pode vir com um número (ex.: `queue 5`) para submeter várias cópias idênticas do mesmo job de uma vez — mas isso é assunto para um job mais avançado.

---

## 3. Como submeter o job

No terminal, dentro da pasta onde estão `job.sub` e `teste.bat`:

```
condor_submit job.sub
```

O HTCondor vai responder com algo como:
```
Submitting job(s).
1 job(s) submitted to cluster 4.
```

Isso significa que seu job recebeu o **Cluster ID 4** (o número pode variar). Esse número é usado para consultar ou cancelar o job depois.

---

## 4. Acompanhando a execução

Enquanto o job roda (ou já rodou), você pode consultar a fila com:

```
condor_q
```

E, se quiser acompanhar o log em tempo real:

```
condor_tail -f 4
```

(troque `4` pelo ID do seu cluster)

---

## 5. Entendendo o `job_windows.log`

Este arquivo é o "diário de bordo" do job, gerado automaticamente pelo HTCondor. Veja os eventos principais do nosso exemplo:

```
000 ... Job submitted from host: ...
```
→ Evento **000**: o job foi submetido. Mostra de qual máquina (o *submit node*) partiu a submissão.

```
040 ... Started transferring input files
040 ... Finished transferring input files
```
→ Evento **040**: transferência de arquivos de entrada (o `teste.bat`) para a máquina que vai executar.

```
001 ... Job executing on host: <10.90.67.201:9618...alias=DESKTOP-MOQMNFK...>
	SlotName: slot1_1@DESKTOP-MOQMNFK
	Cpus = 1
	Memory = 512
```
→ Evento **001**: o job começou a executar, e mostra **em qual máquina** (aqui, `DESKTOP-MOQMNFK`) e com quais recursos alocados.

```
006 ... Image size of job updated: 1
	3  -  MemoryUsage of job (MB)
```
→ Evento **006**: atualização de uso de memória do job durante a execução.

```
040 ... Started transferring output files
040 ... Finished transferring output files
```
→ Transferência dos arquivos de saída de volta para o submit node.

```
005 ... Job terminated.
	(1) Normal termination (return value 0)
```
→ Evento **005**: o job terminou. `return value 0` significa que terminou **com sucesso** (por convenção, `0` = sem erros). Também mostra estatísticas de uso de CPU, memória e tempo.

**Resumo dos números de evento mais comuns:**

| Código | Significado |
|---|---|
| 000 | Job submetido |
| 040 | Transferência de arquivos (entrada ou saída) |
| 001 | Job começou a executar |
| 006 | Atualização de uso de recursos |
| 005 | Job terminado |

---

## 6. Os arquivos de saída

- **`saida_windows.out`** — contém exatamente o que o `echo` do `.bat` imprimiu:
  ```
  Ola do HTCondor no Windows!
  Hostname: DESKTOP-MOQMNFK
  Data/Hora: 29/07/2026 17:49:03,90
  Job concluido com sucesso.
  ```
- **`saida_windows.err`** — está vazio, porque o script não gerou nenhum erro.

Se o script tivesse falhado (por exemplo, um comando não encontrado), a mensagem de erro apareceria aqui, e isso normalmente é o **primeiro lugar a olhar** quando um job não funciona como esperado.

---

## 7. Resumindo o fluxo completo

```
Você escreve teste.bat  →  Você escreve job.sub
        │                          │
        └────────► condor_submit job.sub
                          │
                 HTCondor escolhe uma máquina
                 que atenda aos "requirements"
                          │
                 Transfere teste.bat para lá
                          │
                 Executa e captura stdout/stderr
                          │
                 Devolve os resultados (.out/.err)
                 e registra tudo no .log
```

---

## Checklist para você submeter seu próprio job simples

- [ ] Tenho um executável/script pronto (`.bat`, `.exe`, `.py`, etc.)
- [ ] Criei um arquivo `.sub` apontando `executable`, `output`, `error` e `log`
- [ ] Defini `request_cpus` e `request_memory` compatíveis com o que meu programa precisa
- [ ] Defini `requirements` se preciso de um sistema operacional específico
- [ ] Terminei o arquivo com `queue`
- [ ] Rodei `condor_submit job.sub`
- [ ] Conferi o `.log` para ver se o job rodou e terminou com sucesso
- [ ] Conferi o `.out` (e o `.err`, se algo der errado)

---

No próximo tutorial (Job 2), vamos aumentar um pouco a complexidade.
