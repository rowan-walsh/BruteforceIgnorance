#include <phys253.h>
#include <LiquidCrystal.h>
#include <Servo253.h>
#include <LaserSensor.h>
#include <QrdSensor.h>
#include <MenuItem.h>
#include <EEPROM.h>

// EEPROM ADDRESSES (for the love of god, don't modify!)
// Light sensors
#define LASER_THRESHOLD 0
#define TARGET_THRESHOLD 1
#define BALL_COLLECT_THRESHOLD 2
// Laser Gain parameters
#define LASER_P_GAIN 3
#define LASER_D_GAIN 4
#define QRD_P_GAIN 5
#define QRD_D_GAIN 6
// Motor speeds
#define BRUSH_SPEED 7
#define FIRING_SPEED 8
#define MOTOR_SPEED 9
// Servo angles
#define SERVO_LOAD_ANGLE 10
#define SERVO_COLLECT_ANGLE 11
#define SERVO_STEER_ANGLE 12


// PIN DECLARATIONS
// Servo indices
#define SERVO_BALL 0
#define SERVO_LEFT 1
#define SERVO_RIGHT 2
// Motors
#define LEFT_MOTOR_PIN 0
#define RIGHT_MOTOR_PIN 1
#define BRUSH_MOTOR_PIN 2
#define SHOOTING_MOTOR_PIN 3
// Analog Inputs
#define LEFT_LASER_PIN 0
#define RIGHT_LASER_PIN 1
#define COLLECT_QRD_PIN 2
#define TARGET_DETECT_LEFT_PIN 3
#define TARGET_DETECT_RIGHT_PIN 4
// Digital Inputs
#define LEFT_SIDE_MICROSWITCH_PIN 9
#define LEFT_FRONT_MICROSWITCH_PIN 10
#define RIGHT_SIDE_MICROSWITCH_PIN 7
#define RIGHT_FRONT_MICROSWITCH_PIN 8
// Knobs
#define MENU_ADJUST_KNOB 6	 // adjust selected menu item
#define VALUE_ADJUST_KNOB 7	 // adjust item value
// Wall following
#define LEFT_DIRECTION -1 
#define RIGHT_DIRECTION 1
#define TOO_CLOSE -1
#define TOO_FAR 1


// OTHER CONSTANTS
// Delays
#define LOAD_DELAY 250
#define REBOUND_DELAY 2000
#define EMPTY_DELAY 5000


// VARIABLES
// Microswitches
bool leftSide = false;
bool rightSide = false;
bool leftFront = false;
bool rightFront = false;
// Wall Following
int laserProximity = TOO_CLOSE;
int previousLaserProximity = TOO_FAR;
int laserRawValue = 0;
int strafeDirection = LEFT_DIRECTION;
int timeOfLastFiring = 0;
bool isEmpty = false;
// Target Finding
bool targetFound = false;
int IRleftRawValue = 0;
int IRrightRawValue = 0;

// MENU ITEMS (for the love of god, don't modify!)
// Thresholds
MenuItem laserThreshold = MenuItem("LT", LASER_THRESHOLD);
MenuItem targetThreshold = MenuItem("TTH", TARGET_THRESHOLD);
MenuItem ballCollectThreshold = MenuItem("CTH", BALL_COLLECT_THRESHOLD);
// Gain parameters
MenuItem laserProportionalGain = MenuItem("L P-Gain", LASER_P_GAIN);
MenuItem laserDerivativeGain = MenuItem("L D-Gain", LASER_D_GAIN);
MenuItem qrdProportionalGain = MenuItem("Q P-Gain", QRD_P_GAIN);
MenuItem qrdDerivativeGain = MenuItem("Q D-Gain", QRD_D_GAIN);
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
	laserProportionalGain, laserDerivativeGain,
	qrdProportionalGain, qrdDerivativeGain,
	brushSpeed, firingSpeed, motorSpeed,
	servoLoadAngle, servoCollectAngle, servoSteerAngle
};
int itemCount = 13;

// State tracking
bool MENU = true; // Changing this will load menu by default (true) or start running (false)
int lcdRefreshPeriod = 20; // Update LCD screen every n iterations. Larger = fewer updates. Smaller = flicker
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
	else 
	{
		WallFollowSensorUpdate();
		WallFollow();
	}
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
		break;
		default:
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

// Returns a bool indicating whether the given microswitch is being pressed
// Optional: Specify a debounce time
bool Microswitch(int microswitchPin, int debounceTime = 15)
{
	if(digitalRead(microswitchPin)) return false;
	delay(debounceTime);
	return !digitalRead(microswitchPin);
}

void Update()
{
	// Buttons
	if(StopButton()) MENU = true;
	if(StartButton()) MENU = false;
	
/*	// Microswitches
	leftFront = Microswitch(LEFT_FRONT_MICROSWITCH_PIN);
	leftSide = Microswitch(LEFT_SIDE_MICROSWITCH_PIN);
	rightFront = Microswitch(RIGHT_FRONT_MICROSWITCH_PIN);
	rightSide = Microswitch(RIGHT_SIDE_MICROSWITCH_PIN);*/

	// Update LCD counter (reduces screen flicker)
	lcdRefreshCount = (lcdRefreshCount <= 0) ? lcdRefreshPeriod : (lcdRefreshCount - 1);
}

// Forces sensor updates while spinning for a specified number of milliseconds
void SoftDelay(int milliseconds)
{
	unsigned long startTime = millis();
	while (millis() < startTime + milliseconds)
		Update();
}

