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
#define QRD_THRESHOLD 3
// Gain parameters
#define LASER_P_GAIN 4
#define LASER_D_GAIN 5
#define QRD_P_GAIN 6
#define QRD_D_GAIN 7
// Motor speeds
#define BRUSH_SPEED 8
#define FIRING_SPEED 9
#define BIKE_SPEED 10
#define DIFF_SPEED 11
// Servo angles
#define SERVO_LOAD_ANGLE 12
#define SERVO_COLLECT_ANGLE 13
#define SERVO_BIKE_ANGLE 14
#define SERVO_DIFF_ANGLE 15


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
#define LEFT_SIDE_MICROSWITCH_PIN 13
#define LEFT_FRONT_MICROSWITCH_PIN 12
#define RIGHT_SIDE_MICROSWITCH_PIN 15
#define RIGHT_FRONT_MICROSWITCH_PIN 14
#define OUTER_LEFT_QRD_PIN 8			// REQUIRES ADJUSTMENT
#define INNER_LEFT_QRD_PIN 9			// REQUIRES ADJUSTMENT
#define INNER_RIGHT_QRD_PIN 10			// REQUIRES ADJUSTMENT
#define OUTER_RIGHT_QRD_PIN 11			// REQUIRES ADJUSTMENT
// Knobs
#define MENU_ADJUST_KNOB 6	 // Adjust selected menu item
#define VALUE_ADJUST_KNOB 7	 // Adjust item value
// Wall following
#define LEFT_DIRECTION -1 
#define RIGHT_DIRECTION 1
#define TOO_CLOSE -1
#define TOO_FAR 1
// Differential steering
#define LEFT_DIFF_MULT 1
#define RIGHT_DIFF_MULT -1
#define DIFF_REVERSE -1


// OTHER CONSTANTS
// Delays
#define LOAD_DELAY 250
#define REBOUND_DELAY 2000
#define EMPTY_DELAY 5000
#define WALL_FOLLOW_END_DELAY 3000
#define SERVO_TRANSFORM_DELAY 250
#define MOVE_OFF_WALL_DELAY 500
#define TURN_135_DEG_DELAY 500


// LOOPING MANEUVER STATES
#define MENU_STATE 0
#define WALL_FOLLOWING_STATE 1
#define TAPE_FOLLOW_DOWN_STATE 2
#define COLLECTION_STATE 3
#define TAPE_FOLLOW_UP_STATE 4
// Loop behaviour switches
#define FOLLOW_DOWN_DIRECTION 0
#define FOLLOW_UP_DIRECTION 1

// VARIABLES
// State tracking
int maneuverState = MENU_STATE; // Changing this will change the robot's inital state (menu is default)
int lastState = WALL_FOLLOWING_STATE; // State that the menu will initially switch from
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
unsigned long timeOfLastFiring = 0;
bool isEmpty = false;
unsigned long endingWallFollowCounter = 0;
// Target Finding
bool targetFound = false;
int IRleftRawValue = 0;
int IRrightRawValue = 0;
// Tape Acquiring
bool tapeFound = false;
// Tape Following
int qrdOuterLeftRawValue = 0;
int qrdInnerLeftRawValue = 0;
int qrdInnerRightRawValue = 0;
int qrdOuterRightRawValue = 0;

