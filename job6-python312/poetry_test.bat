@echo off
rem Job 6b: instala Poetry + torch dentro do sandbox do job e roda teste_torch.py
setlocal
set "PY312=C:\Program Files\Python312\python.exe"
set "WORK=%_CONDOR_SCRATCH_DIR%"
if "%WORK%"=="" set "WORK=%CD%"

rem O usuario de slot nao tem um perfil normal: tudo (cache, venvs, poetry)
rem fica dentro do diretorio do job, que o HTCondor apaga no final.
set "PYTHONUTF8=1"
set "PIP_CACHE_DIR=%WORK%\pip-cache"
set "POETRY_CACHE_DIR=%WORK%\poetry-cache"
set "POETRY_CONFIG_DIR=%WORK%\poetry-config"
set "POETRY_VIRTUALENVS_IN_PROJECT=true"
set "POETRY_NO_INTERACTION=1"
set "APPDATA=%WORK%\appdata"
set "LOCALAPPDATA=%WORK%\localappdata"
set "TEMP=%WORK%\tmp"
set "TMP=%WORK%\tmp"
mkdir "%APPDATA%" "%LOCALAPPDATA%" "%TEMP%" 2>nul

echo === Python ===
"%PY312%" --version || exit /b 1

rem Poetry em um venv proprio (evita o instalador oficial, que era o que falhava)
echo === Instalando Poetry ===
"%PY312%" -m venv "%WORK%\poetry-env" || exit /b 2
"%WORK%\poetry-env\Scripts\python.exe" -m pip install --quiet --upgrade pip poetry || exit /b 3
set "POETRY=%WORK%\poetry-env\Scripts\poetry.exe"
"%POETRY%" --version || exit /b 4

echo === poetry install (torch) ===
"%POETRY%" env use "%PY312%" || exit /b 5
"%POETRY%" install --no-root || exit /b 6

echo === Rodando teste_torch.py ===
"%POETRY%" run python teste_torch.py || exit /b 7
endlocal
