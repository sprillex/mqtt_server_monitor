#!/bin/bash

# Exit on error
set -e

echo "--- MQTT Server Monitor Installation ---"

# 1. Ask for the System User
read -p "Enter the system user to run this service (e.g., dietpi): " TARGET_USER

# Check if user exists
if ! id "$TARGET_USER" >/dev/null 2>&1; then
    echo "Error: User '$TARGET_USER' does not exist. Please create the user or check the spelling."
    exit 1
fi

WORKING_DIR=$(pwd)

# 2. Install system dependencies
apt update
apt install -y python3-pip python3-venv

# 3. Setup Virtual Environment
if [ ! -d "venv" ]; then
    echo "Creating virtual environment..."
    python3 -m venv venv
fi

# 4. Install Python requirements
echo "Installing Python dependencies..."
./venv/bin/pip install -r requirements.txt

# 5. Interactive MQTT Configuration
if [ ! -f ".env" ]; then
    echo ""
    echo "--- MQTT Configuration ---"
    read -p "Enter MQTT Broker IP: " mqtt_ip
    read -p "Enter MQTT Username: " mqtt_user
    read -sp "Enter MQTT Password: " mqtt_pass
    echo ""
    read -p "Enter a Unique Name for this Device: " device_name
    
    cat > .env <<EOF
MQTT_BROKER=$mqtt_ip
MQTT_USER=$mqtt_user
MQTT_PASS=$mqtt_pass
MQTT_PORT=1883
DEVICE_NAME=$device_name
INTERVAL=60
EOF
fi

# 6. Fix Ownership
echo "Adjusting permissions for $TARGET_USER..."
chown -R $TARGET_USER:$TARGET_USER $WORKING_DIR

# 7. Setup Systemd Service
echo "Configuring systemd service..."
SERVICE_FILE="/etc/systemd/system/mqtt_monitor.service"

cat > $SERVICE_FILE <<EOF
[Unit]
Description=MQTT System Monitor Service
After=network.target

[Service]
Type=simple
User=$TARGET_USER
Group=$TARGET_USER
WorkingDirectory=$WORKING_DIR
ExecStart=$WORKING_DIR/venv/bin/python $WORKING_DIR/monitor.py
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable mqtt_monitor.service

echo ""
echo "--- Installation Complete ---"
echo "The service is configured to run as: $TARGET_USER"
echo "To start it now, run: sudo systemctl start mqtt_monitor.service"
