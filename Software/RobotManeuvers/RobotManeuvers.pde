#include <phys253.h>
#include <LiquidCrystal.h>
#include <Servo253.h>
#include <LaserSensor.h>
#include <QrdSensor.h>
#include <MenuItem.h>
#include <EEPROM.h>

// EEPROM ADDRESSES (for the love of god, don't modify!)
// Light sensors
#define TARGET_THRESHOLD 1
#define BALL_COLLECT_THRESHOLD 2
// Gain parameters
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
#define SERVO_WALL_CORRECT_ANGLE 16

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
#define COLLECT_QRD_PIN 2
#define TARGET_DETECT_LEFT_PIN 3
#define TARGET_DETECT_RIGHT_PIN 4
// Digital Inputs
#define LEFT_SIDE_MICROSWITCH_PIN 13
#define LEFT_FRONT_MICROSWITCH_PIN 12
#define RIGHT_SIDE_MICROSWITCH_PIN 15
#define RIGHT_FRONT_MICROSWITCH_PIN 14
#define OUTER_LEFT_QRD_PIN 8
#define INNER_LEFT_QRD_PIN 9
#define INNER_RIGHT_QRD_PIN 10
#define OUTER_RIGHT_QRD_PIN 11
// Knobs
#define MENU_ADJUST_KNOB 6	 // Adjust selected menu item
#define VALUE_ADJUST_KNOB 7	 // Adjust item value
// Wall following
#define LEFT_DIRECTION -1 
#define RIGHT_DIRECTION 1
// Differential steering
#define LEFT_DIFF_MULT 1
#define RIGHT_DIFF_MULT -1
#define DIFF_REVERSE -1
#define TOO_LEFT -1.0
#define TOO_RIGHT 1.0
#define OFF_TAPE 5.0

// OTHER CONSTANTS
// Delays
#define REBOUND_DELAY 2000
#define EMPTY_DELAY 5000
#define WALL_FOLLOW_END_DELAY 3000
#define SERVO_TRANSFORM_DELAY 250
#define MOVE_OFF_WALL_DELAY 500
#define TURN_135_DEG_DELAY 500
#define COLLECTION_DELAY 1000
#define COLLECTION_REVERSE_DELAY 250

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
// QRDs
bool qrdOuterLeft = false;
bool qrdInnerLeft = false;
bool qrdInnerRight = false;
bool qrdOuterRight = false;
// Wall Following
int strafeDirection = LEFT_DIRECTION;
int correctionMultiplier = 1;
bool frontTouchWall = false;
bool backTouchWall = false;

unsigned long timeOfLastFiring = 0;
bool isEmpty = false;

// Target Finding
bool targetFound = false;
// Tape Following
int qrdError = 0;
int qrdPreviousError = 0;
int qrdDeriveCounter = 1;
bool endFound = false;
// Collection
bool ballCollected = false;

// MENU ITEMS 
// Thresholds
MenuItem targetThreshold = MenuItem("Tar TH", TARGET_THRESHOLD);
MenuItem ballCollectThreshold = MenuItem("Col TH", BALL_COLLECT_THRESHOLD);
// QRD gains
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
MenuItem servoWallCorrectAngle = MenuItem("Wall ang", SERVO_WALL_CORRECT_ANGLE);

// Load menu items into an array
MenuItem items[] = 
{
	targetThreshold, ballCollectThreshold,
	qrdProportionalGain, qrdDerivativeGain, 
	brushSpeed, firingSpeed, bikeSpeed, diffSpeed, 
	servoLoadAngle, servoCollectAngle, servoBikeAngle, servoDiffAngle, servoWallCorrectAngle 
};
const int itemCount = 13;

const int lcdRefreshPeriod = 20; // Update LCD screen every n iterations. Larger = fewer updates. Smaller = flicker
unsigned int lcdRefreshCount = 0; // Current iteration. Do not change this value

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
		Reset();
		Print("Error: no state");
		break;
	}
}