// MENU ITEMS (for the love of god, don't modify!)
// Thresholds
MenuItem laserThreshold = MenuItem("LAS T", LASER_THRESHOLD);
MenuItem targetThreshold = MenuItem("TAR TH", TARGET_THRESHOLD);
MenuItem ballCollectThreshold = MenuItem("COL TH", BALL_COLLECT_THRESHOLD);
MenuItem qrdThreshold = MenuItem("QRD TH", QRD_THRESHOLD);
// Gain parameters
MenuItem laserProportionalGain = MenuItem("L P-Gain", LASER_P_GAIN);
MenuItem laserDerivativeGain = MenuItem("L D-Gain", LASER_D_GAIN);
MenuItem qrdProportionalGain = MenuItem("Q P-Gain", QRD_P_GAIN);
MenuItem qrdDerivativeGain = MenuItem("Q D-Gain", QRD_D_GAIN);
// Motor speeds
MenuItem brushSpeed = MenuItem("Brush Vel", BRUSH_SPEED);
MenuItem firingSpeed = MenuItem("Fire Vel", FIRING_SPEED);
MenuItem bikeSpeed = MenuItem("Bike Vel", BIKE_SPEED);
MenuItem diffSpeed = MenuItem("Diff Vel", DIFF_SPEED);
// Servo angles
MenuItem servoLoadAngle = MenuItem("Load ang", SERVO_LOAD_ANGLE);
MenuItem servoCollectAngle = MenuItem("Col ang", SERVO_COLLECT_ANGLE);
MenuItem servoBikeAngle = MenuItem("Bike ang", SERVO_BIKE_ANGLE);
MenuItem servoDiffAngle = MenuItem("Diff ang", SERVO_DIFF_ANGLE);

// Load menu items into an array
MenuItem items[] = 
{
	laserThreshold, targetThreshold, ballCollectThreshold, qrdThreshold, 
	laserProportionalGain, laserDerivativeGain, qrdProportionalGain, qrdDerivativeGain, 
	brushSpeed, firingSpeed, bikeSpeed, diffSpeed, 
	servoLoadAngle, servoCollectAngle, servoBikeAngle, servoDiffAngle
};
int itemCount = 15;

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

	switch(maneuverState)
	{
		case MENU_STATE:
			ProcessMenu();
		break;
		case WALL_FOLLOWING_STATE:
			WallFollow();
		break;
		case TAPE_FOLLOW_DOWN_STATE:
			FollowTape(FOLLOW_DOWN_DIRECTION);
		break;
		case COLLECTION_STATE:
			Collection();
		break;
		case TAPE_FOLLOW_UP_STATE:
			FollowTape(FOLLOW_UP_DIRECTION);
		break;
		default:
		break;
	}
}

