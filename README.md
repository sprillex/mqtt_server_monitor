# MQTT Server Monitor

MQTT Server Monitor is a lightweight Python service designed for DietPi and Raspberry Pi single-board computers that collects system hardware metrics and pushes them to Home Assistant via MQTT. It utilizes Home Assistant's MQTT Auto-Discovery specification to automatically register and create sensors upon startup without manual entity configuration. Secure credential handling is supported out-of-the-box via environment variable configuration.

## Features

* **CPU Usage Tracking**: Real-time measurement of host CPU utilization percentage.
* **RAM Memory Monitoring**: Tracks virtual memory usage percentage.
* **CPU Thermal Sensor**: Reads hardware core temperature in °C from system thermal zones.
* **Disk Space Monitoring**: Calculates free storage space on the root filesystem (`/`) in GB.
* **APT Update Detection**: Reads pending APT/DietPi package update counts.
* **Home Assistant Auto-Discovery**: Automatically provisions entity configs and device metadata via MQTT retain payloads.
* **Systemd Daemon Integration**: Automated installation script configures background daemon execution and reboot resilience.

## Tech Stack & Architecture

* **Runtime**: Python 3.7+
* **MQTT Client**: `paho-mqtt`
* **System Metrics Gathering**: `psutil`
* **Environment Configuration**: `python-dotenv`
* **Target OS / Hardware**: DietPi / Debian / Raspberry Pi OS on ARM architectures
* **Architecture**: Event-driven background publisher client pushing JSON payloads over MQTT/TCP to a target broker (e.g., Mosquitto, Home Assistant MQTT Addon).

## Repository Layout

```
.
├── .env.example       # Sample environment configuration template
├── .gitignore         # Git ignore rules for virtual environments and credentials
├── README.md          # Project documentation overview and operational guide
├── API.md             # Detailed MQTT topic schemas, discovery payloads, and payload specs
├── install.sh         # Automated interactive installation and systemd installer script
├── monitor.py         # Application entry point: manages MQTT connection, auto-discovery, and publish loop
├── requirements.txt   # Python dependency declarations
└── sensors.py         # Hardware metric extraction functions utilizing psutil and Linux sysfs
```

## Prerequisites & Setup

### Prerequisites

* Python 3.7 or higher
* System administrator (`sudo`) access (for installing system packages and setting up systemd service)
* Access to an operational MQTT Broker (e.g. Mosquitto)

### Quick Automated Installation

The included interactive `install.sh` script automates virtual environment creation, package installation, `.env` prompt generation, and systemd service setup:

```bash
chmod +x install.sh
sudo ./install.sh
```

### Manual Setup

1. **Clone the repository:**
   ```bash
   git clone https://github.com/sprillex/mqtt_server_monitor.git
   cd mqtt_server_monitor
   ```

2. **Create and activate a virtual environment:**
   ```bash
   python3 -m venv venv
   source venv/bin/activate
   ```

3. **Install Python dependencies:**
   ```bash
   pip install -r requirements.txt
   ```

4. **Configure environment variables:**
   ```bash
   cp .env.example .env
   ```
   Edit `.env` with your MQTT broker credentials and device settings.

## Configuration

Environment configuration is managed via a `.env` file located in the project root directory.

| Variable Name | Default Value | Description |
|---|---|---|
| `MQTT_BROKER` | `192.168.1.50` | IP address or hostname of your MQTT Broker |
| `MQTT_PORT` | `1883` | TCP port of the MQTT Broker |
| `MQTT_USER` | `homeassistant` | MQTT connection username |
| `MQTT_PASS` | `your_secure_password` | MQTT connection password |
| `DEVICE_NAME` | `DietPi_Server` | Device identifier and Home Assistant entity prefix |
| `INTERVAL` | `60` | Telemetry publishing interval in seconds |

Example `.env` configuration:

```env
MQTT_BROKER=192.168.1.50
MQTT_USER=homeassistant
MQTT_PASS=your_secure_password
MQTT_PORT=1883
DEVICE_NAME=DietPi_Server
INTERVAL=60
```

## Running the Application

### Development / Direct Execution

Run the script directly from your terminal using the virtual environment interpreter:

```bash
./venv/bin/python monitor.py
```

Or activate the environment first:

```bash
source venv/bin/activate
python monitor.py
```

### Systemd Service Management (Production)

If installed using `install.sh`, the service is managed by `systemd` under `mqtt_monitor.service`:

* **Start Service**:
  ```bash
  sudo systemctl start mqtt_monitor.service
  ```
* **Stop Service**:
  ```bash
  sudo systemctl stop mqtt_monitor.service
  ```
* **Check Service Status**:
  ```bash
  sudo systemctl status mqtt_monitor.service
  ```
* **View Daemon Logs**:
  ```bash
  sudo journalctl -u mqtt_monitor.service -f
  ```

## Testing & Verification

To verify script syntax and check python source files:

```bash
# Compilation check
python3 -m py_compile monitor.py sensors.py

# Run static analysis / linter if flake8 is installed
flake8 monitor.py sensors.py
```

## API & MQTT Interface Reference

The MQTT Server Monitor does not expose traditional HTTP REST endpoints. Instead, it interacts via MQTT message topics and JSON payloads using Home Assistant's MQTT Auto-Discovery protocol.

For full details on MQTT topic structures, auto-discovery registration payloads, state telemetry JSON schemas, and authentication specifications, refer to the dedicated interface documentation:

👉 **[API Reference Documentation](./API.md)**
