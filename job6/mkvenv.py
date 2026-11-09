"""Cria um venv do jeito que funcionou no diagnostico do lab1-desktop-23:
sem a API CopyFile2 do Windows e com o pip instalado via ensurepip depois.

Uso: python mkvenv.py <pasta_do_venv>
"""
import os
import subprocess
import sys

import _winapi

if hasattr(_winapi, "CopyFile2"):
    delattr(_winapi, "CopyFile2")

import venv  # noqa: E402

destino = sys.argv[1]
venv.EnvBuilder(with_pip=False, symlinks=False, clear=True).create(destino)
py = os.path.join(destino, "Scripts", "python.exe")
subprocess.run([py, "-m", "ensurepip", "--upgrade", "--default-pip"], check=True)
print(f"venv pronto: {py}")
