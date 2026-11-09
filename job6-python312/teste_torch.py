import platform
import socket
import sys

import torch

print(f"No: {socket.gethostname()}")
print(f"Sistema: {platform.system()} {platform.release()}")
print(f"Python: {sys.version.split()[0]} ({sys.executable})")
print(f"torch: {torch.__version__}")
print(f"CUDA disponivel: {torch.cuda.is_available()}")
if torch.cuda.is_available():
    print(f"GPU: {torch.cuda.get_device_name(0)}")
    x = torch.rand(1000, 1000, device="cuda")
    print(f"Soma de teste na GPU: {(x @ x).sum().item():.2f}")
else:
    x = torch.rand(1000, 1000)
    print(f"Soma de teste na CPU: {(x @ x).sum().item():.2f}")