// Sets a specified angle to the given servo
void SetServo(int servoIndex, int servoAngle)
{
	// Constrain possible angles
	if (servoAngle > 180) servoAngle = 180;
	else if (servoAngle < 0) servoAngle = 0;
	
	// Set angle of specific servo
	if(servoIndex == 0)	RCServo0.write(servoAngle);
	else if (servoIndex == 1) RCServo1.write(servoAngle);
	else if (servoIndex == 2) RCServo2.write(servoAngle);
}

inline void Reset() {
	LCD.clear();
	LCD.home();
}

inline void Print(String text) {
	LCD.print(text);
}

inline void Print(int value) {
	LCD.print(value);
}

inline void Print(String text, int value)
{
	LCD.print(text);
	LCD.print(value);
}

// Determines if the start button is being pressed.
// Optional: Debounces the button for the specified number of milliseconds
inline bool StartButton(int debounceTime = 40)
{
	if(!startbutton()) return false;
	delay(debounceTime);
	return startbutton();
}

// Determines if the stop button is being pressed
// Optional: Debounces the button for the specified number of milliseconds
inline bool StopButton(int debounceTime = 40)
{
	if(!stopbutton()) return false;
	delay(debounceTime);
	return stopbutton();
}

// Returns a bool indicating whether the given microswitch is being pressed
// Optional: Specify a debounce time
inline bool Microswitch(int microswitchPin, int debounceTime = 15)
{
	if(digitalRead(microswitchPin)) return false;
	delay(debounceTime);
	return !digitalRead(microswitchPin);
}

// Returns a bool indicating whether the given qrd is sensing a non-reflective surface
inline bool QRD(int qrdPin) {
	return !digitalRead(qrdPin);
}

// Returns a bool indicating whether the collection QRD is being triggered by a ball
inline bool Armed() {
	return (analogRead(COLLECT_QRD_PIN) < ballCollectThreshold.Value());
}

// Returns a bool indicating whether the given IR sensor is detecting a target
inline bool IR(int irPin) {
	return (analogRead(irPin) > TARGET_THRESHOLD);
}

inline bool TargetAcquired(){
	return (analogRead(TARGET_DETECT_LEFT_PIN) > TARGET_THRESHOLD);
}

void Update() // Update - Menu and LCD
{
	if(maneuverState != MENU_STATE && StopButton()) // If not in menu, check if enter button is pressed
	{
		lastState = maneuverState;
		maneuverState = MENU_STATE;
	}
	else if(StartButton()) maneuverState = lastState;
	lcdRefreshCount = (lcdRefreshCount <= 0) ? lcdRefreshPeriod : (lcdRefreshCount - 1);
}

void ProcessMenu()
{
	motor.stop_all();

	if (StartButton(2000)) OverrideState(); // Unlock secret menu

	// Determine selected item and get knob values
	int knobValue = knob(VALUE_ADJUST_KNOB);
	int selectedItem = knob(MENU_ADJUST_KNOB) / (1024 / (itemCount - 1));
	if (selectedItem > itemCount - 1) selectedItem = itemCount - 1; // Normalize the selection

	// Display the item information
	Reset(); 
	Print(items[selectedItem].Name()); Print(" "); Print(items[selectedItem].Value());
	LCD.setCursor(0,1);
	Print("Set to ", knobValue); Print("?");
	
	// Check to see if user set value
	if(StopButton(200)) items[selectedItem].SetValue(knobValue);
	delay(50);
}

