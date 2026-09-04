# MQTT Server Monitor API & Interface Specification

This document details the MQTT topics, discovery configurations, authentication mechanisms, and JSON message schemas utilized by the MQTT Server Monitor service to communicate with MQTT brokers and integrate seamlessly with Home Assistant.

---

## Overview

MQTT Server Monitor communicates using the **MQTT** protocol (v3.1.1 / v5.0). Rather than exposed HTTP REST endpoints, the service acts as an MQTT client publisher that periodically transmits host telemetry metrics to an MQTT broker.

* **Protocol**: MQTT / TCP
* **Default Port**: `1883` (unencrypted) or `8883` (TLS)
* **Default Publish Interval**: `60` seconds (configurable via `INTERVAL`)
* **Discovery Protocol**: Home Assistant MQTT Auto-Discovery specification

---

## Authentication

Authentication is handled at the MQTT protocol layer during client connection setup.

* **Scheme**: Basic Username & Password authentication configured on the MQTT broker.
* **Credentials**:
  * `MQTT_USER`: Broker username (e.g., `homeassistant`).
  * `MQTT_PASS`: Broker user password.
* **Client Identification**: Default client identification initialized via `paho.mqtt.client.Client()`.

---

## Standard Envelopes & Message Formats

Messages published by the monitor fall into two categories:

1. **Auto-Discovery Configuration Envelopes**: Published once upon startup with `retain=True` to automatically register individual sensors with Home Assistant.
2. **State Telemetry Envelopes**: Published periodically (every `INTERVAL` seconds) containing all collected host metrics in a single JSON dictionary.

### Standard Error Handling & Reconnection

* **Connection Failures**: If the MQTT broker connection drops or fails on startup, an exception is logged to standard output.
* **Runtime Errors**: Unhandled errors during metric collection or publishing are caught during the execution loop, printed to standard error, and retried on the next interval cycle without crashing the daemon.

---

## MQTT Topics & Message Schemas

### 1. Home Assistant Discovery Configuration

Registers each system sensor in Home Assistant using MQTT Auto-Discovery.

* **Topic Pattern**: `homeassistant/sensor/{DEVICE_NAME}/{key}/config`
* **Access Level**: Publisher
* **Retained Flag**: `True` (`retain=True`)
* **Topic Parameters**:
  * `DEVICE_NAME` *(string, required)*: Unique identifier for the host (e.g., `DietPi_Server`). Defaults to `DietPi_Node`.
  * `key` *(string, required)*: Sensor key identifier. Allowed values: `CPU_Usage`, `RAM_Usage`, `Temperature`, `Disk_Available`, `Updates`.

#### Sensor Definitions & Metadata

| Sensor Key (`key`) | Display Name | Unit | Icon | Description |
|---|---|---|---|---|
| `CPU_Usage` | CPU Usage | `%` | `mdi:cpu-64bit` | Current host CPU utilization percentage. |
| `RAM_Usage` | RAM Usage | `%` | `mdi:memory` | Current host RAM utilization percentage. |
| `Temperature` | Temperature | `°C` | `mdi:thermometer` | CPU thermal zone temperature in Celsius. |
| `Disk_Available` | Disk Available | `GB` | `mdi:harddisk` | Free disk space on root filesystem (`/`) in Gigabytes. |
| `Updates` | Updates Available | `updates` | `mdi:update` | Number of pending APT package updates (DietPi). |

#### Discovery Payload Schema

| Field | Type | Required | Description | Example |
|---|---|---|---|---|
| `name` | string | Yes | Friendly display name in Home Assistant. | `"DietPi_Server CPU Usage"` |
| `state_topic` | string | Yes | MQTT topic where state updates are published. | `"homeassistant/sensor/DietPi_Server/state"` |
| `value_template` | string | Yes | Jinja2 template extracting the specific sensor key from the state payload. | `"{{ value_json.CPU_Usage }}"` |
| `unit_of_measurement` | string | Yes | Unit symbol associated with the sensor metric. | `"%"`, `"°C"`, `"GB"`, `"updates"` |
| `icon` | string | Yes | Material Design Icon identifier. | `"mdi:cpu-64bit"` |
| `unique_id` | string | Yes | Lowercase unique ID across Home Assistant entities. | `"dietpi_server_cpu_usage"` |
| `device` | object | Yes | Device registration payload for grouping sensors under one device. | See below |
| `device.identifiers` | array[string] | Yes | Array containing the unique device identifier. | `["DietPi_Server"]` |
| `device.name` | string | Yes | Friendly device name. | `"DietPi_Server"` |
| `device.manufacturer` | string | Yes | Device manufacturer info. | `"DietPi"` |
| `device.model` | string | Yes | Hardware model. | `"Raspberry Pi 4"` |

#### Concrete Discovery JSON Payload Example (`CPU_Usage`)

```json
{
  "name": "DietPi_Server CPU Usage",
  "state_topic": "homeassistant/sensor/DietPi_Server/state",
  "value_template": "{{ value_json.CPU_Usage }}",
  "unit_of_measurement": "%",
  "icon": "mdi:cpu-64bit",
  "unique_id": "dietpi_server_cpu_usage",
  "device": {
    "identifiers": [
      "DietPi_Server"
    ],
    "name": "DietPi_Server",
    "manufacturer": "DietPi",
    "model": "Raspberry Pi 4"
  }
}
```

---

### 2. State Telemetry Payload

Publishes current system hardware metrics at regular intervals.

* **Topic Pattern**: `homeassistant/sensor/{DEVICE_NAME}/state`
* **Access Level**: Publisher
* **Retained Flag**: `False`
* **Topic Parameters**:
  * `DEVICE_NAME` *(string, required)*: Configured device name (e.g., `DietPi_Server`).

#### State Payload Fields

| Field | Type | Required | Range / Format | Description |
|---|---|---|---|---|
| `CPU_Usage` | float | Yes | `0.0` - `100.0` | Total CPU utilization percentage sampled over a 1-second interval. |
| `RAM_Usage` | float | Yes | `0.0` - `100.0` | Used memory percentage of total system RAM. |
| `Temperature` | float | Yes | `>= 0.0` | CPU core temperature in °C extracted from `/sys/class/thermal/thermal_zone0/temp`. Defaults to `0.0` if path is unavailable. |
| `Disk_Available` | float | Yes | `>= 0.0` | Available space on root partition (`/`) in GB, rounded to 2 decimal places. |
| `Updates` | integer | Yes | `>= 0` | Count of pending APT package updates parsed from `/run/dietpi/.apt_updates`. Defaults to `0` if file does not exist. |

#### Concrete State Telemetry JSON Example

```json
{
  "CPU_Usage": 12.5,
  "RAM_Usage": 34.2,
  "Temperature": 42.8,
  "Disk_Available": 23.45,
  "Updates": 3
}
```

---

## Polling & Telemetry Frequency

* **Interval Configuration**: Set via the `INTERVAL` environment variable in seconds (default: `60`).
* **Sampling Characteristics**:
  * `CPU_Usage` measurement performs a 1-second blocking sample (`psutil.cpu_percent(interval=1)`).
  * Metrics are pushed immediately after sampling on each loop tick.
