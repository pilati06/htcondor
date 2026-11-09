Job 6 - Python 3.12 + Poetry + torch no no Windows (lab1-desktop-23)

Problema: o slot Windows lab1-desktop-23 so tem Python 3.14.7 com pip quebrado,
entao venv, o instalador do Poetry e o torch falham (clusters 31-33).

1) No lab1-desktop-23, PowerShell como Administrador:
     Set-ExecutionPolicy -Scope Process Bypass -Force
     .\instalar_python312.ps1
2) Ainda no lab1-desktop-23, copie config\99-python312.config para
   C:\condor\config\ e rode:  condor_reconfig
3) Na maquina de submissao, confira que o no anuncia o Python 3.12:
     condor_status -const "HAS_PYTHON312 =?= True" -af Machine PYTHON312_PATH
4) Diagnostico rapido:   condor_submit check_python.sub
   O .out deve terminar com "OK: Python 3.12, pip e venv funcionando..."
5) Teste do Poetry+torch: condor_submit poetry_test.sub
   O .out deve mostrar a versao do torch e "CUDA disponivel: True".

Sem GPU ou para um teste mais leve: em pyproject.toml troque a url da fonte
para https://download.pytorch.org/whl/cpu e tire request_gpus do poetry_test.sub.
