
#include <phys253.h>      
#include <LiquidCrystal.h>
#include <Servo253.h> 
#include <EEPROM.h>

// Parameters
#define SPEED 0
#define PROPORTIONAL_GAIN 1
#define DERIVATIVE_GAIN 2
#define THRESHOLD 3
#define PERPENDICULAR 4

// Pin Definitions
#define MENU_ADJUST_KNOB 6
#define VALUE_ADJUST_KNOB 7
#define LEFT_SENSOR 0
#define RIGHT_SENSOR 1
#define LEFT_MOTOR 1
#define RIGHT_MOTOR 3
#define LEFT_LED 7
#define RIGHT_LED 5
#define ERROR_LED 6
#define LEFT_BUMPER 14
#define RIGHT_BUMPER 13

// States
#define TOO_CLOSE -1.0
#define TOO_FAR 1.0

// Directions
#define LEFT -1
#define RIGHT 1

int direction = LEFT;
int left = 0;
int right = 0;
int previousLeftError = 0;
int previousRightError = 0;
int leftError = 0;
int rightError = 0;
bool leftDetected = false;
bool rightDetected = false;

// Tuning parameters. These are saved to EEPROM
float speed = EEPROM.read(SPEED) * 4; // Max EEPROM value is 255. Multiplies by 4 to get up to ~1000 with fidelity tradeoff
float proportionalGain = EEPROM.read(PROPORTIONAL_GAIN);
float derivativeGain = EEPROM.read(DERIVATIVE_GAIN);
float threshold = EEPROM.read(THRESHOLD) * 2;
float perpendicular = EEPROM.read(PERPENDICULAR);

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
	leftDetected = left > threshold;
	rightDetected = right > threshold;

	// Updates the LED tape-detect indicators. Pin logic is inverted
	digitalWrite(LEFT_LED, !leftDetected);
	digitalWrite(RIGHT_LED, !rightDetected);
	digitalWrite(ERROR_LED, !((!leftDetected) && (!rightDetected)));

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
	motor.speed(LEFT_MOTOR, speed * direction);
	motor.speed(RIGHT_MOTOR, speed * direction);

	if (direction == LEFT) 
	{
		leftError = leftDetected ? TOO_CLOSE : TOO_FAR;
		float leftProportional = (float)leftError * proportionalGain;
		float leftDerivative = (float)(leftError - previousLeftError) * derivativeGain;
		previousLeftError = leftError;

		RCServo0.write(perpendicular - (leftProportional + leftDerivative));
		RCServo1.write(perpendicular);

	}
	else if (direction == RIGHT)
	{
		rightError = rightDetected ? TOO_CLOSE : TOO_FAR;
		float rightProportional = (float)rightError * proportionalGain;
		float rightDerivative = (float)(rightError - previousRightError) * derivativeGain;
		previousRightError = rightError;

		RCServo0.write(perpendicular);
		RCServo1.write(perpendicular + (rightProportional + rightDerivative));
	}

	if(lcdRefreshCount != 0) return;
	LCD.clear(); LCD.home();
	LCD.print("L:"); LCD.print(left); LCD.print(" R:"); LCD.print(right); // Print sensor readings
	LCD.setCursor(0, 1);
	//LCD.print("L:"); LCD.print((int)perpendicular - (int)(leftProportional + leftDerivative));
	//LCD.print(" R:"); LCD.print((int)perpendicular - (int)(rightProportional + rightDerivative));
	LCD.print("Direction: "); LCD.print(direction == LEFT ? "LEFT" : "RIGHT");
}

// Displays a tuning parameter on the LCD
void ProcessMenu()
{
	motor.stop_all();
	int debounceTime = 200;
	int knobValue = knob(VALUE_ADJUST_KNOB) / 4;
	LCD.clear(); LCD.setCursor(0,1);
	LCD.print("Set to "); LCD.print(knobValue); LCD.print("?");
	LCD.home();

	int menuItem = knob(MENU_ADJUST_KNOB) / 200; // Divides by 256 to reduce possible values
	switch (menuItem)
	{
	case SPEED:
		LCD.print("Speed: ");
		LCD.print(speed);
		if (!StopButton(debounceTime)) break;
		speed = knobValue * 4;
		EEPROM.write(SPEED, speed / 4); // divide by four to prevent overflow (EEPROM max is 255)
		break;
	case PROPORTIONAL_GAIN:
		LCD.print("P Gain: ");
		LCD.print(proportionalGain);
		if (!StopButton(debounceTime)) break;
		proportionalGain = knobValue;
		EEPROM.write(PROPORTIONAL_GAIN, proportionalGain);
		break;
	case DERIVATIVE_GAIN:
		LCD.print("D Gain: ");
		LCD.print(derivativeGain);
		if (!StopButton(debounceTime)) break;
		derivativeGain = knobValue;
		EEPROM.write(DERIVATIVE_GAIN, derivativeGain);
		break;
	case THRESHOLD:
		LCD.print("TH: ");
		LCD.print((int)threshold);
		LCD.print(" ");
		LCD.print(left);
		LCD.print(" ");
		LCD.print(right);
		if (!StopButton(debounceTime)) break;
		threshold = knobValue * 2;
		EEPROM.write(THRESHOLD, threshold / 2);
		break;
	case PERPENDICULAR:
		LCD.print("PERP: ");
		LCD.print((int)perpendicular);
		if (!StopButton(debounceTime)) break;
		perpendicular = knobValue;
		EEPROM.write(PERPENDICULAR, perpendicular);
		break;
	default:
		LCD.print("PERP: ");
		LCD.print((int)perpendicular);
		if (!StopButton(debounceTime)) break;
		perpendicular = knobValue;
		EEPROM.write(PERPENDICULAR, perpendicular);
		break;
	}
	delay(30); // Pauses to prevent screen flicker
}
