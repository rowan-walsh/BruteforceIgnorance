#include <phys253.h>      
#include <LiquidCrystal.h>
#include <Servo253.h> 
#include <EEPROM.h>

// Parameters
#define SPEED 0
#define PROPORTIONAL_GAIN 1
#define DERIVATIVE_GAIN 2
#define THRESHOLD 3

// Pin Definitions
#define MENU_ADJUST_KNOB 6
#define VALUE_ADJUST_KNOB 7
#define LEFT_SENSOR 0
#define RIGHT_SENSOR 1
#define LEFT_MOTOR 0
#define RIGHT_MOTOR 1

// Tape States
#define TOO_LEFT -1.0
#define TOO_RIGHT 1.0
#define OFF_TAPE 5.0

// Sensor Values
int left = 0;
int right = 0; 
int previousError = 0;
int error = 0;
bool leftDetected = false;
bool rightDetected = false;

// Tuning parameters. These are saved to EEPROM
float speed = EEPROM.read(SPEED) * 4; // Max EEPROM value is 255. Multiplies by 4 to get up to ~1000 with fidelity tradeoff
float proportionalGain = EEPROM.read(PROPORTIONAL_GAIN);
float derivativeGain = EEPROM.read(DERIVATIVE_GAIN);
float threshold = EEPROM.read(THRESHOLD);

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
		RCServo0.write(0);
		RCServo1.write(0);
		RCServo2.write(0);
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
}

// Computes new PID values and calculates a new motor speed for
// the left and right motors. Prints motor and sensor values to LCD.
void ProcessMovement()
{
	if (leftDetected && rightDetected) error = 0;
	else if (!leftDetected && rightDetected) error = TOO_LEFT;
	else if (leftDetected && !rightDetected) error = TOO_RIGHT;
	else if (!leftDetected && !rightDetected) error = (previousError <= TOO_LEFT) ? -OFF_TAPE : OFF_TAPE;
	
	float proportional = (float)error * proportionalGain;
	float derivative = (float)(error - previousError) * derivativeGain;
	motor.speed(LEFT_MOTOR, speed + (proportional + derivative));
	motor.speed(RIGHT_MOTOR, speed - (proportional + derivative));
	previousError = error;

	if(lcdRefreshCount != 0) return; // Mitigates screen flicker
	LCD.clear(); LCD.home();
	LCD.print("L:"); LCD.print(left); LCD.print(" R:"); LCD.print(right); // Print sensor readings
	LCD.setCursor(0, 1);
	LCD.print("L:"); LCD.print((int)speed - (int)(proportional + derivative));
	LCD.print(" R:"); LCD.print((int)speed + (int)(proportional + derivative));
}

// Displays a tuning parameter on the LCD
void ProcessMenu()
{
	motor.stop_all();
	int knobValue = knob(VALUE_ADJUST_KNOB) / 4;
	LCD.clear(); LCD.setCursor(0,1);
	LCD.print("Set to "); LCD.print(knobValue); LCD.print("?");
	LCD.home();

	int menuItem = knob(MENU_ADJUST_KNOB) / 256; // Divides by 256 to reduce possible values
	switch (menuItem)
	{
	case SPEED:
		LCD.print("Speed: ");
		LCD.print(speed);
		if (!StopButton()) break;
		speed = knobValue * 4;
		EEPROM.write(SPEED, speed / 4); // divide by four to prevent overflow (EEPROM max is 255)
		break;
	case PROPORTIONAL_GAIN:
		LCD.print("P Gain: ");
		LCD.print(proportionalGain);
		if (!StopButton()) break;
		proportionalGain = knobValue;
		EEPROM.write(PROPORTIONAL_GAIN, proportionalGain);
		break;
	case DERIVATIVE_GAIN:
		LCD.print("D Gain: ");
		LCD.print(derivativeGain);
		if (!StopButton()) break;
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
		if (!StopButton()) break;
		threshold = knobValue;
		EEPROM.write(THRESHOLD, threshold);
		break;
	default: // Selects threshold by default
		LCD.print("TH: ");
		LCD.print((int)threshold);
		LCD.print(" ");
		LCD.print(left);
		LCD.print(" ");
		LCD.print(right);
		if (!StopButton()) break;
		threshold = knobValue;
		EEPROM.write(THRESHOLD, threshold);
		break;
	}
	delay(30); // Pauses to prevent screen flicker
}
