#include <HardwareTimer2.h>


int ledPin = 48;  // onboard LED on the Wiring I/O board (pin 48) 
byte value = HIGH; 

void setup()
{
  pinMode(ledPin, OUTPUT);  // sets the digital pin as output
  
  // sets Timer2 to execute function ledFlash() every 500ms
  Timer2.set(100, ledFlash);  
  
  // sets Timer2 to execute function ledFlash() using timer prescaler 1024
  // F_CPU / 1024 in a 16Mhz will be 15625 
  // 15625 / 255 = 61.27 overflows (full countings to 255)
  // 1000ms / 61.27 = 16.32ms, so function ledFlash() will be executed every 16.32ms
    
  //Timer2.set(ledFlash, CLOCK_DIV1024);
    
  // start timer
  Timer2.start();
}

void loop()
{
}

void ledFlash() {
  digitalWrite(ledPin, value);
  if(value == HIGH) 
    value = LOW;
  else
    value = HIGH; 
}

