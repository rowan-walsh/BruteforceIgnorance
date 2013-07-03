/**
 * Simple Read
 * 
 * Read data from the serial port and turn ON the onboard LED if
 * the character received is an 'a'
 */

int data;         // to read the char

void setup() {
  Serial.begin(9600);
  pinMode(48, OUTPUT);
}

void loop() {
  if(Serial.available()) {         // if data available
    data = Serial.read();          // read data
    if(data == 'a') {              // if value read is character 'a'
      digitalWrite(48, HIGH);  // turn ON the onboard LED
    } else {
      digitalWrite(48, LOW);   // if not turn it OFF
    }
  }
  delay(100);  // wait 100ms for next read
}
