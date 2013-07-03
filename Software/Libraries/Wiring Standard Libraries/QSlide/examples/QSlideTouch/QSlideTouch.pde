/**
 * Reading a QProx QT401 or QT501 touch sensor
 * by Nicholas Zambetti <http://www.zambetti.com>
 * 
 * Demostrates how to read the sensor and print to serial port
 */

#include <QSlide.h>

/* create a new QSlide instance
   pin 2: data ready   (drdy)
   pin 3: data in      (sdi)
   pin 4: slave select (ss)
   pin 5: clock        (sclk)
   pin 6: data out     (sdo)
   pin 7: detect       (detect)
   pin 8: proximity    (prox)
*/
QSlide slider = QSlide(2, 3, 4, 5, 6, 7, 8);

void setup()
{
  Serial.begin(9600);       // begin serial communication at 9600bps
}

void loop()
{
  if(slider.isTouching())   // if someone is touching the slider
  {
    int x = slider.read();  // read the slider as an integer
    Serial.print(x);        // print via serial port
  }
}

