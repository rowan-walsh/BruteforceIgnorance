/**
 * Encoder read 
 * by BARRAGAN <http://barraganstudio.com> 
 * 
 * Demonstrates the use of an encoder with the Encoder library 
 * Prints the encoder value 
 */

#include <Encoder.h> 
 
int val; 
Encoder myEncoder; 
 
void setup() { 
  myEncoder.attach(2, 8);  // ataches the encoder to pins 2 and 8
  myEncoder.write(0);      // set the encoder position to 0
  Serial.begin(9600);
} 
 
void loop() { 
  // Reads the position or angle of the encoder variable 
  val = myEncoder.read();  // read position
  Serial.print("Encoder is at: ");  // print the position
  Serial.println(val);
  delay(100);  // wait 100ms for next reading
} 
