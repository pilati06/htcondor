#!/bin/bash
echo "=== Verificação de GPU ==="
echo "Hostname: $(hostname)"
echo "Data: $(date)"
echo "CUDA_VISIBLE_DEVICES = $CUDA_VISIBLE_DEVICES"

if command -v nvidia-smi >/dev/null 2>&1; then
    nvidia-smi
else
    echo "nvidia-smi não encontrado (esperado se não houver GPU NVIDIA)"
fi
