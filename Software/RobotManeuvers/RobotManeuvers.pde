#include <phys253.h>
#include <LiquidCrystal.h>
#include <Servo253.h>
#include <LaserSensor.h>
#include <QrdSensor.h>
#include <MenuItem.h>
#include <EEPROM.h>

// EEPROM ADDRESSES
// Light sensors
#define LASER_THRESHOLD 0
#define TARGET_THRESHOLD 1
#define BALL_COLLECT_THRESHOLD 2
// Gain parameters
#define P_GAIN 3
#define D_GAIN 4
// Motor speeds
#define BRUSH_SPEED 5
#define FIRING_SPEED 6
#define MOTOR_SPEED 7
// Servo angles
#define SERVO_LOAD_ANGLE 8
#define SERVO_COLLECT_ANGLE 9
#define SERVO_STEER_ANGLE 10

// PIN DECLARATIONS
// Motors
#define LEFT_MOTOR_PIN 1
#define RIGHT_MOTOR_PIN 2
#define BRUSH_MOTOR_PIN 3
#define SHOOTING_MOTOR_PIN 4
// Analog Inputs
#define LEFT_LASER_PIN 1
#define RIGHT_LASER_PIN 2
#define COLLECT_QRD_PIN 3
#define TARGET_DETECT_PIN 4
// Digital Inputs
#define LEFT_SIDE_MICROSWITCH_PIN 14
#define LEFT_FRONT_MICROSWITCH_PIN 13
#define RIGHT_SIDE_MICROSWITCH_PIN 12
#define RIGHT_FRONT_MICROSWITCH_PIN 11
// Knobs
#define MENU_ADJUST_KNOB 6	 // adjust selected menu item
#define VALUE_ADJUST_KNOB 7	 // adjust item value

// Can't explicitly define servos
// RC Servo 0 = ball loading
// RC Servo 1 = left
// RC Servo 2 = right

// MENU ITEMS 
// Thresholds
MenuItem laserThreshold = MenuItem("Laser TH", LASER_THRESHOLD);
MenuItem targetThreshold = MenuItem("Target TH", TARGET_THRESHOLD);
MenuItem ballCollectThreshold = MenuItem("Collect TH", BALL_COLLECT_THRESHOLD);
// Gain parameters
MenuItem proportionalGain = MenuItem("P-Gain", P_GAIN);
MenuItem derivativeGain = MenuItem("D-Gain", D_GAIN);
// Motor speeds
MenuItem brushSpeed = MenuItem("Brush Vel", BRUSH_SPEED);
MenuItem firingSpeed = MenuItem("Fire Vel", FIRING_SPEED);
MenuItem motorSpeed = MenuItem("Motor Vel", MOTOR_SPEED);
// Servo angles
MenuItem servoLoadAngle = MenuItem("Load ang", SERVO_LOAD_ANGLE);
MenuItem servoCollectAngle = MenuItem("Col ang", SERVO_COLLECT_ANGLE);
MenuItem servoSteerAngle = MenuItem("Steer ang", SERVO_STEER_ANGLE);

// Load menu items into an array
MenuItem items[] = 
{
	laserThreshold, targetThreshold, ballCollectThreshold,
	proportionalGain, derivativeGain,
	brushSpeed, firingSpeed, motorSpeed,
	servoLoadAngle, servoCollectAngle, servoSteerAngle
};
int itemCount = 11;

// State tracking
bool MENU = true; // Changing this will load menu by default (true) or start running (false)
int lcdRefreshPeriod = 2000; // Update LCD screen every n iterations. Larger = fewer updates. Smaller = flicker
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
	else Run();
}

// Sets a specified angle to the given servo
void SetServo(int servoIndex, int servoAngle)
{
	if (servoAngle > 180) servoAngle = 180;
	if (servoAngle < 0) servoAngle = 0;
	switch (servoIndex)
	{
		case 0:
			RCServo0.write(servoAngle);
			break;
		case 1:
			RCServo1.write(servoAngle);
			break;
		case 2:
			RCServo2.write(servoAngle);
			break
		case default:
			break;
	}
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
	if(StopButton()) MENU = true;
	if(StartButton()) MENU = false;
	lcdRefreshCount = (lcdRefreshCount <= 0) ? lcdRefreshPeriod : (lcdRefreshCount - 1);
	if(lcdRefreshCount == 0)
	{ 
		LCD.clear();
		LCD.home();
		LCD.print(analogRead(0));
	}
}

// Sensors still update while the program is delayed
void SoftDelay(int milliseconds)
{
	unsigned long startTime = millis();
	while (millis() < startTime + milliseconds)
	{
		Update();
	}
}

void Run()
{

}

void ProcessMenu()
{
	motor.stop_all();
	int knobValue = knob(VALUE_ADJUST_KNOB);
	int selectedItem = knob(MENU_ADJUST_KNOB) / (1024 / itemCount - 1);
	if (selectedItem > itemCount - 1) selectedItem = itemCount - 1; // Normalize the selection

	LCD.clear(); LCD.home();
	LCD.print(items[selectedItem].Name() + " "); 
	LCD.print(items[selectedItem].Value());
	LCD.setCursor(0,1);
	LCD.print("Set to "); LCD.print(knobValue); LCD.print("?");
	
	if(StopButton(200)) items[selectedItem].SetValue(knobValue);
	delay(50);
}
