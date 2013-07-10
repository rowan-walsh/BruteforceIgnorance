#include <phys253.h>
#include <LiquidCrystal.h>
#include <Servo253.h>
#include <LaserSensor.h>
#include <QrdSensor.h>
#include <MenuItem.h>
#include <EEPROM.h>

// EEPROM addresses
#define LASER_THRESHOLD 0
#define P_GAIN 1
#define D_GAIN 2
#define BRUSH_SPEED 3
#define FIRING_SPEED 4
#define MOTOR_SPEED 5
#define SERVO_ANGLE 6

// Knobs
#define MENU_ADJUST_KNOB 6
#define VALUE_ADJUST_KNOB 7

// Menu items
#include "WProgram.h"
#include <HardwareSerial.h>
void setup();
void loop();
void Update();
void ProcessMenu();
MenuItem laserThreshold = MenuItem("Laser TH", LASER_THRESHOLD);
MenuItem pGain = MenuItem("P-Gain", P_GAIN);
MenuItem dGain = MenuItem("D-Gain", D_GAIN);
MenuItem brushSpeed = MenuItem("Brush Vel", BRUSH_SPEED);
MenuItem firingSpeed = MenuItem("Fire Vel", FIRING_SPEED);
MenuItem motorSpeed = MenuItem("Motor Vel", MOTOR_SPEED);
MenuItem servoAngle = MenuItem("Servo Angle", SERVO_ANGLE);
MenuItem items[] = {laserThreshold, pGain, dGain, brushSpeed, firingSpeed, motorSpeed, servoAngle};
int itemCount = 7;

// State tracking
bool MENU = true;
int lcdRefreshPeriod = 200; // Update LCD screen every n iterations. Larger = fewer updates. Smaller = flicker
int lcdRefreshCount = 0; // Current iteration. Do not change this value

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
	Update();
	if (MENU) ProcessMenu();

}

// Determines if the start button is being pressed.
// Optional: Debounces the button for the specified number of milliseconds
bool StartButton(int debounceTime = 80)
{
	if(!startbutton()) return false;
	delay(debounceTime);
	return startbutton();
}

// Determines if the stop button is being pressed
// Optional: Debounces the button for the specified number of milliseconds
bool StopButton(int debounceTime = 80)
{
	if(!stopbutton()) return false;
	delay(debounceTime);
	return stopbutton();
}

void Update()
{
	// Detects button presses and decrements the LCD counter
	if(StopButton()) MENU = true;
	if(StartButton()) MENU = false;
	lcdRefreshCount = (lcdRefreshCount <= 0) ? lcdRefreshPeriod : (lcdRefreshCount - 1);
}

void ProcessMenu()
{
	motor.stop_all();
	int knobValue = knob(VALUE_ADJUST_KNOB);
	int selectedItem = knob(MENU_ADJUST_KNOB) / (1024 / itemCount - 1);
	if (selectedItem > itemCount - 1) selectedItem = itemCount - 1;

	LCD.home();
	LCD.clear();
	LCD.print(items[selectedItem].Name() + " "); LCD.print(items[selectedItem].Value());
	LCD.setCursor(0,1);
	LCD.print("Set to "); LCD.print(knobValue); LCD.print("?");
	
	if(StopButton(200)) items[selectedItem].SetValue(knobValue);
	delay(30);
}

