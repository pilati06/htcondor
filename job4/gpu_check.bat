@echo off
setlocal EnableDelayedExpansion
echo === Verificacao de GPU ===
echo Hostname: %COMPUTERNAME%
echo Data: %DATE% %TIME%
echo Usuario: %USERNAME%
echo CUDA_VISIBLE_DEVICES = %CUDA_VISIBLE_DEVICES%
echo PATH = %PATH%
echo.

rem O HTCondor monta um ambiente minimo para o job: o PATH do servico
rem pode nao conter as pastas do driver NVIDIA. Por isso procuramos o
rem nvidia-smi.exe pelos caminhos conhecidos, e so depois pelo PATH.
set "NVSMI="
for %%P in (
    "C:\Windows\System32\nvidia-smi.exe"
    "C:\Program Files\NVIDIA Corporation\NVSMI\nvidia-smi.exe"
) do (
    if not defined NVSMI if exist %%P set "NVSMI=%%~P"
)

rem Drivers DCH tambem guardam o nvidia-smi no DriverStore
if not defined NVSMI (
    for /d %%D in ("C:\Windows\System32\DriverStore\FileRepository\nv*") do (
        if not defined NVSMI if exist "%%D\nvidia-smi.exe" set "NVSMI=%%D\nvidia-smi.exe"
    )
)

rem Por ultimo, o PATH do job (where.exe chamado pelo caminho completo,
rem porque o proprio System32 pode estar fora do PATH)
if not defined NVSMI (
    for /f "delims=" %%F in ('C:\Windows\System32\where.exe nvidia-smi 2^>nul') do (
        if not defined NVSMI set "NVSMI=%%F"
    )
)

if defined NVSMI (
    echo nvidia-smi encontrado em: !NVSMI!
    echo.
    "!NVSMI!"
    exit /b !ERRORLEVEL!
) else (
    echo nvidia-smi nao encontrado
    echo Verifique se o driver NVIDIA esta instalado nesta maquina.
    exit /b 1
)
