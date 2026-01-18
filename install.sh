#!/bin/bash

# Exit on error
set -e

echo "--- MQTT Server Monitor Installation ---"

# 1. Install system dependencies
sudo apt update
sudo apt install -y python3-pip python3-venv

# 2. Setup Virtual Environment (User's preferred best practice)
if [ ! -d "venv" ]; then
    echo "Creating virtual environment..."
    python3 -m venv venv
fi

# 3. Install Python requirements
echo "Installing Python dependencies..."
source venv/bin/activate
pip install -r requirements.txt

# 4. Interactive Configuration
if [ ! -f ".env" ]; then
    echo ""
    echo "--- Configuration ---"
    read -p "Enter MQTT Broker IP (e.g., 192.168.1.50): " mqtt_ip
    read -p "Enter MQTT Username: " mqtt_user
    read -sp "Enter MQTT Password: " mqtt_pass
    echo ""
    read -p "Enter a Unique Name for this Device (e.g., DietPi_Kitchen): " device_name
    
    cat > .env <<EOF
MQTT_BROKER=$mqtt_ip
MQTT_USER=$mqtt_user
MQTT_PASS=$mqtt_pass
MQTT_PORT=1883
DEVICE_NAME=$device_name
INTERVAL=60
EOF
    echo ".env file created successfully."
else
    echo ".env file already exists. Skipping configuration."
fi

# 5. Setup Systemd Service
echo "Configuring systemd service..."
SERVICE_FILE="/etc/systemd/system/mqtt_monitor.service"
WORKING_DIR=$(pwd)

sudo bash -c "cat > $SERVICE_FILE" <<EOF
[Unit]
Description=MQTT System Monitor Service
After=network.target

[Service]
Type=simple
User=$USER
WorkingDirectory=$WORKING_DIR
ExecStart=$WORKING_DIR/venv/bin/python $WORKING_DIR/monitor.py
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable mqtt_monitor.service

echo ""
echo "--- Installation Complete ---"
echo "To start the monitor now, run: sudo systemctl start mqtt_monitor.service"
