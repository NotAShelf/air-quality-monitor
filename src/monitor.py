import json
import os
import time
import datetime
import serial
import redis
import aqi


REDIS_HOST = os.environ.get("REDIS_HOST", "localhost")
REDIS_PORT = int(os.environ.get("REDIS_PORT", 6379))
REDIS_DB = int(os.environ.get("REDIS_DB", 0))
redis_client = redis.StrictRedis(host=REDIS_HOST, port=REDIS_PORT, db=REDIS_DB)


class AirQualityMonitor:
    SERIAL_DEVICE = os.environ.get("SERIAL_DEVICE", "/dev/ttyUSB0")

    def __init__(self):
        self.ser = serial.Serial(self.SERIAL_DEVICE)

    def get_measurement(self):
        """Fetches a measurement from the sensor and returns it."""
        data = [self.ser.read() for _ in range(10)]
        pmtwo = int.from_bytes(b"".join(data[2:4]), byteorder="little") / 10
        pmten = int.from_bytes(b"".join(data[4:6]), byteorder="little") / 10
        aqi_value = aqi.to_aqi(
            [
                (aqi.POLLUTANT_PM25, str(pmtwo)),
                (aqi.POLLUTANT_PM10, str(pmten)),
            ]
        )

        measurement = {
            "timestamp": datetime.datetime.now(),
            "pm2.5": pmtwo,
            "pm10": pmten,
            "aqi": float(aqi_value),
        }
        return {"time": int(time.time()), "measurement": measurement}

    def save_measurement_to_redis(self):
        """Saves measurement to redis db"""
        redis_client.lpush(
            "measurements", json.dumps(self.get_measurement(), default=str)
        )

    def get_last_n_measurements(self):
        """Returns the last n measurements in the list"""
        return [json.loads(x) for x in redis_client.lrange("measurements", 0, -1)]
