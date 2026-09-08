#!/bin/bash

# Se a imagem docker padrão do Python não tiver o pandas, instala rapidamente no contêiner
pip install --no-cache-dir pandas > /dev/null 2>&1

# Executa o script repassando o nome do arquivo recebido como argumento
python3 analyse.py "$1"
