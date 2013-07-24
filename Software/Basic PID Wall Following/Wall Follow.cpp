
#include <phys253.h>      
#include <LiquidCrystal.h>
#include <Servo253.h> 
#include <EEPROM.h>

// Parameters
#define SPEED 0
#define PROPORTIONAL_GAIN 1
#define DERIVATIVE_GAIN 2
#define INTEGRAL_GAIN 3
#define THRESHOLD_LEFT 4
#define THRESHOLD_RIGHT 5
#define PERPENDICULAR 6
#define TURN_COMPENSATION 7

// Pin Definitions
#define MENU_ADJUST_KNOB 6
#define VALUE_ADJUST_KNOB 7
#define LEFT_SENSOR 0
#define RIGHT_SENSOR 1
#define LEFT_MOTOR 0
#define RIGHT_MOTOR 1
#define LEFT_BUMPER 13
#define RIGHT_BUMPER 15

// States
#define TOO_CLOSE 1.0
#define TOO_FAR -1.0

// Directions
#define LEFT 1
#define RIGHT -1

int direction = LEFT;
int left = 0;
int right = 0;
int previousError = 0;
int deriveCount = 1;
float integral = 0.0;
int error = 0;
bool leftDetected = false;
bool rightDetected = false;

int integralOffsetPeriod = 50;
int integralOffsetCounter = integralOffsetPeriod;

// Tuning parameters. These are saved to EEPROM
float speed = EEPROM.read(SPEED) * 4; // Max EEPROM value is 255. Multiplies by 4 to get up to ~1000 with fidelity tradeoff
float proportionalGain = EEPROM.read(PROPORTIONAL_GAIN) * 4;
float derivativeGain = EEPROM.read(DERIVATIVE_GAIN) * 4;
float integralGain = EEPROM.read(INTEGRAL_GAIN) * 4;
float thresholdLeft = EEPROM.read(THRESHOLD_LEFT) * 4;
float thresholdRight = EEPROM.read(THRESHOLD_RIGHT) * 4;
float perpendicular = EEPROM.read(PERPENDICULAR) * 4;
float turnCompensationGain = EEPROM.read(TURN_COMPENSATION) * 4;
float boostAngle = 5.0;

// State tracking
bool MENU = true;
int lcdRefreshPeriod = 200; // Update LCD screen every n iterations. Larger = fewer updates. Smaller = flicker
int lcdRefreshCount = 0; // Current iteration. Do not change this value

void setup()
{
	portMode(0, INPUT) ;      //   ***** from 253 template file
	portMode(1, INPUT) ;      //   ***** from 253 template file
	RCServo0.attach(RCServo0Output) ;
	RCServo1.attach(RCServo1Output) ;
	RCServo2.attach(RCServo2Output) ;
}

