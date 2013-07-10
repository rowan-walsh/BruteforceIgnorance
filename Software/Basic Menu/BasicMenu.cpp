#include <phys253.h>
#include <LiquidCrystal.h>
#include <Servo253.h>
#include <LaserSensor.h>
#include <QrdSensor.h>
#include <MenuItem.h>
#include <EEPROM.h>

#define LASER_THRESHOLD 0
#define P_GAIN 1
#define D_GAIN 2
#define BRUSH_SPEED 3
#define FIRING_SPEED 4
#define MOTOR_SPEED 5
#define SERVO_ANGLE 6

LaserSensor laser;
QrdSensor qrd;

MenuItem laserThreshold = MenuItem("Laser TH", LASER_THRESHOLD);
MenuItem pGain = MenuItem("P-Gain", P_GAIN);
MenuItem dGain = MenuItem("D-Gain", D_GAIN);
MenuItem brushSpeed = MenuItem("Brush Vel", BRUSH_SPEED);
MenuItem firingSpeed = MenuItem("Fire Vel", FIRING_SPEED);
MenuItem motorSpeed = MenuItem("Motor Vel", MOTOR_SPEED);
MenuItem servoAngle = MenuItem("Servo Angle", SERVO_ANGLE);

void setup()
{
	portMode(0, INPUT);       
	portMode(1, INPUT); 
	RCServo0.attach(RCServo0Output);
	RCServo1.attach(RCServo1Output);
	RCServo2.attach(RCServo2Output);

	


	//item.SetName("Gain");
	//item.SetAddress(1);
	//item.SetValue(10);

	laser.Attach(0, 500);
	qrd.Attach(0);
}

void loop()
{
	delay(50);
	LCD.home();
	LCD.clear();
	
	//// Laser state
	//LCD.print("Val ");
	//LCD.print(laser.Value());
	//LCD.print(" ");
	//LCD.print(laser.AboveThreshold());

	//// QRD states
	//LCD.setCursor(0,1);
	//LCD.print("Tape ");
	//LCD.print(qrd.TapeDetected());



}