void OverrideState()
{
	Reset();
	Print("Secret menu"); LCD.setCursor(0,1); Print("unlocked");
	delay(1000);

	while(!StartButton())
	{
 		int selectedState = knob(VALUE_ADJUST_KNOB) / 256 + 1; // Allow user to select states 1-4 (not zero)
 		Reset(); 
 		Print("Current: ", lastState); LCD.setCursor(0,1); 
 		Print("Set to ", selectedState); Print("?");
 		if(StopButton()) lastState = selectedState;
 		delay(50);
 	};
 }

 void WallFollowSensorUpdate()
 {
	// Detect ball collection
 	isEmpty = (!Armed() && millis()-timeOfLastFiring >= EMPTY_DELAY);

	// Microswitches
 	leftSide = Microswitch(LEFT_SIDE_MICROSWITCH_PIN);
 	rightSide = Microswitch(RIGHT_SIDE_MICROSWITCH_PIN);
 	leftFront = Microswitch(LEFT_FRONT_MICROSWITCH_PIN);
 	rightFront = Microswitch(RIGHT_FRONT_MICROSWITCH_PIN);

	// Handle wall collisions
 	if (leftSide && strafeDirection == LEFT_DIRECTION) strafeDirection == RIGHT_DIRECTION;
 	else if (rightSide && strafeDirection == RIGHT_DIRECTION) strafeDirection == LEFT_DIRECTION;

 	if(!isEmpty) targetFound = IR(TARGET_DETECT_LEFT_PIN);
 	else targetFound = false;
 }

 void WallFollow()
 {
 	WallFollowSensorUpdate();

	// End the wall following maneuver
 	if ((leftSide || rightSide) && isEmpty)
 	{
 		unsigned long startTime = millis();
 		while (millis() < startTime + WALL_FOLLOW_END_DELAY)
 		{
 			Strafe();
 			WallFollowSensorUpdate();
 			if (StopButton(3000)) return; // escape condition
 		}
 		MoveOffWall();
 		AcquireTapeFromWall();
 		maneuverState = TAPE_FOLLOW_DOWN_STATE;
 		return;
 	}

	// FIRE!
 	if(targetFound && !isEmpty)
 	{
 		Reset(); Print("Firing!");
 		Fire();
 		targetFound = false;
 	}

 	Strafe();
 }

// Strafes along front wall while performing ON/OFF distance correction
 void Strafe()
 {
	// Engage collection, set strafing speeds
 	motor.speed(BRUSH_MOTOR_PIN, brushSpeed.Value());
 	motor.speed(LEFT_MOTOR_PIN, strafeDirection * bikeSpeed.Value());
 	motor.speed(RIGHT_MOTOR_PIN, strafeDirection * bikeSpeed.Value());

 	if(strafeDirection == LEFT_DIRECTION)
 	{
 		SetServo(SERVO_LEFT, 180 - servoBikeAngle.Value());
 		SetServo(SERVO_RIGHT, servoBikeAngle.Value() - servoWallCorrectAngle.Value());
 	}
	else // strafeDirection == RIGHT_DIRECTION
	{
		SetServo(SERVO_LEFT, 180 - servoBikeAngle.Value() + servoWallCorrectAngle.Value());
		SetServo(SERVO_RIGHT, servoBikeAngle.Value());
	}
}

void Fire() 
{
	// Disengage navigationm; engage collection and firing
	motor.stop(LEFT_MOTOR_PIN);
	motor.stop(RIGHT_MOTOR_PIN);
	motor.speed(BRUSH_MOTOR_PIN, brushSpeed.Value());
	motor.speed(SHOOTING_MOTOR_PIN, firingSpeed.Value());

	// Load firing mechanism
	Reset(); Print("Loading ball");
	SetServo(SERVO_BALL, servoLoadAngle.Value());
	while(Armed()) // Wait until ball unloaded
		if (StopButton(3000)) return; // escape condition	
	Reset();
	SetServo(SERVO_BALL, servoCollectAngle.Value()); // return arm to collect position

	// Stop firing rotor motor
	delay(500); // Allow time for ball to shoot
	motor.stop(SHOOTING_MOTOR_PIN);

	delay(REBOUND_DELAY); // Attempt to collect rebounded balls
	timeOfLastFiring = millis();
}

// Exectutes a controlled maneuver to exit the wall from a wall following position
void MoveOffWall()
{
	Reset(); Print("Leaving wall");

	// Engage collection and halt navigation
	motor.speed(BRUSH_MOTOR_PIN, brushSpeed.Value());
	motor.stop(LEFT_MOTOR_PIN); motor.stop(RIGHT_MOTOR_PIN);
	delay(500); // allow motors to come to a halt

	// Rotate servos
	SetServo(SERVO_LEFT, servoDiffAngle.Value()); 
	SetServo(SERVO_RIGHT, servoDiffAngle.Value());
	delay(SERVO_TRANSFORM_DELAY);  

	// Make a controlled reverse
	motor.speed(LEFT_MOTOR_PIN, LEFT_DIFF_MULT * DIFF_REVERSE * diffSpeed.Value());
	motor.speed(RIGHT_MOTOR_PIN, RIGHT_DIFF_MULT * DIFF_REVERSE * diffSpeed.Value());
	delay(MOVE_OFF_WALL_DELAY);

	// Make a controlled turn
	motor.speed(LEFT_MOTOR_PIN, diffSpeed.Value() * -strafeDirection);
	motor.speed(RIGHT_MOTOR_PIN, diffSpeed.Value() * -strafeDirection);
	delay(TURN_135_DEG_DELAY);
}

