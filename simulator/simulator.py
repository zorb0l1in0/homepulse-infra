"""
HomePulse Sensor Simulator
Publishes fake sensor data to MQTT for two properties: Torino and Tenerife.
"""

import json
import time
import random
import argparse
from datetime import datetime

import paho.mqtt.client as mqtt

PROPERTIES = {
    "torino": {
        "name": "Torino",
        "temp_range": (-2, 35),
        "humidity_range": (30, 85),
        "rooms": ["soggiorno", "camera", "bagno", "cucina"],
    },
    "tenerife": {
        "name": "Tenerife",
        "temp_range": (15, 32),
        "humidity_range": (50, 90),
        "rooms": ["salon", "dormitorio", "bano", "cocina"],
    },
}

SEASONAL_OFFSET = {
    "torino":   [-5, -3, 0, 5, 10, 15, 18, 17, 12, 6, 1, -3],
    "tenerife": [-2, -1, 0, 1,  3,  5,  7,  7,  5, 3, 1, -1],
}


class SensorSimulator:
    def __init__(self, broker_host, broker_port=1883):
        self.client = mqtt.Client(client_id="homepulse-simulator")
        self.broker_host = broker_host
        self.broker_port = broker_port
        self.last_temp = {}
        self.last_humidity = {}

    def connect(self):
        print(f"Connecting to MQTT broker at {self.broker_host}:{self.broker_port}")
        self.client.connect(self.broker_host, self.broker_port, keepalive=60)
        self.client.loop_start()
        print("Connected.")

    def disconnect(self):
        self.client.loop_stop()
        self.client.disconnect()
        print("Disconnected from MQTT broker.")

    def _drift(self, last_value, min_val, max_val, max_step=0.5):
        delta = random.uniform(-max_step, max_step)
        new_value = last_value + delta
        return round(max(min_val, min(max_val, new_value)), 1)

    def _get_base_temp(self, property_id):
        month = datetime.now().month - 1
        prop = PROPERTIES[property_id]
        mid = sum(prop["temp_range"]) / 2
        return mid + SEASONAL_OFFSET[property_id][month]

    def generate_reading(self, property_id, room):
        prop = PROPERTIES[property_id]
        key = f"{property_id}/{room}"

        if key not in self.last_temp:
            self.last_temp[key] = self._get_base_temp(property_id)
        self.last_temp[key] = self._drift(
            self.last_temp[key], prop["temp_range"][0], prop["temp_range"][1],
        )

        if key not in self.last_humidity:
            self.last_humidity[key] = sum(prop["humidity_range"]) / 2
        self.last_humidity[key] = self._drift(
            self.last_humidity[key], prop["humidity_range"][0], prop["humidity_range"][1], max_step=1.0,
        )

        return {
            "property": property_id,
            "room": room,
            "temperature": self.last_temp[key],
            "humidity": self.last_humidity[key],
            "door_open": random.random() < 0.05,
            "window_open": random.random() < 0.10,
            "timestamp": datetime.utcnow().isoformat(),
        }

    def publish_all(self):
        for property_id, prop in PROPERTIES.items():
            for room in prop["rooms"]:
                reading = self.generate_reading(property_id, room)
                topic = f"homepulse/{property_id}/{room}"
                payload = json.dumps(reading)
                self.client.publish(topic, payload, qos=1)
                print(f"  {topic}: {reading['temperature']}C  {reading['humidity']}%")

    def run(self, interval=10):
        self.connect()
        try:
            while True:
                now = datetime.now().strftime("%H:%M:%S")
                print(f"\n[{now}] Publishing sensor data...")
                self.publish_all()
                time.sleep(interval)
        except KeyboardInterrupt:
            print("\nStopping simulator...")
        finally:
            self.disconnect()


def main():
    parser = argparse.ArgumentParser(description="HomePulse Sensor Simulator")
    parser.add_argument("--host", default="localhost", help="MQTT broker host")
    parser.add_argument("--port", type=int, default=1883, help="MQTT broker port")
    parser.add_argument("--interval", type=int, default=10, help="Seconds between readings")
    args = parser.parse_args()

    simulator = SensorSimulator(args.host, args.port)
    simulator.run(args.interval)


if __name__ == "__main__":
    main()
