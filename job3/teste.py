import platform
import socket
from datetime import datetime

print(f"Nó: {socket.gethostname()}")
print(f"Sistema: {platform.system()} {platform.release()}")
print(f"Data: {datetime.now()}")
