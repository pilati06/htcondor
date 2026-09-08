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