void AcquireTapeFromWall()
{
	Reset(); Print("Acquiring Tape");

	motor.speed(LEFT_MOTOR_PIN, LEFT_DIFF_MULT * diffSpeed.Value());
	motor.speed(RIGHT_MOTOR_PIN, RIGHT_DIFF_MULT * diffSpeed.Value());

	do
	{
		qrdInnerLeft = QRD(INNER_LEFT_QRD_PIN);
		qrdInnerRight = QRD(INNER_RIGHT_QRD_PIN);
		if (StopButton(3000)) return; // escape condition
	}
	while(!qrdInnerLeft && !qrdInnerRight);
}

void FollowTapeSensorUpdate(int followDirection) // Update - Following tape
{
	// Check if end has been found
	if(followDirection == FOLLOW_UP_DIRECTION)
	{
		qrdOuterLeft = QRD(OUTER_LEFT_QRD_PIN);
		qrdOuterRight = QRD(OUTER_RIGHT_QRD_PIN);
		endFound = (qrdOuterLeft || qrdOuterRight);
	}
	else if(followDirection == FOLLOW_DOWN_DIRECTION)
	{
		leftFront = Microswitch(LEFT_FRONT_MICROSWITCH_PIN);
		rightFront = Microswitch(RIGHT_FRONT_MICROSWITCH_PIN);
		endFound = (leftFront || rightFront);
	}

	if(endFound) return; // Only check line-following stuff if not at the end
	qrdInnerLeft = QRD(INNER_LEFT_QRD_PIN);
	qrdInnerRight = QRD(INNER_RIGHT_QRD_PIN);
}

void FollowTape(int followDirection) // Looping maneuver
{
	FollowTapeSensorUpdate(followDirection);

	// If the end has been found,
	if(endFound)
	{
		if(followDirection == FOLLOW_UP_DIRECTION) 			// while following tape up,
		{
			AcquireWallFromTape();								// find the front wall (cross tape-less gap)
			maneuverState = WALL_FOLLOWING_STATE;				// begin wall following
			endFound = false;
			return;
		}
		else if(followDirection == FOLLOW_DOWN_DIRECTION)	// while following tape down,
		{
			SquareTouch();										// square to collection wall
			maneuverState = COLLECTION_STATE;					// begin collection maneuver
			endFound = false;
			return;
		}
	}

	// Compute QRD error
	if(qrdInnerLeft && qrdInnerRight) qrdError = 0;
	else if(!qrdInnerLeft && qrdInnerRight) qrdError = TOO_LEFT;
	else if(qrdInnerLeft && !qrdInnerRight)	qrdError = TOO_RIGHT;
	else if(!qrdInnerLeft && !qrdInnerRight) qrdError = (qrdPreviousError <= TOO_LEFT) ? -1*OFF_TAPE : OFF_TAPE;

	// Compute PID course correction
	float proportional = qrdError * qrdProportionalGain.Value();
	float derivative = (float)(qrdError - qrdPreviousError) / (float)qrdDeriveCounter * qrdDerivativeGain.Value();
	float compensationSpeed = proportional + derivative;
	motor.speed(LEFT_MOTOR_PIN, LEFT_DIFF_MULT * (diffSpeed.Value() + compensationSpeed));
	motor.speed(RIGHT_MOTOR_PIN, RIGHT_DIFF_MULT * (diffSpeed.Value() + compensationSpeed));
	if(qrdPreviousError != qrdError)
	{
		qrdPreviousError = qrdError;
		qrdDeriveCounter = 1;
	}
	else qrdDeriveCounter++;

	// Show steering information on screen
	if(lcdRefreshCount > 2) return;
	Reset();
	Print("Steer speed:", compensationSpeed);
	LCD.setCursor(0, 1);
	Print("Error: ", qrdError);
}

