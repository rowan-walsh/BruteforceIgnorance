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
#define HOME_BEACON_THRESHOLD 5
#define BALL_COLLECT_THRESHOLD 2
#define BREAK_BEAM_THRESHOLD 4
// Gain parameters
#define QRD_P_GAIN 6
#define QRD_D_GAIN 7
#define RIGHT_STRAFE_GAIN 18
// Motor speeds
#define BRUSH_SPEED 8
#define FIRING_SPEED 9
#define BIKE_SPEED 10
#define DIFF_UP_SPEED 11
#define DIFF_DOWN_SPEED 3
// Servo angles
#define SERVO_LOAD_ANGLE 12
#define SERVO_COLLECT_ANGLE 13
#define SERVO_BIKE_ANGLE 14
#define SERVO_DIFF_ANGLE 15
#define SERVO_WALL_REAR_ANGLE 16
#define SERVO_WALL_FRONT_ANGLE 17

// PIN DECLARATIONS
// Servo indices
#define BALL_SERVO 0
#define LEFT_SERVO 1
#define RIGHT_SERVO 2
// Motors
#define LEFT_MOTOR_PIN 0
#define RIGHT_MOTOR_PIN 1
#define BRUSH_MOTOR_PIN 2
#define SHOOTING_MOTOR_PIN 3
// Analog Inputs
#define BREAK_BEAM_SENSOR_PIN 3
#define COLLECT_QRD_PIN 2
#define TARGET_IR_PIN 1
#define HOME_BEACON_IR_PIN 0
// Digital Inputs
#define LEFT_SIDE_MICROSWITCH_PIN 7
#define LEFT_FRONT_MICROSWITCH_PIN 6
#define RIGHT_SIDE_MICROSWITCH_PIN 4
#define RIGHT_FRONT_MICROSWITCH_PIN 5
#define OUTER_LEFT_QRD_PIN 3
#define INNER_LEFT_QRD_PIN 2
#define INNER_RIGHT_QRD_PIN 1
#define OUTER_RIGHT_QRD_PIN 0
// Knobs
#define MENU_ADJUST_KNOB 6	 // Adjust selected menu item
#define VALUE_ADJUST_KNOB 7	 // Adjust item value
// Wall following
#define LEFT_DIRECTION 1 
#define RIGHT_DIRECTION -1
// Differential steering
#define LEFT_DIFF_MULT -1
#define RIGHT_DIFF_MULT 1
#define DIFF_REVERSE 1
#define TOO_LEFT -1.0
#define TOO_RIGHT 1.0
#define OFF_TAPE 2.0

// OTHER CONSTANTS
// Delays
#define REBOUND_DELAY 3000				// Fairly arbitrary
#define WALL_FOLLOW_END_DELAY 1500		// Good
#define SERVO_TRANSFORM_DELAY 1000		// Fairly arbitrary
#define MOVE_OFF_WALL_DELAY 1000		// Arbitrary, probably too long
#define TURN_135_DEG_DELAY 1000			// Arbitrary, untested
#define COLLECTION_DELAY 1000			// Good
#define COLLECTION_REVERSE_DELAY 500	// Good
#define BRUSH_LOAD_TIMEOUT_DELAY 4000  	// Experimental

// LOOPING MANEUVER STATES
#define MENU_STATE 0
#define WALL_FOLLOWING_STATE 1
#define TAPE_FOLLOW_DOWN_STATE 2
#define COLLECTION_STATE 3
#define TAPE_FOLLOW_UP_STATE 4
#define SECRET_LEVEL_STATE 5
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
int leftAngle = 0;
int rightAngle = 0;
bool leavingWall = false;
bool passedHomeBeacon = false;
// Tape Following
int qrdError = 0;
int qrdPreviousError = 0;
int qrdDeriveCounter = 1;
bool endFound = false;
// Collection
bool ballCollected = false;

