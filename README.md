# Ice Detection System using MLX90640

This project implements an ice detection system using the **MLX90640 thermal sensor** and **ESP32 microcontroller**. The system communicates via MQTT and exposes data through an HTTP service, designed for integration in a robotic environment to ensure proper ice dispensing.

## Architecture

```mermaid
graph TD
    subgraph Process Engine
        Process -->|HTTP GET /temperature| Data_Service        
    end

    subgraph Ice Detector Device
        MLX90640 -->|I2C| ESP32
    end
    ESP32 -->|MQTT Publish| MQTT_Broker

    subgraph Lab Machine
        Data_Service -->|MQTT Subscribe| MQTT_Broker
    end

    subgraph lehre.bpm.in.tum.de
        Process -->|HTTP POST /predict| Prediction_Service
    end
```
