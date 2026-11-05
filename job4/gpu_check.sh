#!/bin/bash
echo "=== Verificação de GPU ==="
echo "Hostname: $(hostname)"
echo "Data: $(date)"
echo "CUDA_VISIBLE_DEVICES = $CUDA_VISIBLE_DEVICES"

# No WSL2 o nvidia-smi fica em /usr/lib/wsl/lib, que nem sempre esta no PATH
export PATH="$PATH:/usr/lib/wsl/lib"

if command -v nvidia-smi >/dev/null 2>&1; then
    nvidia-smi
else
    echo "nvidia-smi não encontrado (esperado se não houver GPU NVIDIA)"
fi

# Placas de qualquer fabricante
command -v lspci >/dev/null 2>&1 && lspci | grep -i -E "vga|3d|display"