// MENU ITEMS 
// Thresholds
MenuItem targetThreshold = MenuItem("T TH", TARGET_THRESHOLD);
MenuItem homeBeaconThreshold = MenuItem("HB TH", HOME_BEACON_THRESHOLD);
MenuItem ballCollectThreshold = MenuItem("Col TH", BALL_COLLECT_THRESHOLD);
MenuItem breakBeamThreshold = MenuItem("BB TH", BREAK_BEAM_THRESHOLD);
// QRD gains
MenuItem qrdProportionalGain = MenuItem("Q P-Gain", QRD_P_GAIN);
MenuItem qrdDerivativeGain = MenuItem("Q D-Gain", QRD_D_GAIN);
MenuItem rightStrafeGain = MenuItem("R S-Gain", RIGHT_STRAFE_GAIN);
// Motor speeds
MenuItem brushSpeed = MenuItem("Brush Vel", BRUSH_SPEED);
MenuItem firingSpeed = MenuItem("Fire Vel", FIRING_SPEED);
MenuItem bikeSpeed = MenuItem("Bike Vel", BIKE_SPEED);
MenuItem diffUpSpeed = MenuItem("Dif-U Vel", DIFF_UP_SPEED);
MenuItem diffDownSpeed = MenuItem("Dif-D Vel", DIFF_DOWN_SPEED);
// Servo angles
MenuItem servoLoadAngle = MenuItem("Load ang", SERVO_LOAD_ANGLE);
MenuItem servoCollectAngle = MenuItem("Col ang", SERVO_COLLECT_ANGLE);
MenuItem servoBikeAngle = MenuItem("Bike ang", SERVO_BIKE_ANGLE);
MenuItem servoDiffAngle = MenuItem("Dif ang", SERVO_DIFF_ANGLE);
MenuItem servoWallRearAngle = MenuItem("Rear ang", SERVO_WALL_REAR_ANGLE);
MenuItem servoWallFrontAngle = MenuItem("Front ang", SERVO_WALL_FRONT_ANGLE);

// Load menu items into an array
MenuItem items[] = 
{
	targetThreshold, homeBeaconThreshold, ballCollectThreshold, breakBeamThreshold,
	qrdProportionalGain, qrdDerivativeGain, 
	brushSpeed, firingSpeed, bikeSpeed, diffUpSpeed, diffDownSpeed, 
	servoLoadAngle, servoCollectAngle, servoBikeAngle, servoDiffAngle, servoWallRearAngle, servoWallFrontAngle
};
const int itemCount = 17; // must equal menu item array size

const int lcdRefreshPeriod = 30; // Update LCD screen every n iterations. Larger = fewer updates. Smaller = flicker
unsigned int lcdRefreshCount = 0; // Current iteration. Do not change this value

