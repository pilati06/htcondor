@echo off
rem Diagnostico do Python no no Windows (roda como job do HTCondor)
echo === Diagnostico do Python ===
echo Hostname: %COMPUTERNAME%
echo Usuario:  %USERNAME%
echo Scratch:  %_CONDOR_SCRATCH_DIR%
echo.
echo --- Pythons no PATH ---
where python 2>nul
where py 2>nul
py -0p 2>nul
echo.
set "PY312=C:\Program Files\Python312\python.exe"
if not exist "%PY312%" (
    echo ERRO: %PY312% nao existe. Rode instalar_python312.ps1 neste no.
    exit /b 1
)
"%PY312%" --version || exit /b 1
"%PY312%" -m pip --version || exit /b 2
"%PY312%" -m venv "%_CONDOR_SCRATCH_DIR%\venv_teste" || exit /b 3
"%_CONDOR_SCRATCH_DIR%\venv_teste\Scripts\python.exe" -m pip --version || exit /b 4
echo.
echo OK: Python 3.12, pip e venv funcionando no slot do HTCondor.
