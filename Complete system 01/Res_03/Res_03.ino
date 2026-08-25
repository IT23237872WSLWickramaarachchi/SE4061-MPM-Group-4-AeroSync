#include <WiFi.h>
#include <esp_now.h>

#define RELAY1_PIN 18 // Low/Medium threshold relay
#define RELAY2_PIN 19 // High threshold relay

// Active-LOW relay logic definitions
#define RELAY_ON  LOW
#define RELAY_OFF HIGH

typedef struct struct_message {
  int val; // Volume level (0 - 100)
} struct_message;

struct_message myData;

void OnDataRecv(const esp_now_recv_info_t *info, const uint8_t *incomingData, int len) {
  memcpy(&myData, incomingData, sizeof(myData));
  
  int volume = constrain(myData.val, 0, 100);
  Serial.printf("Volume Received: %d%%\n", volume);

  if (volume < 20) {
    // Below 20%: Channel 1 OFF, Channel 2 OFF
    digitalWrite(RELAY1_PIN, RELAY_OFF);
    digitalWrite(RELAY2_PIN, RELAY_OFF);
    Serial.println("Relays: [CH1: OFF | CH2: OFF]");

  } else if (volume >= 20 && volume <= 70) {
    // 20% - 70%: Channel 1 ON, Channel 2 OFF
    digitalWrite(RELAY1_PIN, RELAY_ON);
    digitalWrite(RELAY2_PIN, RELAY_OFF);
    Serial.println("Relays: [CH1: ON  | CH2: OFF]");

  } else {
    // Above 70%: Channel 1 OFF, Channel 2 ON
    digitalWrite(RELAY1_PIN, RELAY_OFF);
    digitalWrite(RELAY2_PIN, RELAY_ON);
    Serial.println("Relays: [CH1: OFF | CH2: ON ]");
  }
}

void setup() {
  Serial.begin(115200);

  pinMode(RELAY1_PIN, OUTPUT);
  pinMode(RELAY2_PIN, OUTPUT);

  // Turn both relays OFF on startup
  digitalWrite(RELAY1_PIN, RELAY_OFF);
  digitalWrite(RELAY2_PIN, RELAY_OFF);

  WiFi.mode(WIFI_STA);
  delay(100);

  if (esp_now_init() != ESP_OK) {
    Serial.println("ESP-NOW Init Failed");
    return;
  }

  esp_now_register_recv_cb(OnDataRecv);
  Serial.println("Volume Receiver Ready.");
}

void loop() {
  // Handled asynchronously in callback
}