void setup()
{
	portMode(0, INPUT);       
	portMode(1, INPUT); 
	RCServo0.attach(RCServo0Output);
	RCServo1.attach(RCServo1Output);
	RCServo2.attach(RCServo2Output);

	// Random servo dance
	SetServo(BALL_SERVO, servoCollectAngle.Value());
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
	//	case TAPE_FOLLOW_UP_STATE:
	//	FollowTape(FOLLOW_UP_DIRECTION);
		break;
		case SECRET_LEVEL_STATE:
		SecretFiringLevel();
		break;
		default:
		Reset();
		Print("Error: no state"); LCD.setCursor(0,1);
		Print("???");
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
bool Microswitch(int microswitchPin, int debounceTime = 15)
{
	if(microswitchPin == LEFT_FRONT_MICROSWITCH_PIN || microswitchPin == RIGHT_FRONT_MICROSWITCH_PIN)
	{
		if(!digitalRead(microswitchPin)) return false;
		delay(debounceTime);
		return digitalRead(microswitchPin);
	}
	else
	{
		if(digitalRead(microswitchPin)) return false;
		delay(debounceTime);
		return !digitalRead(microswitchPin);
	}
}

// Updates the variables that track the wall following touch sensors
void UpdateWallFollowMicroswitches()
{
	leftSide = Microswitch(LEFT_SIDE_MICROSWITCH_PIN);
	rightSide = Microswitch(RIGHT_SIDE_MICROSWITCH_PIN);
	leftFront = Microswitch(LEFT_FRONT_MICROSWITCH_PIN);
	rightFront = Microswitch(RIGHT_FRONT_MICROSWITCH_PIN);
}

// Returns a bool indicating whether the given qrd is sensing a non-reflective surface
inline bool QRD(int qrdPin) {
	return !digitalRead(qrdPin);
}

// Returns a bool indicating whether the collection QRD is being triggered by a ball
bool Armed(int debounceTime = 15)
{
	if(analogRead(COLLECT_QRD_PIN) >= ballCollectThreshold.Value()) return false;
	delay(debounceTime);
	return (analogRead(COLLECT_QRD_PIN) < ballCollectThreshold.Value());
}

// Returns a bool indicating whether the laser break beam has been triggered
bool BreakBeam(int debounceTime = 15)
{
	if(analogRead(BREAK_BEAM_SENSOR_PIN) < breakBeamThreshold.Value()) return false;
	delay(debounceTime);
	return (analogRead(BREAK_BEAM_SENSOR_PIN) >= breakBeamThreshold.Value());
}

// Returns a bool indicating whether a target is detected
bool TargetAcquired(int debounceTime = 15)
{
	if(analogRead(TARGET_IR_PIN) < targetThreshold.Value()) return false;
	delay(debounceTime);
	return (analogRead(TARGET_IR_PIN) >= targetThreshold.Value());
}

// Returns a bool indicating whether the home beacon is detected
bool HomeBeaconAcquired(int debounceTime = 15)
{
	if(analogRead(HOME_BEACON_IR_PIN) < homeBeaconThreshold.Value()) return false;
	delay(debounceTime);
	return (analogRead(HOME_BEACON_IR_PIN) >= homeBeaconThreshold.Value());
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

	// Determine selected item and get knob values
	int knobValue = knob(VALUE_ADJUST_KNOB);
	int selectedItem = knob(MENU_ADJUST_KNOB) / (1024 / (itemCount + 2));
	if(selectedItem > itemCount + 1) selectedItem = itemCount + 1; // Normalize the selection

	Reset();

	// Display comparator board states
	if(selectedItem == itemCount)
	{
		Print("QRD: ");
		Print(QRD(OUTER_LEFT_QRD_PIN)); Print(QRD(INNER_LEFT_QRD_PIN));
		Print(QRD(INNER_RIGHT_QRD_PIN)); Print(QRD(OUTER_RIGHT_QRD_PIN));
		LCD.setCursor(0,1);
		Print("Switches: f");
		Print(Microswitch(LEFT_FRONT_MICROSWITCH_PIN,10)); Print(Microswitch(RIGHT_FRONT_MICROSWITCH_PIN,10));
		Print("s"); Print(Microswitch(LEFT_SIDE_MICROSWITCH_PIN,10)); Print(Microswitch(RIGHT_SIDE_MICROSWITCH_PIN,10));
		delay(100);
		return;
	}
	else if(selectedItem == itemCount + 1)
	{
		int selectedState = knobValue / 205 + 1;	// Allow user to select states 1-5 (not zero)
		Print("Current state: ", lastState); LCD.setCursor(0,1); 
		Print("Set to ", selectedState); Print(" ?");
		if(StopButton()) lastState = selectedState;
		delay(100);
		return;
	}

	// Display the item information
	Print(items[selectedItem].Name()); Print(" "); Print(items[selectedItem].Value());

	if(selectedItem == 0) Print(" ", analogRead(TARGET_IR_PIN));
	else if(selectedItem == 1) Print(" ", analogRead(HOME_BEACON_IR_PIN));
	else if(selectedItem == 2) Print(" ", analogRead(COLLECT_QRD_PIN));
	else if(selectedItem == 3) Print(" ", analogRead(BREAK_BEAM_SENSOR_PIN));

	LCD.setCursor(0,1);
	Print("Set to ", knobValue); Print("?");
	
	// Check to see if user set value
	if(StopButton(200)) items[selectedItem].SetValue(knobValue);
	delay(50);
}

void SecretFiringLevel()
{
	motor.speed(BRUSH_MOTOR_PIN, brushSpeed.Value());
	motor.speed(SHOOTING_MOTOR_PIN, firingSpeed.Value());

	Reset();
	Print("Arm: ", analogRead(COLLECT_QRD_PIN));
	LCD.setCursor(0,1);
	Print("IR:  ", analogRead(TARGET_IR_PIN));
	if(Armed())
	{
		delay(500);
		SetServo(BALL_SERVO, servoLoadAngle.Value());
		delay(1000);
	}
	else SetServo(BALL_SERVO, servoCollectAngle.Value());
	delay(100);
}

// When wall following, this updates the sensors to react to changes in the environment
void WallFollowSensorUpdate()
{
	UpdateWallFollowMicroswitches();
	if (!passedHomeBeacon && HomeBeaconAcquired()) passedHomeBeacon = true;

	// If no ball detected, debounce and then check again
	if(!leavingWall && !Armed() && !BreakBeam()) 
	{
		unsigned long startTime = millis();
		do
		{
			Reset(); Print("Ball lost!");
			delay(10);
		}
		while (!leavingWall && !Armed() && !BreakBeam() && (millis() < startTime + 1000)); 

		if (!Armed() && !BreakBeam()) 
			leavingWall = true;		
	}

	// If going left and hit left switch, or going right and hit right switch, then switch direction
	if ((leftSide && (strafeDirection == LEFT_DIRECTION)) || (rightSide && (strafeDirection == RIGHT_DIRECTION)))
		SwitchWallFollowDirection();
}

void SwitchWallFollowDirection()
{
	passedHomeBeacon = false; // Haven't seen home beacon since direction is reset
	strafeDirection *= -1; // Reverse strafing direction
	
	motor.stop(LEFT_MOTOR_PIN);
	motor.stop(RIGHT_MOTOR_PIN);
	delay(1000); // can lower later

	if (leftSide)
	{
		leftAngle = 180 - servoBikeAngle.Value() + servoWallRearAngle.Value();
		rightAngle = servoBikeAngle.Value() + servoWallFrontAngle.Value();
	}
	else if (rightSide)
	{
		leftAngle = 180 - servoBikeAngle.Value() - servoWallFrontAngle.Value();
		rightAngle = servoBikeAngle.Value() - servoWallRearAngle.Value();
	}

	SetServo(LEFT_SERVO, leftAngle);
	SetServo(RIGHT_SERVO, rightAngle);
	delay(SERVO_TRANSFORM_DELAY);
}

void WallFollow()
{
	WallFollowSensorUpdate();
	SetServo(BALL_SERVO, servoCollectAngle.Value());

	// End the wall following maneuver
	/*if(leavingWall)
	{
		if (passedHomeBeacon) SwitchWallFollowDirection();
		passedHomeBeacon = false; // Not strictly necessary but could prevent bugs later
		Reset();
		Print("Finding 10K IR");
		while (!HomeBeaconAcquired())
		{
			Strafe();
			WallFollowSensorUpdate();
			if (!leavingWall) return;
			if (StopButton(100)) return; // escape condition
		}
		Reset();
		Print("Found 10k bacon");
		AcquireTapeFromWall();
		maneuverState = TAPE_FOLLOW_DOWN_STATE;
		leavingWall = false;
		return;
	}*/

	if(TargetAcquired())
	{
		if(Armed()) Fire();
		else if (BreakBeam())
		{
			motor.stop(LEFT_MOTOR_PIN);
			motor.stop(RIGHT_MOTOR_PIN);
			// unsigned long startTime = millis();
			LCD.setCursor(0,1);
			Print("Cycling");
			while (!Armed() /*&& (millis() < startTime + BRUSH_LOAD_TIMEOUT_DELAY)*/)
			{	
				if (StopButton(100)) return; // escape condition
			}
			Fire();
		}
		lcdRefreshCount = 1;
	}
	Strafe();
}

// Strafes along front wall
void Strafe()
{
	// Engage collection, set strafing speeds
	motor.speed(BRUSH_MOTOR_PIN, brushSpeed.Value());
	motor.speed(LEFT_MOTOR_PIN, strafeDirection * bikeSpeed.Value());
	motor.speed(RIGHT_MOTOR_PIN, strafeDirection * bikeSpeed.Value() * (rightStrafeGain.Value() / 1000));

	if(strafeDirection == LEFT_DIRECTION)
	{
		leftAngle = 180 - servoBikeAngle.Value() - servoWallFrontAngle.Value();
		rightAngle = servoBikeAngle.Value() - servoWallRearAngle.Value();
	}
	else // strafeDirection == RIGHT_DIRECTION
	{
		leftAngle = 180 - servoBikeAngle.Value() + servoWallRearAngle.Value();
		rightAngle = servoBikeAngle.Value() + servoWallFrontAngle.Value();
	}

	SetServo(LEFT_SERVO, leftAngle);
	SetServo(RIGHT_SERVO, rightAngle);

	// Show steering information on screen
	if(lcdRefreshCount > 2) return;
	Reset();
	Print("Strafe ");
	Print((strafeDirection == LEFT_DIRECTION) ? "L " : "R ", analogRead(TARGET_IR_PIN));
}

void Fire() 
{
	if(!Armed()) return;
	// Disengage navigation and collection, engage firing
	motor.stop(BRUSH_MOTOR_PIN);
	
	//if (strafeDirection == LEFT_DIRECTION) motor.stop(LEFT_MOTOR_PIN);
	//else motor.stop(RIGHT_MOTOR_PIN);
	//delay(500);
	motor.stop(LEFT_MOTOR_PIN);
	motor.stop(RIGHT_MOTOR_PIN);
	motor.speed(SHOOTING_MOTOR_PIN, firingSpeed.Value());

	// Load firing mechanism
	LCD.setCursor(0,1);
	Print("Loading ball");
	SetServo(BALL_SERVO, servoLoadAngle.Value());
	
	while(Armed())
	{
		delay(10);
		if (StopButton(100)) return; // escape condition
	}
	SetServo(BALL_SERVO, servoCollectAngle.Value()); // return arm to collect position

	// Stop firing rotor motor
	delay(500); // Allow time for ball to shoot
	motor.stop(SHOOTING_MOTOR_PIN);
	motor.speed(BRUSH_MOTOR_PIN, brushSpeed.Value());
	delay(REBOUND_DELAY);
}

// Exectutes a controlled maneuver to exit the wall from a wall following position
void MoveOffWall()
{
	LCD.setCursor(0,1); Print("Backing off wall");

	// Engage collection and halt navigation
	motor.speed(BRUSH_MOTOR_PIN, brushSpeed.Value());
	motor.stop(LEFT_MOTOR_PIN); motor.stop(RIGHT_MOTOR_PIN);
	delay(500); // allow motors to come to a halt

	// Rotate servos
	SetServo(LEFT_SERVO, 180 - servoDiffAngle.Value()); 
	SetServo(RIGHT_SERVO, servoDiffAngle.Value());
	delay(SERVO_TRANSFORM_DELAY);

	// Make a controlled reverse
	motor.speed(LEFT_MOTOR_PIN, LEFT_DIFF_MULT * DIFF_REVERSE * diffDownSpeed.Value());
	motor.speed(RIGHT_MOTOR_PIN, RIGHT_DIFF_MULT * DIFF_REVERSE * diffDownSpeed.Value());
	Reset(); Print("Backing up");
	delay(MOVE_OFF_WALL_DELAY);

	// Make a controlled turn
	motor.speed(LEFT_MOTOR_PIN, diffDownSpeed.Value() * strafeDirection);
	motor.speed(RIGHT_MOTOR_PIN, diffDownSpeed.Value() * strafeDirection);
	Reset(); Print("135 deg turn");
	delay(TURN_135_DEG_DELAY);
}

void AcquireTapeFromWall()
{
	Reset();
	Print("Acquiring Tape");
	MoveOffWall();
	motor.speed(LEFT_MOTOR_PIN, LEFT_DIFF_MULT * diffDownSpeed.Value());
	motor.speed(RIGHT_MOTOR_PIN, RIGHT_DIFF_MULT * diffDownSpeed.Value());
	
	do
	{
		qrdInnerLeft = QRD(INNER_LEFT_QRD_PIN);
		qrdInnerRight = QRD(INNER_RIGHT_QRD_PIN);
		if (StopButton(100)) return; // escape condition
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
	SetServo(BALL_SERVO, servoCollectAngle.Value());
	SetServo(LEFT_SERVO, 180 - servoDiffAngle.Value());
	SetServo(RIGHT_SERVO, servoDiffAngle.Value());

	int baseSpeed = (followDirection == FOLLOW_UP_DIRECTION) ? diffUpSpeed.Value() : diffDownSpeed.Value();

	// If the end has been found,
	if(endFound && (followDirection == FOLLOW_DOWN_DIRECTION))
	{
		SquareTouch(diffDownSpeed.Value());					// square to collection wall
		maneuverState = COLLECTION_STATE;					// begin collection maneuver
		endFound = false;
		return;
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
	
	if (qrdError >= 0) 
	{
		motor.speed(LEFT_MOTOR_PIN, LEFT_DIFF_MULT * (-baseSpeed - compensationSpeed));
		motor.speed(RIGHT_MOTOR_PIN, RIGHT_DIFF_MULT * -baseSpeed);
	}
	else
	{
		motor.speed(LEFT_MOTOR_PIN, LEFT_DIFF_MULT * -baseSpeed);
		motor.speed(RIGHT_MOTOR_PIN, RIGHT_DIFF_MULT * (-baseSpeed + compensationSpeed));
	}

	// Keep track of differential gain
	if(qrdPreviousError != qrdError)
	{
		qrdPreviousError = qrdError;
		qrdDeriveCounter = 1;
	}
	else qrdDeriveCounter++;

	// Show steering information on screen
	if(lcdRefreshCount > 2) return;
	Reset();
	Print("Steering: ", compensationSpeed);
	LCD.setCursor(0, 1);
	Print("Error: ", qrdError);
}

void SquareTouch(int baseSpeed)
{
	Reset(); Print("Square touch");
	motor.speed(BRUSH_MOTOR_PIN, brushSpeed.Value()); // Engage collection
	
	do
	{
		leftFront = Microswitch(LEFT_FRONT_MICROSWITCH_PIN);
		rightFront = Microswitch(RIGHT_FRONT_MICROSWITCH_PIN);
		
		// Disengage motors when touching wall
		int leftSpeed = leftFront ? 0 : LEFT_DIFF_MULT * baseSpeed; 
		int rightSpeed = rightFront ? 0 : RIGHT_DIFF_MULT * baseSpeed;
		motor.speed(LEFT_MOTOR_PIN, -leftSpeed);
		motor.speed(RIGHT_MOTOR_PIN, -rightSpeed);

		if (StopButton(100)) return; // escape condition
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

	SetServo(BALL_SERVO, servoCollectAngle.Value());
	SetServo(LEFT_SERVO, 180 - servoDiffAngle.Value());
	SetServo(RIGHT_SERVO, servoDiffAngle.Value());

	if (ballCollected)
	{
		AcquireWallFromCollect();
		maneuverState = WALL_FOLLOWING_STATE;
		ballCollected = false;
	} else BumpCollect();
}

void BumpCollect()
{
	LCD.setCursor(0,1);	Print("Reversing...  ");

	// Engage collection and reverse navigation motors
	motor.speed(BRUSH_MOTOR_PIN, brushSpeed.Value()); // Engage collection	
	motor.speed(LEFT_MOTOR_PIN, LEFT_DIFF_MULT * DIFF_REVERSE * diffUpSpeed.Value());
	motor.speed(RIGHT_MOTOR_PIN, RIGHT_DIFF_MULT * DIFF_REVERSE * diffUpSpeed.Value());
	delay(COLLECTION_REVERSE_DELAY);

	// Disengage navigation motors
	motor.stop(LEFT_MOTOR_PIN); 
	motor.stop(RIGHT_MOTOR_PIN);

	delay(COLLECTION_DELAY);
	SquareTouch(diffDownSpeed.Value());
}

void AcquireWallFromCollect() 
{
	// Back up a certain distanced
	motor.speed(LEFT_MOTOR_PIN, LEFT_DIFF_MULT * DIFF_REVERSE * diffUpSpeed.Value());
	motor.speed(RIGHT_MOTOR_PIN, RIGHT_DIFF_MULT * DIFF_REVERSE * diffUpSpeed.Value());
	Reset(); Print("Backing up");
	delay(4 * COLLECTION_REVERSE_DELAY);

	// Stop Motors
	motor.stop(LEFT_MOTOR_PIN);
	motor.stop(RIGHT_MOTOR_PIN);
	delay(500);

	// Spin
	Reset(); Print("Turning");
//	motor.speed(LEFT_MOTOR_PIN, LEFT_DIFF_MULT * 1.5 * diffUpSpeed.Value());
//	motor.speed(RIGHT_MOTOR_PIN, RIGHT_DIFF_MULT * 1.5 * -diffUpSpeed.Value());
	motor.speed(LEFT_MOTOR_PIN, -800);
	motor.speed(RIGHT_MOTOR_PIN, -800);
	do
	{
		if(StopButton(100)) return; // Escape condition
	}
	while(!HomeBeaconAcquired(5));

	motor.stop(LEFT_MOTOR_PIN);
	motor.stop(RIGHT_MOTOR_PIN);
	delay(500);

	SquareTouch(diffUpSpeed.Value());

	// Disengage motors
	motor.stop(LEFT_MOTOR_PIN);
	motor.stop(RIGHT_MOTOR_PIN);
	Reset(); Print("Motors killed");
	delay(1000); // ARBITRARY
}

/*void AcquireWallFromTape() 
{
	Reset(); 
	Print("Tape ended,"); LCD.setCursor(0,1);
	Print("Finding Wall...");
	SquareTouch(diffUpSpeed.Value());

	if(strafeDirection == LEFT_DIRECTION)
	{
		leftAngle = 180 - servoBikeAngle.Value() - servoWallFrontAngle.Value();
		rightAngle = servoBikeAngle.Value() - servoWallRearAngle.Value();
	}
	else // strafeDirection == RIGHT_DIRECTION
	{
		leftAngle = 180 - servoBikeAngle.Value() + servoWallRearAngle.Value();
		rightAngle = servoBikeAngle.Value() + servoWallFrontAngle.Value();
	}

	SetServo(LEFT_SERVO, leftAngle);
	SetServo(RIGHT_SERVO, rightAngle);

	delay(SERVO_TRANSFORM_DELAY);
}*/