from bottle import Bottle, run, response, static_file, template
import paho.mqtt.client as mqtt
import json
import os
import logging
from dotenv import load_dotenv

load_dotenv()

logging.basicConfig(
    level=logging.INFO, format="%(asctime)s - %(levelname)s - %(message)s"
)

app = Bottle()

mqtt_broker_ip = os.getenv("MQTT_BROKER_IP")
mqtt_broker_port = int(os.getenv("MQTT_BROKER_PORT"))
service_port = int(os.getenv("SERVICE_PORT"))

logging.debug(f"MQTT broker IP: {mqtt_broker_ip}, Port: {mqtt_broker_port}")
logging.debug(f"Service running on port: {service_port}")

temperature_data = {"ambient_temp": None, "grid": [None] * 24}


def on_message(client, userdata, msg):
    """Callback function for MQTT messages."""
    topic = msg.topic
    payload = msg.payload.decode("utf-8")

    logging.debug(f"Received message on topic: {topic}, payload: {payload}")

    if topic == "ice_detector/ambient_temp":
        temperature_data["ambient_temp"] = float(payload)
        logging.debug(
            f"Updated ambient temperature: {temperature_data['ambient_temp']}"
        )
    elif topic.startswith("ice_detector/temperature_grid/row"):
        row_index = int(topic.split("/")[-1].replace("row", ""))
        temperature_data["grid"][row_index] = payload.split(",")
        logging.debug(
            f"Updated temperature grid row {row_index}: {temperature_data['grid'][row_index]}"
        )


mqtt_client = mqtt.Client(mqtt.CallbackAPIVersion.VERSION2)
mqtt_client.on_message = on_message

logging.debug("Connecting to MQTT broker...")
mqtt_client.connect(mqtt_broker_ip, mqtt_broker_port, 60)
mqtt_client.subscribe("ice_detector/ambient_temp")
mqtt_client.subscribe("ice_detector/temperature_grid/#")
mqtt_client.loop_start()
logging.debug("MQTT client connected and started listening.")


@app.route("/")
def index():
    logging.debug("Serving Temperature Monitoring Dashboard.")
    return template("index")


@app.route("/temperature", method="GET")
def get_temperature_data():
    logging.debug("Temperature data requested.")
    response.content_type = "application/json"
    return json.dumps(temperature_data)


if __name__ == "__main__":
    logging.info("Starting Bottle web server...")
    run(app, host="0.0.0.0", port=service_port)