// Sets a specified angle to the given servo
void SetServo(int servoIndex, int servoAngle)
{
	if (servoAngle > 180) servoAngle = 180;
	if (servoAngle < 0) servoAngle = 0;
	switch(servoIndex)
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

void Reset()
{
	LCD.clear();
	LCD.home();
}

void Print(String text)
{
	LCD.print(text);
}

void Print(int value)
{
	LCD.print(value);
}

void Print(String text, int value)
{
	LCD.print(text);
	LCD.print(value);
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

// Forces sensor updates while spinning for a specified number of milliseconds
void SoftDelay(int milliseconds)
{
	unsigned long startTime = millis();
	while (millis() < startTime + milliseconds)
		Update();
}

void Update() // Update - Menu and LCD
{
	if(maneuverState != MENU_STATE) // If not in menu, check if enter button is pressed
		if(StopButton())
		{
			lastState = maneuverState;
			maneuverState = MENU_STATE;
		}
	else // If already in menu, check if exit button is pressed
		if(StartButton()) maneuverState = lastState;

	// Update LCD counter (reduces screen flicker)
	lcdRefreshCount = (lcdRefreshCount <= 0) ? lcdRefreshPeriod : (lcdRefreshCount - 1);
}

void ProcessMenu() // Looping maneuver
{
	// Stop motors
	motor.stop_all();

	// Determine selected item and get knob values
	int knobValue = knob(VALUE_ADJUST_KNOB);
	int selectedItem = knob(MENU_ADJUST_KNOB) / (1024 / (itemCount - 1));
	if (selectedItem > itemCount - 1) selectedItem = itemCount - 1; // Normalize the selection

	// Display the item information
	Reset();
	Print(items[selectedItem].Name()); Print(" "); Print(items[selectedItem].Value());
	
	// Show laser threshold
	if (selectedItem == LASER_THRESHOLD) 
	{
		Print(" ", analogRead(LEFT_LASER_PIN));	
		Print(" ", analogRead(RIGHT_LASER_PIN));	
	}
	
	LCD.setCursor(0,1);
	Print("Set to ", knobValue); Print("?");
	
	// Check to see if user set value
	if(StopButton(200)) items[selectedItem].SetValue(knobValue);
	delay(50);
}

void WallFollowSensorUpdate() // Update - Wall following
{
	// If not ignoring lifter arm QRD (committed to collection)
	if(endingWallFollowCounter == 0)
		// If lifter arm is empty and reloading delay has passed, set to empty-state
		isEmpty = (analogRead(COLLECT_QRD_PIN) < BALL_COLLECT_THRESHOLD && millis()-timeOfLastFiring >= EMPTY_DELAY);

	// Microswitches
	leftSide = Microswitch(LEFT_SIDE_MICROSWITCH_PIN);
	rightSide = Microswitch(RIGHT_SIDE_MICROSWITCH_PIN);

	// Update laser sensor
	int detectingLaser = (strafeDirection == LEFT_DIRECTION) ? LEFT_LASER_PIN : RIGHT_LASER_PIN;
	laserRawValue = analogRead(detectingLaser);
	laserProximity = (laserRawValue < laserThreshold.Value()) ? TOO_CLOSE : TOO_FAR;

	// Change direction if side microswitches are contacted
	// If the robot is in the empty state, it begins to exit the wall-follow maneuver
	if (strafeDirection == LEFT_DIRECTION && leftSide)
	{
		strafeDirection = RIGHT_DIRECTION;
		// Begin end-wall-follow counter if the robot is empty at the rebound
		endingWallFollowCounter = (isEmpty) ? millis() : 0;
	}
	if (strafeDirection == RIGHT_DIRECTION && rightSide)
	{
		strafeDirection = LEFT_DIRECTION;
		endingWallFollowCounter = (isEmpty) ? millis() : 0;
	}

	if(!isEmpty) // If we have balls, update IR sensors
	{
		// Update IR sensor values (can be ignored if we are empty)
		IRleftRawValue = analogRead(TARGET_DETECT_LEFT_PIN);
	//  IRrightRawValue = analogRead(TARGET_DETECT_RIGHT_PIN);

		// Determine if a target has been found
		targetFound = (IRleftRawValue > targetThreshold.Value());
	}
	else targetFound = false;
}

void WallFollow() // Looping maneuver
{
	WallFollowSensorUpdate();

	// When the robot has moved far enough from the wall after going to the empty state, execute the discrete
	//   MoveOffWall() maneuver and then change to the tape-acquiring maneuver state
	if(endingWallFollowCounter != 0 && (millis()-endingWallFollowCounter) >= WALL_FOLLOW_END_DELAY)
	{
		MoveOffWall();
		AcquireTapeFromWall();
		maneuverState = TAPE_FOLLOW_DOWN_STATE;
		return;
	}

	// When a target is found, execute discrete Firing() maneuver
	if(targetFound)
	{
		Reset();
		Print("Firing!");

		Firing();

		targetFound = false;
	}

	// Collection motor should be ON
	motor.speed(BRUSH_MOTOR_PIN, BRUSH_SPEED);

	// Set motors to correct speed and direction
	motor.speed(LEFT_MOTOR_PIN, BIKE_SPEED * strafeDirection);
	motor.speed(RIGHT_MOTOR_PIN, BIKE_SPEED * strafeDirection);

	// Compute PID correction
	float proportional = (float)laserProximity * laserProportionalGain.Value();
	float derivative = (float)(laserProximity - previousLaserProximity) * laserDerivativeGain.Value();
	previousLaserProximity = laserProximity;
	
	// Set servos to new corrected angles
	int steeringServo = (strafeDirection == LEFT_DIRECTION) ? SERVO_LEFT : SERVO_RIGHT;
	int fixedServo = (strafeDirection == LEFT_DIRECTION) ? SERVO_RIGHT : SERVO_LEFT;
	SetServo(steeringServo, servoBikeAngle.Value() - (proportional + derivative));
	SetServo(fixedServo, servoBikeAngle.Value());

	// Show steering information on screen
	if(lcdRefreshCount > 2) return;
	Reset();
	Print("Steer ang:", proportional + derivative);
	LCD.setCursor(0, 1);
	Print("Direction: "); Print(strafeDirection == LEFT_DIRECTION ? "LEFT" : "RIGHT");
}

void Firing() // Discrete maneuver
{
	// Check if lifter arm is empty
	if(COLLECT_QRD_PIN) < BALL_COLLECT_THRESHOLD)
	{
		isEmpty = false;
		return;
	}

	// Stop movement motors
	motor.stop(LEFT_MOTOR_PIN);
	motor.stop(RIGHT_MOTOR_PIN);

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

// Moves the robot away from the wall and turns it until ready to acquire tape
void MoveOffWall() // Discrete maneuver
{
	Reset();
	Print("Moving away");
	LCD.setCursor(0,1);
	Print("from the wall...")

	// Collection motor should be ON
	motor.speed(BRUSH_MOTOR_PIN, BRUSH_SPEED);

	// Stop Motors
	motor.stop(LEFT_MOTOR_PIN);
	motor.stop(RIGHT_MOTOR_PIN);

	// Move servos to differential steering configuration
	SetServo(SERVO_LEFT, servoDiffAngle.Value());
	SetServo(SERVO_RIGHT, servoDiffAngle.Value());
	delay(SERVO_TRANSFORM_DELAY);

	// Reverse from wall
	motor.speed(LEFT_MOTOR_PIN, LEFT_DIFF_MULT * DIFF_REVERSE * diffSpeed.Value());
	motor.speed(RIGHT_MOTOR_PIN, RIGHT_DIFF_MULT * DIFF_REVERSE * diffSpeed.Value());
	delay(MOVE_OFF_WALL_DELAY);

	// Turn 135deg from wall, towards center of arena
	if(strafeDirection == LEFT_DIRECTION) // On the right side of the arena
	{
		motor.speed(LEFT_MOTOR_PIN, LEFT_DIFF_MULT * diffSpeed.Value());
		motor.speed(RIGHT_MOTOR_PIN, RIGHT_DIFF_MULT * DIFF_REVERSE * diffSpeed.Value());
	}
	else // On the left side of the arena
	{
		motor.speed(LEFT_MOTOR_PIN, LEFT_DIFF_MULT * DIFF_REVERSE * diffSpeed.Value());
		motor.speed(RIGHT_MOTOR_PIN, RIGHT_DIFF_MULT * diffSpeed.Value());
	}
	delay(TURN_135_DEG_DELAY);

	tapeFound = false;
}

void AcquireTapeFromWall() // Discrete maneuver
{
	// Set display state
	if(lcdRefreshCount > 2) return;
	Reset();
	Print("Acquiring Tape");

	// Set motor speed
	motor.speed(LEFT_MOTOR_PIN, LEFT_DIFF_MULT * diffSpeed.Value());
	motor.speed(RIGHT_MOTOR_PIN, RIGHT_DIFF_MULT * diffSpeed.Value());

	do
	{
		qrdInnerLeftRawValue = analogRead(INNER_LEFT_QRD_PIN);
		qrdInnerRightRawValue = analogRead(INNER_RIGHT_QRD_PIN);
	}
	while(qrdInnerLeftRawValue < qrdThreshold.Value() && qrdInnerRightRawValue < qrdThreshold.Value());

	maneuverState = TAPE_FOLLOW_DOWN_STATE;
	tapeFound = false;
}

void FollowTapeSensorUpdate() // Update - Following tape
{
	
}

void FollowTape(int followDirection) // Looping maneuver
{
	// Once either touch sensor is triggered (use the bool), run SquareTouch() and then change loop state to Collection()
}

// Turns the robot until both front touch sensors are in contact with the wall
void SquareTouch() // Discrete maneuver
{

}

void CollectionSensorUpdate() // Update - collection
{

}

void Collection() // Looping maneuver
{

}

void BumpCollect() // Discrete maneuver
{

}

void AcquireTapeFromCollect() // Discrete maneuver
{

}

void AcquireWallFromTape() //  Discrete maneuver
{

}