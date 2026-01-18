import psutil
import os

def get_stats():
    """Gathers system metrics and returns a dictionary."""
    
    # Temperature (Standard for RPi)
    temp = 0
    if os.path.exists("/sys/class/thermal/thermal_zone0/temp"):
        with open("/sys/class/thermal/thermal_zone0/temp", "r") as f:
            temp = round(float(f.read()) / 1000, 1)

    # DietPi/APT Updates
    updates = 0
    if os.path.exists("/run/dietpi/.apt_updates"):
        with open("/run/dietpi/.apt_updates", "r") as f:
            try:
                updates = int(f.read().strip() or 0)
            except ValueError:
                updates = 0

    return {
        "CPU_Usage": psutil.cpu_percent(interval=1),
        "RAM_Usage": psutil.virtual_memory().percent,
        "Temperature": temp,
        "Disk_Available": round(psutil.disk_usage('/').free / (1024**3), 2),
        "Updates": updates
    }
