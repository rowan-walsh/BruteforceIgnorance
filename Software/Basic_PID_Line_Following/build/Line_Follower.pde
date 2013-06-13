
#include <phys253.h>      
#include <LiquidCrystal.h>
#include <Servo253.h> 
#include <EEPROM.h>

// Parameters
#define SPEED 0
#define PROPORTIONAL_GAIN 1
#define DERIVATIVE_GAIN 2
#define THRESHOLD 3

// Pins
#define MENU_ADJUST_KNOB 6
#define VALUE_ADJUST_KNOB 7
#define LEFT_SENSOR 0
#define RIGHT_SENSOR 1
#define LEFT_MOTOR 1
#define RIGHT_MOTOR 3
#define LEFT_LED 7
#define RIGHT_LED 5
#define ERROR_LED 6

// Tape States
#define TOO_LEFT -1.0
#define TOO_RIGHT 1.0
#define OFF_TAPE 5.0

// Values
int left = 0;
int right = 0;
int previousError = 0;
int error = 0;

// Parameters
float speed = EEPROM.read(SPEED) * 4;
float proportionalGain = EEPROM.read(PROPORTIONAL_GAIN);
float derivativeGain = EEPROM.read(DERIVATIVE_GAIN);
float threshold = EEPROM.read(THRESHOLD);

// States
bool MENU = true;

void setup()
{

}

void loop()
{
	Update();
	if (MENU) ProcessMenu();
	else ProcessMovement();
	delay(20);
}

void Update()
{
	left = analogRead(LEFT_SENSOR);
	right = analogRead(RIGHT_SENSOR);
	digitalWrite(LEFT_LED, left < threshold);
	digitalWrite(RIGHT_LED, right < threshold);
	digitalWrite(ERROR_LED, !((left < threshold) && (right < threshold)));
	if(stopbutton()) 
	{
		delay(20);
		if(stopbutton()) MENU = true;
		
	}
	else if(startbutton())
	{ 
		delay(20);
		if(!startbutton()) MENU = false;
	}	
}

void ProcessMovement()
{
	ShowSensorValues();
	if ((left > threshold) && (right > threshold)) error = 0;
	else if ((left < threshold) && (right > threshold)) error = TOO_LEFT;
	else if ((left > threshold) && (right < threshold)) error = TOO_RIGHT;
	
	if ((left < threshold) && (right < threshold))
		if (previousError <= TOO_LEFT) error = OFF_TAPE * -1;
		else error = OFF_TAPE;
	float proportional = (float)error * proportionalGain;
	float derivative = (float)(error - previousError) * derivativeGain;

	motor.speed(LEFT_MOTOR, speed + (proportional + derivative));
	motor.speed(RIGHT_MOTOR, speed - (proportional + derivative));
	LCD.setCursor(0, 1);
	LCD.print("L:"); LCD.print(speed - (proportional + derivative));
	LCD.print(" R:"); LCD.print(speed + (proportional + derivative));
	previousError = error;
}

void ProcessMenu()
{
	motor.stop_all();
	int knobValue = knob(VALUE_ADJUST_KNOB) / 4;
	LCD.clear(); LCD.setCursor(0,1);
	LCD.print("Set to "); LCD.print(knobValue); LCD.print("?");
	LCD.home();

	int menuItem = knob(MENU_ADJUST_KNOB) / 255;
	switch (menuItem)
	{
	case SPEED:
		LCD.print("Speed: ");
		LCD.print(speed);
		if (!stopbutton()) break;
		delay(10);
		if (!stopbutton()) break;
		speed = knobValue * 4;
		EEPROM.write(SPEED, speed / 4);
		break;
	case PROPORTIONAL_GAIN:
		LCD.print("P Gain: ");
		LCD.print(proportionalGain);
		if (!stopbutton()) break;
		delay(10);
		if (!stopbutton()) break;
		proportionalGain = knobValue;
		EEPROM.write(PROPORTIONAL_GAIN, proportionalGain);
		break;
	case DERIVATIVE_GAIN:
		LCD.print("D Gain: ");
		LCD.print(derivativeGain);
		if (!stopbutton()) break;
		delay(10);
		if (!stopbutton()) break;
		derivativeGain = knobValue;
		EEPROM.write(DERIVATIVE_GAIN, derivativeGain);
		break;
	case THRESHOLD:
		LCD.print("Thresh");
		LCD.print((int)threshold);
		LCD.print(" ");
		LCD.print(left);
		LCD.print(" ");
		LCD.print(right);
		if (!stopbutton()) break;
		delay(10);
		if (!stopbutton()) break;
		threshold = knobValue;
		EEPROM.write(THRESHOLD, threshold);
		break;
	default:
		LCD.print("Thresh");
		LCD.print((int)threshold);
		LCD.print(" ");
		LCD.print(left);
		LCD.print(" ");
		LCD.print(right);
		if (!stopbutton()) break;
		delay(10);
		if (!stopbutton()) break;
		threshold = knobValue;
		EEPROM.write(THRESHOLD, threshold);
		break;
	}
}

void ShowSensorValues()
{
	LCD.clear();
	LCD.home();
	LCD.print("L:");
	LCD.print(left);
	LCD.print(" R:");
	LCD.print(right);
}
