/** 
 * LCD print 
 * by BARRAGAN <http://barraganstudio.com> 
 * 
 * Demonstrates the use of a generic text liquid crystal dsplay (LCD) 
 * to print the value of a variable 
 */

#include <LiquidCrystal.h>

// creates a LiquidDisplay object with R/S, R/W and E on pins 8,9,10 and 
// data pins on port 2
LiquidCrystal myDisplay = LiquidCrystal(8,9,10,2);

void setup()
{
  // nothing for setup
}

int a = 0;

void loop()
{
  myDisplay.clear();
  myDisplay.home();
  myDisplay.print("Variable a is: ");
  myDisplay.setCursor(16, 0);
  myDisplay.print(a);
  a = a + 1;
  delay(200);
} 

