#include <phys253.h>      
#include <LiquidCrystal.h>
#include <Servo253.h> 
#include <EEPROM.h>

#define LEFT_SIDE 14
#define LEFT_FRONT 13
#define RIGHT_SIDE 12
#define RIGHT_FRONT 11
#define LEFT_LASER 0
#define RIGHT_LASER 1

void setup()
{
	portMode(0, INPUT);
	portMode(1, INPUT);
	RCServo0.attach(RCServo0Output);
	RCServo1.attach(RCServo1Output);
	RCServo2.attach(RCServo2Output);
}

void loop()
{
	LCD.clear(); 
	LCD.home();
	Print("F", digitalRead(LEFT_FRONT));
	Print("S", digitalRead(LEFT_SIDE));
	Print(" F", digitalRead(RIGHT_FRONT));
	Print("S", digitalRead(RIGHT_SIDE));
	LCD.setCursor(0,1);
	Print("L1: ", analogRead(LEFT_LASER));
	Print("L2: ", analogRead(RIGHT_LASER));
	delay(50);
}

void Print(String text, int value)
{
	LCD.print(text);
	LCD.print(value);
}