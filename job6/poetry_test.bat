@echo off
rem Job 6b: instala Poetry + torch dentro do sandbox do job e roda teste_torch.py
setlocal
set "PY312=C:\Program Files\Python312\python.exe"
set "WORK=%_CONDOR_SCRATCH_DIR%"
if "%WORK%"=="" set "WORK=%CD%"

rem Tudo (cache, temporarios) fica dentro do diretorio do job.
rem O TEMP padrao do usuario de slot nao existe, por isso apontamos para o scratch.
set "PYTHONUTF8=1"
set "TEMP=%WORK%\tmp"
set "TMP=%WORK%\tmp"
set "PIP_CACHE_DIR=%WORK%\pip-cache"
set "POETRY_CACHE_DIR=%WORK%\poetry-cache"
set "POETRY_CONFIG_DIR=%WORK%\poetry-config"
set "POETRY_DATA_DIR=%WORK%\poetry-data"
set "POETRY_NO_INTERACTION=1"
set "PYTHON_KEYRING_BACKEND=keyring.backends.null.Keyring"
mkdir "%TEMP%" 2>nul

echo === [1] Python ===
"%PY312%" --version || (echo ERRO no passo 1 & exit /b 1)

echo === [2] venv do Poetry ===
"%PY312%" mkvenv.py "%WORK%\poetry-env" || (echo ERRO no passo 2: criar venv do Poetry & exit /b 2)

echo === [3] pip install poetry ===
"%WORK%\poetry-env\Scripts\python.exe" -m pip install --upgrade pip poetry || (echo ERRO no passo 3: pip install poetry & exit /b 3)
set "POETRY=%WORK%\poetry-env\Scripts\poetry.exe"
"%POETRY%" --version || (echo ERRO no passo 3b: poetry --version & exit /b 3)

rem O Poetry cria venvs com o pacote virtualenv, que pode bater no mesmo erro.
rem Criamos o venv do projeto nos mesmos moldes e o "ativamos": o Poetry usa
rem o venv ativo (VIRTUAL_ENV) em vez de criar um novo.
echo === [4] venv do projeto ===
"%PY312%" mkvenv.py "%WORK%\.venv" || (echo ERRO no passo 4: criar venv do projeto & exit /b 4)
set "VIRTUAL_ENV=%WORK%\.venv"
set "PATH=%WORK%\.venv\Scripts;%PATH%"

echo === [5] poetry install (torch) ===
"%POETRY%" install --no-root -vv || (echo ERRO no passo 5: poetry install & exit /b 5)

echo === [6] teste_torch.py ===
"%POETRY%" run python teste_torch.py || (echo ERRO no passo 6: teste_torch & exit /b 6)
endlocal