void ProcessMenu()
{
	// Determine selected item and get knob values
	motor.stop(LEFT_MOTOR_PIN);
	motor.stop(RIGHT_MOTOR_PIN);

	int knobValue = knob(VALUE_ADJUST_KNOB);
	int selectedItem = knob(MENU_ADJUST_KNOB) / (1024 / (itemCount - 1));
	if (selectedItem > itemCount - 1) selectedItem = itemCount - 1; // Normalize the selection

	// Display the item information
	LCD.clear(); LCD.home();
	LCD.print(items[selectedItem].Name()); LCD.print(" "); 
	LCD.print(items[selectedItem].Value());
	
	// Show laser threshold
	if (selectedItem == LASER_THRESHOLD) 
	{
		LCD.print(" ");
		LCD.print(analogRead(LEFT_LASER_PIN));	
		LCD.print(" ");
		LCD.print(analogRead(RIGHT_LASER_PIN));	
	}
	
	LCD.setCursor(0,1);
	LCD.print("Set to "); LCD.print(knobValue); LCD.print("?");
	
	// Check to see if user set value
	if(StopButton(200)) items[selectedItem].SetValue(knobValue);
	delay(50);
}

void WallFollowSensorUpdate()
{
	// If lifter arm is empty and reloading delay has passed, set to empty-state
	isEmpty = (analogRead(COLLECT_QRD_PIN) < BALL_COLLECT_THRESHOLD && millis()-timeOfLastFiring >= EMPTY_DELAY);

	// Update laser sensor
	int detectingLaser = (strafeDirection == LEFT_DIRECTION) ? LEFT_LASER_PIN : RIGHT_LASER_PIN;
	laserRawValue = analogRead(detectingLaser);
	laserProximity = (laserRawValue < laserThreshold.Value()) ? TOO_CLOSE : TOO_FAR;

	// Change direction if side microswitches are contacted
	if (strafeDirection == LEFT_DIRECTION && leftSide) strafeDirection = RIGHT_DIRECTION;
	if (strafeDirection == RIGHT_DIRECTION && rightSide) strafeDirection = LEFT_DIRECTION;

	if(!isEmpty) // if we have balls, update IR sensors
	{
		// update IR sensor values (can be ignored if we are empty)
		IRleftRawValue = analogRead(TARGET_DETECT_LEFT_PIN);
	//  IRrightRawValue = analogRead(TARGET_DETECT_RIGHT_PIN);

		// determine if a target has been found
		targetFound = (IRleftRawValue > TARGET_THRESHOLD);
	}
	else
	{
		targetFound = false;
	}
}

void WallFollow()
{
	if(targetFound)
	{
		motor.stop(LEFT_MOTOR_PIN);
		motor.stop(RIGHT_MOTOR_PIN);

		LCD.clear(); LCD.home();
		LCD.print("Firing!");

		Firing();

		targetFound = false;
	}

	// Collection motor should be ON
	motor.speed(BRUSH_MOTOR_PIN, BRUSH_SPEED);

	// Set motors to correct speed and direction
	motor.speed(LEFT_MOTOR_PIN, MOTOR_SPEED * strafeDirection);
	motor.speed(RIGHT_MOTOR_PIN, MOTOR_SPEED * strafeDirection);

	// Compute PID correction
	float proportional = (float)laserProximity * laserProportionalGain.Value();
	float derivative = (float)(laserProximity - previousLaserProximity) * laserDerivativeGain.Value();
	previousLaserProximity = laserProximity;
	
	// Set servos to new corrected angles
	int steeringServo = (strafeDirection == LEFT_DIRECTION) ? SERVO_LEFT : SERVO_RIGHT;
	int fixedServo = (strafeDirection == LEFT_DIRECTION) ? SERVO_RIGHT : SERVO_LEFT;
	SetServo(steeringServo, servoSteerAngle.Value() - (proportional + derivative));
	SetServo(fixedServo, servoSteerAngle.Value());

	// Show steering information on screen
	if(lcdRefreshCount > 2) return;
	LCD.clear(); LCD.home();
	LCD.print("Steer ang:"); LCD.print(proportional + derivative);
	LCD.setCursor(0, 1);
	LCD.print("Direction: "); LCD.print(strafeDirection == LEFT_DIRECTION ? "LEFT" : "RIGHT");
}

void Firing()
{
	// Check if lifter arm is empty
	if(COLLECT_QRD_PIN) < BALL_COLLECT_THRESHOLD)
	{
		isEmpty = false;
		return;
	}

	// Collection motor should be ON
	motor.speed(BRUSH_MOTOR_PIN, BRUSH_SPEED);

	// Start firing rotors (spin-up)
	motor.speed(SHOOTING_MOTOR_PIN, FIRING_SPEED);

	// If necessary, move short distance back along the wall until IR signal is strongest (to correct for stopping distance)
	// 		Adjust robot so parallel to wall using laser readings
	// 			Turn robot until the laser readings are within X of each other's values.

	// Lift loading servo to firing angle; check that lifter QRD goes off
	SetServo(SERVO_BALL, SERVO_LOAD_ANGLE);
	
	// Wait for servo to reach loading angle
	delay(LOAD_DELAY);

	// Check if loading servo arm is empty
	if(analogRead(COLLECT_QRD_PIN) < BALL_COLLECT_THRESHOLD);
	// DOES NOTHING ATM, might not be necessary

	// Put servo back to collecting angle
	SetServo(SERVO_BALL, SERVO_COLLECT_ANGLE);

	// Stop firing rotor motor
	motor.stop(BRUSH_MOTOR_PIN);

	// Wait with collection running for X seconds (possibly strafe in direction ball deflects) to collect the rebound.
	delay(REBOUND_DELAY);
	timeOfLastFiring = millis(); // Reset counter
}