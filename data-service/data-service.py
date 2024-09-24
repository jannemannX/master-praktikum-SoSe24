from bottle import Bottle, run, response, static_file, template
import paho.mqtt.client as mqtt
import json
import os
from dotenv import load_dotenv

load_dotenv()

app = Bottle()

mqtt_broker_ip = os.getenv("MQTT_BROKER_IP")
mqtt_broker_port = int(os.getenv("MQTT_BROKER_PORT"))
service_port = int(os.getenv("SERVICE_PORT"))

temperature_data = {"ambient_temp": None, "grid": [None] * 24}


def on_message(client, userdata, msg):
    topic = msg.topic
    payload = msg.payload.decode('utf-8')

    if topic == "ice_detector/ambient_temp":
        temperature_data["ambient_temp"] = float(payload)
    elif topic.startswith("ice_detector/temperature_grid/row"):
        row_index = int(topic.split('/')[-1].replace('row', ''))
        temperature_data["grid"][row_index] = payload.split(',')


mqtt_client = mqtt.Client()
mqtt_client.on_message = on_message
mqtt_client.connect(mqtt_broker_ip, mqtt_broker_port, 60)
mqtt_client.subscribe("ice_detector/ambient_temp")
mqtt_client.subscribe("ice_detector/temperature_grid/#")
mqtt_client.loop_start()


@app.route('/')
def index():
    return template('index')


@app.route('/temperature', method='GET')
def get_temperature_data():
    response.content_type = 'application/json'
    return json.dumps(temperature_data)


if __name__ == '__main__':
    run(app, host='0.0.0.0', port=service_port)