void SquareTouch()
{
	Reset(); 
	Print("Wall found,"); LCD.setCursor(0,1);
	Print("Squaring up...");
	motor.speed(BRUSH_MOTOR_PIN, brushSpeed.Value()); // Engage collection
	
	do
	{
		leftFront = Microswitch(LEFT_FRONT_MICROSWITCH_PIN);
		rightFront = Microswitch(RIGHT_FRONT_MICROSWITCH_PIN);
		
		// Disengage motors when touching wall
		int leftSpeed = leftFront ? 0 : LEFT_DIFF_MULT * diffSpeed.Value(); 
		int rightSpeed = rightFront ? 0 : RIGHT_DIFF_MULT * diffSpeed.Value();
		motor.speed(LEFT_MOTOR_PIN, leftSpeed);
		motor.speed(RIGHT_MOTOR_PIN, rightSpeed);
	
		if (StopButton(3000)) return; // escape condition
	}
	while(!leftFront && !rightFront); // as long as BOTH switches are not triggered
}

void CollectionSensorUpdate() {
	ballCollected = Armed();
}

void Collection()
{
	Reset(); Print("Collecting...");
	motor.speed(BRUSH_MOTOR_PIN, brushSpeed.Value()); // Engage collection
	CollectionSensorUpdate();

	if (ballCollected)
	{
		AcquireTapeFromCollect();
		maneuverState = FOLLOW_UP_DIRECTION;
		ballCollected = false;
		
	} else BumpCollect();
}

void BumpCollect()
{
	LCD.setCursor(0,1);	Print("Bumping wall");

	// Engage collection and reverse navigation motors
	motor.speed(BRUSH_MOTOR_PIN, brushSpeed.Value()); // Engage collection	
	motor.speed(LEFT_MOTOR_PIN, LEFT_DIFF_MULT * DIFF_REVERSE * diffSpeed.Value());
	motor.speed(RIGHT_MOTOR_PIN, RIGHT_DIFF_MULT * DIFF_REVERSE * diffSpeed.Value());
	delay(COLLECTION_REVERSE_DELAY);
	
	// Disengage navigation motors
	motor.stop(LEFT_MOTOR_PIN); 
	motor.stop(RIGHT_MOTOR_PIN);

	delay(COLLECTION_DELAY);
	SquareTouch();
}

void AcquireTapeFromCollect() 
{
	// Set display state
	Reset();
	Print("Ball collected,");
	LCD.setCursor(0,1);
	Print("Aquiring tape...");

	// Back up a certain distance
	motor.speed(LEFT_MOTOR_PIN, LEFT_DIFF_MULT * DIFF_REVERSE * diffSpeed.Value());
	motor.speed(RIGHT_MOTOR_PIN, RIGHT_DIFF_MULT * DIFF_REVERSE * diffSpeed.Value());
	delay(COLLECTION_REVERSE_DELAY);

	// Stop Motors
	motor.stop(LEFT_MOTOR_PIN);
	motor.stop(RIGHT_MOTOR_PIN);

	// Spin about 135 degrees
	motor.speed(LEFT_MOTOR_PIN, LEFT_DIFF_MULT * diffSpeed.Value());
	motor.speed(RIGHT_MOTOR_PIN, RIGHT_DIFF_MULT * DIFF_REVERSE * diffSpeed.Value());
	delay(TURN_135_DEG_DELAY);

	// Wait until tape is detected
	do
	{
		qrdInnerLeft = QRD(INNER_LEFT_QRD_PIN);
		qrdInnerRight = QRD(INNER_RIGHT_QRD_PIN);
		if (StopButton(3000)) return; // escape condition
	}
	while(!qrdInnerLeft && !qrdInnerRight);

	// Disengage motors
	motor.stop(LEFT_MOTOR_PIN);
	motor.stop(RIGHT_MOTOR_PIN);
}

void AcquireWallFromTape() 
{
	Reset(); 
	Print("Tape ended,"); LCD.setCursor(0,1);
	Print("Finding Wall...");
	SquareTouch();
}