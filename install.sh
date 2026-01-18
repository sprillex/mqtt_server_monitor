#!/bin/bash

# Exit on error
set -e

echo "--- Starting MQTT Server Monitor Installation ---"

# 1. Install system dependencies
sudo apt update
sudo apt install -y python3-pip python3-venv

# 2. Setup Virtual Environment
if [ ! -d "venv" ]; then
    echo "Creating virtual environment..."
    python3 -m venv venv
fi

# 3. Install Python requirements
echo "Installing Python dependencies..."
source venv/bin/activate
pip install -r requirements.txt

# 4. Handle .env file
if [ ! -f ".env" ]; then
    echo "Creating .env from example..."
    cp .env.example .env
    echo "!!! IMPORTANT: Edit the .env file with your MQTT credentials !!!"
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

echo "--- Installation Complete ---"
echo "1. Edit your credentials: nano .env"
echo "2. Start the service: sudo systemctl start mqtt_monitor.service"
