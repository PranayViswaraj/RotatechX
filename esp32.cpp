#include <WiFi.h>
#include <HTTPClient.h>

// Replace with your WiFi credentials
const char* ssid = "vivoY01";
const char* password = "sundueli";

// WiFi client instance
WiFiClient client;

void setup() {
  Serial.begin(9600);  // Communication with Arduino Uno

  // Start WiFi connection
  WiFi.begin(ssid, password);
  Serial.print("Connecting to WiFi");

  // Wait for connection
  while (WiFi.status() != WL_CONNECTED) {
    delay(500);
    Serial.print(".");
  }

  Serial.println("\nConnected to WiFi!");
}

void loop() {
  // Check if data is available on Serial (from Arduino)
  if (Serial.available()) {
    String sensorLine = Serial.readStringUntil('\n');
    sensorLine.trim();  // Remove leading/trailing whitespaces

    Serial.println("Received: " + sensorLine);

    // Variables to hold parsed sensor values
    float temperature;
    int heartRate, spo2, steps, bpSystolic, bpDiastolic;
    String ecgStatus;

    // Find commas to split values
    int firstComma = sensorLine.indexOf(',');
    int secondComma = sensorLine.indexOf(',', firstComma + 1);
    int thirdComma = sensorLine.indexOf(',', secondComma + 1);
    int fourthComma = sensorLine.indexOf(',', thirdComma + 1);
    int fifthComma = sensorLine.indexOf(',', fourthComma + 1);
    int sixthComma = sensorLine.indexOf(',', fifthComma + 1);

    // Ensure the expected number of fields are present
    if (firstComma > 0 && sixthComma > 0) {
      // Parse the values
      temperature = sensorLine.substring(0, firstComma).toFloat();
      heartRate = sensorLine.substring(firstComma + 1, secondComma).toInt();
      spo2 = sensorLine.substring(secondComma + 1, thirdComma).toInt();
      ecgStatus = sensorLine.substring(thirdComma + 1, fourthComma);
      steps = sensorLine.substring(fourthComma + 1, fifthComma).toInt();
      bpSystolic = sensorLine.substring(fifthComma + 1, sixthComma).toInt();
      bpDiastolic = sensorLine.substring(sixthComma + 1).toInt();

      // If WiFi is still connected
      if (WiFi.status() == WL_CONNECTED) {
        HTTPClient http;
        http.begin(client, "http://192.168.255.84:3000/data");  // Change to your Flask server IP

        http.addHeader("Content-Type", "application/json");

        // Create JSON string to send
        String jsonData = "{";
        jsonData += "\"temperature\":" + String(temperature, 1) + ",";
        jsonData += "\"heartRate\":" + String(heartRate) + ",";
        jsonData += "\"spo2\":" + String(spo2) + ",";
        jsonData += "\"ecgStatus\":\"" + ecgStatus + "\",";
        jsonData += "\"steps\":" + String(steps) + ",";
        jsonData += "\"bpSystolic\":" + String(bpSystolic) + ",";
        jsonData += "\"bpDiastolic\":" + String(bpDiastolic);
        jsonData += "}";

        Serial.println("Sending to server: " + jsonData);

        // Send the POST request
        int httpResponseCode = http.POST(jsonData);

        Serial.print("HTTP Response code: ");
        Serial.println(httpResponseCode);

        http.end();
      } else {
        Serial.println("WiFi not connected");
      }
    } else {
      Serial.println("Invalid data format received");
    }
  }
}