# include "BluetoothSerial.h"

BluetoothSerial SerialBT;
int ledPin = 2;
int pin1 = 26; // Lo-
int pin2 = 27; // Lo+
int flag = 0;

void setup() {
  Serial.begin(9600);
  SerialBT.begin("ECG Monitor");
  pinMode(ledPin, OUTPUT);
  pinMode(pin1, INPUT);
  pinMode(pin2, INPUT);
}


void loop() {
  if (SerialBT.available()) { 
    char receivedData = SerialBT.read();
    Serial.println(receivedData);
    if (receivedData == '1') {
      flag = 1;
    } else if(receivedData == '0') {
      flag = 0;
    }
  }
  if (flag == 1) {
    digitalWrite(ledPin, HIGH);
    if ((digitalRead(pin2) == 1) || (digitalRead(pin1) == 1)){
      digitalWrite(ledPin, LOW);
    }
    else {
      digitalWrite(ledPin, HIGH);
      int analogValue = analogRead(A0);
      Serial.println(analogValue);
      String analogValueStr = String(analogValue);
      SerialBT.println(analogValueStr); 
      delay(10);
    }
  } else {
    digitalWrite(ledPin, LOW);
  }
}