void loop()
{
	Update();
	if (MENU) ProcessMenu();
	else ProcessMovement();
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

// Determines if the bumper switch is being contacted
bool LeftBumper(int debounceTime = 15)
{
	if(digitalRead(LEFT_BUMPER)) return false;
	delay(debounceTime);
	return !digitalRead(LEFT_BUMPER);
}

bool RightBumper(int debounceTime = 15)
{
	if(digitalRead(RIGHT_BUMPER)) return false;
	delay(debounceTime);
	return !digitalRead(RIGHT_BUMPER);
}

// Polls the inputs and obtains new sensor readings. 
// Updates LED indicators and detects button presses
void Update()
{
	// Gets new sensor readings
	left = analogRead(LEFT_SENSOR);
	right = analogRead(RIGHT_SENSOR);
	leftDetected = left < thresholdLeft;
	rightDetected = right < thresholdRight;

	// Detects button presses and decrements the LCD counter
	if(StopButton()) MENU = true;
	if(StartButton()) MENU = false;
	lcdRefreshCount = (lcdRefreshCount <= 0) ? lcdRefreshPeriod : (lcdRefreshCount - 1);

	// Reverse direction if bumper pressed
	if(LeftBumper()) direction = RIGHT;
	else if (RightBumper()) direction = LEFT;
}


// Computes new PID values and calculates a new motor speed for
// the left and right motors. Prints motor and sensor values to LCD.
void ProcessMovement()
{


	// Determine the error for correct direction
	if (direction == LEFT) error = leftDetected ? TOO_CLOSE : TOO_FAR;
	else if (direction == RIGHT) error = rightDetected ? TOO_CLOSE : TOO_FAR;

	// Integral calculations
	if (integralOffsetCounter < 0)
	{
		integral += error * integralGain;
		integralOffsetCounter = integralOffsetPeriod;
	}
	else integralOffsetCounter--;
	if (integral > 25.0) integral = 25.0;
	else if (integral < -25.0) integral = -25.0;
	
	// PID calculations
	float proportional = (float)error * proportionalGain;
	float derivative = (float)(error - previousError) / (float)deriveCount * derivativeGain;
	int compensationAngle = proportional + integral + derivative;
	if(previousError != error)
	{
		previousError = error;
		deriveCount = 1;
	}
	else deriveCount++;

	// Set new servo angles
	if (direction == LEFT)
	{
		RCServo1.write(perpendicular - compensationAngle);
		RCServo2.write(perpendicular + boostAngle);
	}
	else
	{
		RCServo1.write(perpendicular - boostAngle);
		RCServo2.write(perpendicular + compensationAngle);
	}

	// Compute turning speed compensation
	int turnCompensation = abs(compensationAngle) * turnCompensationGain * direction;

	motor.speed(LEFT_MOTOR, (speed * direction) + turnCompensation);
	motor.speed(RIGHT_MOTOR, (speed * direction) + turnCompensation);

	// Draw data on screen
	if(lcdRefreshCount != 0) return;
	LCD.clear(); LCD.home();
	LCD.print("L:"); LCD.print(left); LCD.print(" R:"); LCD.print(right); // Print sensor readings
	LCD.setCursor(0, 1);
	LCD.print("Direction: "); LCD.print(direction == LEFT ? "LEFT" : "RIGHT");
}

// Displays a tuning parameter on the LCD
void ProcessMenu()
{
	motor.stop_all();
	int debounceTime = 200;
	int knobValue = knob(VALUE_ADJUST_KNOB);
	LCD.clear(); LCD.setCursor(0,1);
	LCD.print("Set to "); LCD.print(knobValue); LCD.print("?");
	LCD.home();

	int menuItem = knob(MENU_ADJUST_KNOB) / 100; // Divides by 1 to reduce possible values to something like 10
	switch (menuItem)
	{
		case SPEED:
		LCD.print("Speed: ");
		LCD.print(speed);
		if (!StopButton(debounceTime)) break;
		speed = knobValue ;
		EEPROM.write(SPEED, speed / 4); // divide by four to prevent overflow (EEPROM max is 255)
		break;
		case PROPORTIONAL_GAIN:
		LCD.print("P Gain: ");
		LCD.print(proportionalGain);
		if (!StopButton(debounceTime)) break;
		proportionalGain = knobValue;
		EEPROM.write(PROPORTIONAL_GAIN, proportionalGain/4);
		break;
		case DERIVATIVE_GAIN:
		LCD.print("D Gain: ");
		LCD.print(derivativeGain);
		if (!StopButton(debounceTime)) break;
		derivativeGain = knobValue;
		EEPROM.write(DERIVATIVE_GAIN, derivativeGain/4);
		break;
		case INTEGRAL_GAIN:
		LCD.print("I Gain: ");
		LCD.print(integralGain);
		if (!StopButton(debounceTime)) break;
		integralGain = knobValue;
		EEPROM.write(INTEGRAL_GAIN, integralGain/4);
		break;
		case THRESHOLD_LEFT:
		LCD.print("TH L: ");
		LCD.print((int)thresholdLeft);
		LCD.print(" ");
		LCD.print(left);
		if (!StopButton(debounceTime)) break;
		thresholdLeft = knobValue;
		EEPROM.write(THRESHOLD_LEFT, thresholdLeft / 4);
		break;
		case THRESHOLD_RIGHT:
		LCD.print("TH R: ");
		LCD.print((int)thresholdRight);
		LCD.print(" ");
		LCD.print(right);
		if (!StopButton(debounceTime)) break;
		thresholdRight = knobValue;
		EEPROM.write(THRESHOLD_RIGHT, thresholdRight / 4);
		break;
		case PERPENDICULAR:
		LCD.print("PERP: ");
		LCD.print((int)perpendicular);
		if (!StopButton(debounceTime)) break;
		perpendicular = knobValue;
		EEPROM.write(PERPENDICULAR, perpendicular /4 );
		break;
		case TURN_COMPENSATION:
		LCD.print("COMP: ");
		LCD.print((int)turnCompensationGain);
		if (!StopButton(debounceTime)) break;
		turnCompensationGain = knobValue;
		EEPROM.write(TURN_COMPENSATION, turnCompensationGain /4 );
		break;
		default:
		LCD.print("PERP: ");
		LCD.print((int)perpendicular);
		if (!StopButton(debounceTime)) break;
		perpendicular = knobValue;
		EEPROM.write(PERPENDICULAR, perpendicular / 4);
		break;
	}
	delay(30); // Pauses to prevent screen flicker
}
