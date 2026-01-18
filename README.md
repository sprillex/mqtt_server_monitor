# MQTT Server Monitor

A lightweight Python script designed for **DietPi** (Raspberry Pi) that pushes system metrics to **Home Assistant** via MQTT. It supports multiple devices, secure credential management via `.env`, and utilizes Home Assistant's MQTT Discovery.

## Features
* **CPU Usage (%)**
* **RAM Usage (%)**
* **CPU Temperature (°C)**
* **Disk Space Available (GB)**
* **Updates Pending** (Specific to DietPi & APT)

## Installation

1. **Clone the repository:**
   ```bash
   git clone [https://github.com/sprillex/mqtt_server_monitor.git](https://github.com/sprillex/mqtt_server_monitor.git)
   cd mqtt_server_monitor
## Quick Install
```bash
chmod +x install.sh
./install.sh
