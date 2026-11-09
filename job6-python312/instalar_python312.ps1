# Instala o Python 3.12 para TODOS os usuarios no no Windows do HTCondor
# (ex.: lab1-desktop-23). Rode em um PowerShell como Administrador:
#
#   Set-ExecutionPolicy -Scope Process Bypass -Force
#   .\instalar_python312.ps1
#
# Por que "todos os usuarios": os jobs do HTCondor no Windows rodam como um
# usuario de slot (condor-slotN), que nao enxerga um Python instalado so para
# o seu usuario (AppData\Local\Programs\Python).
#
# O Python 3.14 atual NAO e removido; o 3.12 fica ao lado, em
# C:\Program Files\Python312, e os jobs chamam esse caminho explicitamente.

$ErrorActionPreference = "Stop"
$versao    = "3.12.10"   # ultima versao 3.12 com instalador oficial
$url       = "https://www.python.org/ftp/python/$versao/python-$versao-amd64.exe"
$destino   = "C:\Program Files\Python312"
$instalador = Join-Path $env:TEMP "python-$versao-amd64.exe"

if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    throw "Rode este script em um PowerShell como Administrador."
}

if (-not (Test-Path "$destino\python.exe")) {
    Write-Host "Baixando $url ..."
    Invoke-WebRequest -Uri $url -OutFile $instalador -UseBasicParsing
    Write-Host "Instalando em $destino ..."
    $argList = @(
        "/quiet",
        "InstallAllUsers=1",
        "TargetDir=`"$destino`"",
        "PrependPath=0",          # nao mexe no PATH global; os jobs usam o caminho completo
        "Include_pip=1",
        "Include_launcher=1",
        "InstallLauncherAllUsers=1",
        "Include_test=0",
        "Shortcuts=0"
    )
    $p = Start-Process -FilePath $instalador -ArgumentList $argList -Wait -PassThru
    if ($p.ExitCode -ne 0) { throw "Instalador terminou com codigo $($p.ExitCode)" }
} else {
    Write-Host "Python 3.12 ja existe em $destino, pulando a instalacao."
}

$py = "$destino\python.exe"

Write-Host "`n== Verificando =="
& $py --version
# Garante um pip funcional (reinstala a partir do ensurepip embutido se preciso)
& $py -m ensurepip --upgrade --default-pip
& $py -m pip --version
if ($LASTEXITCODE -ne 0) { throw "pip continua quebrado no Python 3.12" }

# Teste de venv em uma pasta temporaria (o mesmo passo que falhava no 3.14)
$tmpVenv = Join-Path $env:TEMP "teste-venv-312"
if (Test-Path $tmpVenv) { Remove-Item -Recurse -Force $tmpVenv }
& $py -m venv $tmpVenv
& "$tmpVenv\Scripts\python.exe" -m pip --version
if ($LASTEXITCODE -ne 0) { throw "venv criado, mas o pip dentro dele falhou" }
Remove-Item -Recurse -Force $tmpVenv

# Permite que os usuarios de slot leiam/executem o Python
icacls $destino /grant "*S-1-5-32-545:(OI)(CI)RX" /T /Q | Out-Null   # BUILTIN\Users

Write-Host "`nOK: Python 3.12 com pip e venv funcionando em $destino"
Write-Host "Proximo passo: copie config\99-python312.config para C:\condor\config\ e rode 'condor_reconfig'."
