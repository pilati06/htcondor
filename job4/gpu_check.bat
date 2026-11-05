@echo off
setlocal EnableDelayedExpansion
echo === Verificacao de GPU ===
echo Hostname: %COMPUTERNAME%
echo Data: %DATE% %TIME%
echo Usuario: %USERNAME%
echo.
echo --- GPU reservada pelo HTCondor ---
echo _CONDOR_AssignedGPUs = %_CONDOR_AssignedGPUs%
echo CUDA_VISIBLE_DEVICES = %CUDA_VISIBLE_DEVICES%
echo GPU_DEVICE_ORDINAL   = %GPU_DEVICE_ORDINAL%
echo.

rem Lista as placas de video de qualquer fabricante (NVIDIA, AMD, Intel).
rem Caminho completo do PowerShell, porque o PATH do job pode ser minimo.
echo --- Placas de video desta maquina ---
"C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe" -NoProfile -Command "Get-CimInstance Win32_VideoController | Format-List Name,AdapterCompatibility,DriverVersion,AdapterRAM"

rem nvidia-smi so existe com placa e driver NVIDIA.
set "NVSMI="
for %%P in (
    "C:\Windows\System32\nvidia-smi.exe"
    "C:\Program Files\NVIDIA Corporation\NVSMI\nvidia-smi.exe"
) do (
    if not defined NVSMI if exist %%P set "NVSMI=%%~P"
)

echo --- NVIDIA ---
if defined NVSMI (
    "!NVSMI!"
) else (
    echo nvidia-smi nao encontrado: a placa nao e NVIDIA ou o driver NVIDIA nao esta instalado.
    echo Placas AMD/Intel nao usam nvidia-smi nem CUDA. Use OpenCL, DirectML ou oneAPI.
)
exit /b 0
