"""Diagnostico do WinError -2147467259 (E_FAIL) ao criar venv no slot Windows.

Testa cada operacao que o venv faz, separadamente, e imprime o traceback
completo de qualquer falha. No final tenta criar o venv com um contorno
(sem a API CopyFile2 do Windows).
"""
import os
import shutil
import subprocess
import sys
import tempfile
import traceback

WORK = os.environ.get("_CONDOR_SCRATCH_DIR") or os.getcwd()
SRC = sys.executable


def passo(nome, func):
    print(f"\n--- {nome} ---", flush=True)
    try:
        r = func()
        print(f"OK {r if r is not None else ''}", flush=True)
        return True
    except Exception:
        traceback.print_exc(file=sys.stdout)
        sys.stdout.flush()
        return False


print("Python:", sys.version)
print("Executavel:", SRC)
print("Scratch:", WORK)
print("Usuario:", os.environ.get("USERNAME"), "| USERPROFILE:", os.environ.get("USERPROFILE"))
print("TEMP:", os.environ.get("TEMP"), "| tempfile:", tempfile.gettempdir())
subprocess.run(["fsutil", "fsinfo", "volumeinfo", WORK[:3]], check=False)

passo("escrever arquivo de texto", lambda: open(os.path.join(WORK, "t.txt"), "w").write("x"))
passo("shutil.copyfile python.exe", lambda: shutil.copyfile(SRC, os.path.join(WORK, "c1.exe")))
passo("shutil.copy2 python.exe (usa CopyFile2)", lambda: shutil.copy2(SRC, os.path.join(WORK, "c2.exe")))
passo("os.symlink", lambda: os.symlink(SRC, os.path.join(WORK, "link.exe")))
passo("tempfile.mkdtemp", tempfile.mkdtemp)
passo("venv --without-pip", lambda: subprocess.run(
    [SRC, "-m", "venv", "--without-pip", os.path.join(WORK, "v1")], check=True))
passo("ensurepip dentro do venv", lambda: subprocess.run(
    [os.path.join(WORK, "v1", "Scripts", "python.exe"), "-m", "ensurepip"], check=True))

# Contorno: remove CopyFile2 para o shutil usar o caminho antigo de copia
codigo = ("import _winapi, runpy, sys;"
          "hasattr(_winapi, 'CopyFile2') and delattr(_winapi, 'CopyFile2');"
          "sys.argv=['venv', sys.argv[1]];"
          "runpy.run_module('venv', run_name='__main__')")
passo("venv completo SEM CopyFile2", lambda: subprocess.run(
    [SRC, "-c", codigo, os.path.join(WORK, "v2")], check=True))
