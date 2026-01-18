import os
import time
import json
import paho.mqtt.client as mqtt
from dotenv import load_dotenv
from sensors import get_stats

# Load environment variables
load_dotenv()

MQTT_BROKER = os.getenv("MQTT_BROKER")
MQTT_USER = os.getenv("MQTT_USER")
MQTT_PASS = os.getenv("MQTT_PASS")
DEVICE_NAME = os.getenv("DEVICE_NAME", "DietPi_Node")
INTERVAL = int(os.getenv("INTERVAL", 60))

client = mqtt.Client()
client.username_pw_set(MQTT_USER, MQTT_PASS)

def publish_discovery():
    """Registers sensors in Home Assistant using MQTT Auto-Discovery."""
    sensors = [
        ("CPU_Usage", "CPU Usage", "%", "mdi:cpu-64bit"),
        ("RAM_Usage", "RAM Usage", "%", "mdi:memory"),
        ("Temperature", "Temperature", "°C", "mdi:thermometer"),
        ("Disk_Available", "Disk Available", "GB", "mdi:harddisk"),
        ("Updates", "Updates Available", "updates", "mdi:update")
    ]
    
    for key, name, unit, icon in sensors:
        topic = f"homeassistant/sensor/{DEVICE_NAME}/{key}/config"
        payload = {
            "name": f"{DEVICE_NAME} {name}",
            "state_topic": f"homeassistant/sensor/{DEVICE_NAME}/state",
            "value_template": f"{{{{ value_json.{key} }}}}",
            "unit_of_measurement": unit,
            "icon": icon,
            "unique_id": f"{DEVICE_NAME}_{key}".lower(),
            "device": {
                "identifiers": [DEVICE_NAME],
                "name": DEVICE_NAME,
                "manufacturer": "DietPi",
                "model": "Raspberry Pi 4"
            }
        }
        client.publish(topic, json.dumps(payload), retain=True)

def main():
    print(f"Starting monitor for {DEVICE_NAME}...")
    client.connect(MQTT_BROKER, 1883, 60)
    publish_discovery()
    
    while True:
        try:
            stats = get_stats()
            client.publish(f"homeassistant/sensor/{DEVICE_NAME}/state", json.dumps(stats))
        except Exception as e:
            print(f"Error: {e}")
        time.sleep(INTERVAL)

if __name__ == "__main__":
    main()
