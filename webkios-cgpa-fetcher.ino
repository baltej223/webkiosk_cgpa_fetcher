#include <ESP8266WiFi.h>
#include <ESP8266WebServer.h>
#include <WiFiClientSecure.h>
#include <ESP8266HTTPClient.h>

const char* ssid = "SSID"; 
const char* password = "PASSWORD";

ESP8266WebServer server(80);

const char* loginUrl = "https://webkiosk.thapar.edu/CommonFiles/UserAction.jsp";
const char* cgpaUrl = "https://webkiosk.thapar.edu/StudentFiles/Exam/StudCGPAReport.jsp";

String enrollment = "ENROLMENT_NUMBER";
String loginPassword = "YOUR_PASSWORD";
unsigned long interval = 60000; // 60s
unsigned long lastFetch = 0;
String cookies;
String cgpaHtml = "<h1>Fetching CGPA...</h1>";

void setup() {
  Serial.begin(115200);
  WiFi.begin(ssid, password);
  Serial.print("Connecting to WiFi");

  while (WiFi.status() != WL_CONNECTED) {
    delay(1000);
    Serial.print(".");
  }
  Serial.println("\nWiFi connected");
  Serial.print("ESP IP address: ");
  Serial.println(WiFi.localIP());

  server.on("/", []() {
    server.send(200, "text/html", cgpaHtml);
  });

  server.begin();
  Serial.println("Server started");

  loginAndFetch();
}

void loop() {
  server.handleClient();
  unsigned long now = millis();
  if (now - lastFetch > interval) {
    loginAndFetch();
    lastFetch = now;
  }
}

void loginAndFetch() {
  if (loginToWebkiosk()) {
    fetchCGPA();
  } else {
    Serial.println("[!] Login failed.");
    cgpaHtml = "<h1>Login failed</h1>";
  }
}

bool loginToWebkiosk() {
  WiFiClientSecure client;
  client.setInsecure();

  Serial.println("[*] Logging in manually...");

  if (!client.connect("webkiosk.thapar.edu", 443)) {
    Serial.println("[!] Connection failed");
    return false;
  }

  String postData =
    "txtuType=S&UserType=S"
    "&txtCode=" + enrollment + "&MemberCode=" + enrollment +
    "&txtPin=Password%2FPin&Password=" + loginPassword +
    "&BTNSubmit=Submit";

  String request =
    "POST /CommonFiles/UserAction.jsp HTTP/1.1\r\n"
    "Host: webkiosk.thapar.edu\r\n"
    "User-Agent: Mozilla/5.0\r\n"
    "Content-Type: application/x-www-form-urlencoded\r\n"
    "Content-Length: " + String(postData.length()) + "\r\n"
    "Connection: close\r\n\r\n" +
    postData;

  client.print(request);
  delay(100);

  String response;
  while (client.connected() || client.available()) {
    response += client.readStringUntil('\n');
  }

  Serial.println("[DEBUG] Raw login response:");
  Serial.println(response.substring(0, 800)); // To avoid flooding serial

  // Extract JSESSIONID from Set-Cookie
  int jsIndex = response.indexOf("Set-Cookie: JSESSIONID=");
  if (jsIndex >= 0) {
    int end = response.indexOf(";", jsIndex);
    cookies = response.substring(jsIndex + 12, end);
    cookies.trim();
    Serial.println("[+] Extracted Cookie: " + cookies);
    return true;
  } else {
    Serial.println("[!] Cookie not found");
    return false;
  }
}


void fetchCGPA() {
  HTTPClient https;
  WiFiClientSecure client;
  client.setInsecure();

  Serial.println("[*] Fetching CGPA...");

  if (https.begin(client, cgpaUrl)) {
    if (cookies.length() > 0) {
      int start = cookies.indexOf("JSESSIONID=");
      int end = cookies.indexOf(";", start);
      String jsessionid = cookies.substring(start, end);
      https.addHeader("Cookie", jsessionid);
      Serial.println("[*] Using cookie: " + jsessionid);
    }

    int httpCode = https.GET();
    if (httpCode == 200) {
      String payload = https.getString();
      if (payload.indexOf("session timeout") > 0 || payload.indexOf("not authorized") > 0) {
        Serial.println("[!] Session expired");
        cgpaHtml = "<h1>Session expired. Will retry...</h1>";
      } else {
        cgpaHtml = payload;
        Serial.println("[+] CGPA page fetched.");
      }
    } else {
      Serial.println("[!] Error fetching CGPA: " + String(httpCode));
      cgpaHtml = "<h1>Error fetching CGPA</h1>";
    }

    https.end();
  }
}
