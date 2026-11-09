@echo off
set "PYTHONUTF8=1"
whoami
"C:\Program Files\Python312\python.exe" -X faulthandler diag_venv.py
