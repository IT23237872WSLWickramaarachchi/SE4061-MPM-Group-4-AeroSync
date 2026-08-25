#include <WiFi.h>
#include <esp_now.h>

// --- RECEIVER MAC ADDRESSES ---
uint8_t mac_rx1[] = {0x68, 0x09, 0x47, 0x44, 0x56, 0x90}; // Receiver 01 (Volume / Fan 1)
uint8_t mac_rx2[] = {0x68, 0x09, 0x47, 0x52, 0x41, 0xF0}; // Receiver 02 (Brightness / Fan 2)
uint8_t mac_rx3[] = {0x68, 0x09, 0x47, 0x5E, 0xD9, 0xF4}; // Receiver 03 (Volume / Fan 3)

// Payload Data Structure
typedef struct struct_message {
  int val; // Percentage (0 - 100) or level value
} struct_message;

struct_message data_rx1;
struct_message data_rx2;
struct_message data_rx3;

esp_now_peer_info_t peerInfo;

// Packet delivery send callback
void OnDataSent(const wifi_tx_info_t *info, esp_now_send_status_t status) {
  // Packet delivery callback
}

// Callback when ESP-NOW data is received from paired receiver nodes (telemetry/current sensor data)
void OnDataRecv(const esp_now_recv_info_t *info, const uint8_t *incomingData, int len) {
  struct_message incoming;
  if (len == sizeof(incoming)) {
    memcpy(&incoming, incomingData, sizeof(incoming));
    char macStr[18];
    snprintf(macStr, sizeof(macStr), "%02X:%02X:%02X:%02X:%02X:%02X",
             info->src_addr[0], info->src_addr[1], info->src_addr[2],
             info->src_addr[3], info->src_addr[4], info->src_addr[5]);
    Serial.printf("TELEMETRY_RX [%s] -> Val: %d\n", macStr, incoming.val);
  }
}

// Helper to parse key-value serial inputs (e.g., "V:50,B:80", "F1:1,F2:2,F3:0", "C:75", "C1:30,C2:60,C3:90")
void parseAndDispatch(String input) {
  input.trim();
  if (input.length() == 0) return;

  bool hasRx1 = false, hasRx2 = false, hasRx3 = false;
  int valRx1 = data_rx1.val;
  int valRx2 = data_rx2.val;
  int valRx3 = data_rx3.val;

  int startIdx = 0;
  while (startIdx < input.length()) {
    int commaIdx = input.indexOf(',', startIdx);
    if (commaIdx == -1) commaIdx = input.length();

    String pair = input.substring(startIdx, commaIdx);
    pair.trim();

    int colonIdx = pair.indexOf(':');
    if (colonIdx != -1) {
      String key = pair.substring(0, colonIdx);
      String valStr = pair.substring(colonIdx + 1);
      key.trim();
      key.toUpperCase();
      valStr.trim();
      int rawVal = valStr.toInt();

      if (key == "F1" || key == "C1") {
        // Fan 1 or Current Channel 1
        valRx1 = (key == "F1" && rawVal <= 2) ? (rawVal == 1 ? 50 : (rawVal == 2 ? 100 : 0)) : rawVal;
        hasRx1 = true;
      } else if (key == "F2" || key == "C2" || key == "B") {
        // Fan 2, Brightness, or Current Channel 2
        valRx2 = (key == "F2" && rawVal <= 2) ? (rawVal == 1 ? 50 : (rawVal == 2 ? 100 : 0)) : rawVal;
        hasRx2 = true;
      } else if (key == "F3" || key == "C3") {
        // Fan 3 or Current Channel 3
        valRx3 = (key == "F3" && rawVal <= 2) ? (rawVal == 1 ? 50 : (rawVal == 2 ? 100 : 0)) : rawVal;
        hasRx3 = true;
      } else if (key == "V") {
        // Volume -> Fan 1 & Fan 3
        valRx1 = rawVal;
        valRx3 = rawVal;
        hasRx1 = true;
        hasRx3 = true;
      } else if (key == "C" || key == "CURRENT" || key == "VAL") {
        // Global current / value -> All channels
        valRx1 = rawVal;
        valRx2 = rawVal;
        valRx3 = rawVal;
        hasRx1 = true;
        hasRx2 = true;
        hasRx3 = true;
      }
    }
    startIdx = commaIdx + 1;
  }

  // Transmit payloads to paired receivers
  if (hasRx1) {
    data_rx1.val = valRx1;
    esp_now_send(mac_rx1, (uint8_t *)&data_rx1, sizeof(data_rx1));
  }
  if (hasRx2) {
    data_rx2.val = valRx2;
    esp_now_send(mac_rx2, (uint8_t *)&data_rx2, sizeof(data_rx2));
  }
  if (hasRx3) {
    data_rx3.val = valRx3;
    esp_now_send(mac_rx3, (uint8_t *)&data_rx3, sizeof(data_rx3));
  }

  Serial.printf("Dispatched -> Rx1: %d | Rx2: %d | Rx3: %d\n", data_rx1.val, data_rx2.val, data_rx3.val);
}

void setup() {
  Serial.begin(115200);
  Serial.setTimeout(50);

  WiFi.mode(WIFI_STA);
  delay(100);

  if (esp_now_init() != ESP_OK) {
    Serial.println("Error initializing ESP-NOW");
    return;
  }

  esp_now_register_send_cb(OnDataSent);
  esp_now_register_recv_cb(OnDataRecv);

  // Register Receiver 01
  memcpy(peerInfo.peer_addr, mac_rx1, 6);
  peerInfo.channel = 0;
  peerInfo.encrypt = false;
  esp_now_add_peer(&peerInfo);

  // Register Receiver 02
  memcpy(peerInfo.peer_addr, mac_rx2, 6);
  esp_now_add_peer(&peerInfo);

  // Register Receiver 03
  memcpy(peerInfo.peer_addr, mac_rx3, 6);
  esp_now_add_peer(&peerInfo);

  Serial.println("Transmitter Ready. Listening for serial commands...");
}

void loop() {
  if (Serial.available() > 0) {
    String input = Serial.readStringUntil('\n');
    parseAndDispatch(input);
  }
}