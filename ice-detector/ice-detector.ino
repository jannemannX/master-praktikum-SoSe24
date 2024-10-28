#include <WiFi.h>
#include <PubSubClient.h>
#include <Adafruit_MLX90640.h>

const char *ssid = "YOUR_WIFI_SSID";
const char *password = "YOUR_WIFI_PASSWORD";
const char *mqtt_server = "YOUR_MQTT_SERVER_IP";

WiFiClient espClient;
PubSubClient client(espClient);

Adafruit_MLX90640 mlx;
float frame[32 * 24];              // temperature frame buffer
unsigned long lastPublishTime = 0; // track the last publish time

void setup_wifi()
{
  delay(10);
  WiFi.begin(ssid, password);
  while (WiFi.status() != WL_CONNECTED)
  {
    delay(500);
  }
  Serial.println("WiFi connected, IP address: ");
  Serial.println(WiFi.localIP());
}

// reconnect to mqtt
void reconnect()
{
  while (!client.connected())
  {
    if (client.connect("esp32_client"))
    {
      Serial.println("mqtt connected");
    }
    else
    {
      delay(5000);
    }
  }
}

void setup()
{
  Serial.begin(115200);
  setup_wifi();
  client.setServer(mqtt_server, 1883);

  if (!mlx.begin(MLX90640_I2CADDR_DEFAULT, &Wire))
  {
    Serial.println("MLX90640 not found!");
    while (1)
      ;
  }
  mlx.setResolution(MLX90640_ADC_19BIT); // 19 bit is highest rate, lower rates might be sufficient, if power becomes a concern or i2c gets unstable
  mlx.setRefreshRate(MLX90640_4_HZ);     // at higher rates I2C might become unstable
  mlx.setMode(MLX90640_CHESS);           // chess = on every reading half the pixels are sampled, odd and even, thats why we use 4hz and publish results every 500ms.
}

void loop()
{
  if (!client.connected())
  {
    reconnect();
  }
  client.loop();

  if (millis() - lastPublishTime >= 500)
  {
    lastPublishTime = millis(); // update the last publish time

    if (mlx.getFrame(frame) != 0)
    {
      Serial.println("Failed to read frame data from MLX90640.");
      return;
    }

    float ambientTemp = mlx.getTa(false) - 8.0; // get ambient temperature, offset by -8.0°C if in free air
    String payload = String(ambientTemp, 2);

    // publish ambient temperature
    if (client.publish("ice_detector/ambient_temp", payload.c_str()))
    {
      // Serial.println("Ambient temperature published successfully");
    }
    else
    {
      Serial.println("Failed to publish ambient temperature");
    }

    // publish each row of the temperature grid
    for (uint8_t y = 0; y < 24; y++)
    {
      String rowPayload = "";
      for (uint8_t x = 0; x < 32; x++)
      {
        rowPayload += String(frame[y * 32 + x], 2);
        if (x < 31)
          rowPayload += ",";
      }

      String topic = "ice_detector/temperature_grid/row" + String(y);

      if (client.publish(topic.c_str(), rowPayload.c_str()))
      {
        // Serial.print("Row ");
        // Serial.print(y);
        // Serial.println(" published successfully.");
      }
      else
      {
        Serial.print("Failed to publish row ");
        Serial.println(y);
      }
    }
  }
}