#include <phys253.h>      
#include <LiquidCrystal.h>
#include <Servo253.h> 
#include <EEPROM.h>

// PIN DECLARATIONS
// Analog Inputs
#define LEFT_LASER_PIN 0
#define RIGHT_LASER_PIN 1
#define COLLECT_QRD_PIN 2
#define TARGET_DETECT_PIN_LEFT 3
#define TARGET_DETECT_PIN_RIGHT 4
#define VALUE_ADJUST_KNOB 7
// Digital Inputs
#define LEFT_SIDE_MICROSWITCH_PIN 13
#define LEFT_FRONT_MICROSWITCH_PIN 12
#define RIGHT_SIDE_MICROSWITCH_PIN 15
#define RIGHT_FRONT_MICROSWITCH_PIN 14
#define LEFT_QRD_PIN 10
#define RIGHT_QRD_PIN 11

bool StartButton(int debounceTime = 80)
{
	if(!startbutton()) return false;
	delay(debounceTime);
	return startbutton();
}

void setup()
{
	portMode(0, INPUT) ;
	portMode(1, INPUT) ;
	RCServo0.attach(RCServo0Output) ;
	RCServo1.attach(RCServo1Output) ;
	RCServo2.attach(RCServo2Output) ;
	RCServo0.write(90);
	RCServo1.write(90);
	RCServo2.write(90);
}

void loop()
{
	MotorTest();
	ServoTest();
	DigitalInputTest();
	AnalogInputTest();

}

void MotorTest()
{
	Reset();
	Print("Motor test");
	for (int i = 0; i <= 4; i++) 
		motor.speed(i, 500);
	while(!StartButton()) 
		delay(10);
	motor.stop_all();
}

void ServoTest()
{
	Reset();
	Print("Servo motors");
	delay(700);
	while(!StartButton())
	{
		int angle = knob(VALUE_ADJUST_KNOB);
		angle = (int)((float)angle * (float)0.17578125);
		if (angle > 180) angle = 180;
		if (angle < 0) angle = 0;
		Reset();
		Print("Angle: ", angle);
		RCServo0.write(angle);
		RCServo1.write(angle);
		RCServo2.write(angle);
		delay(50);
		if (StartButton()) break;
	}
}

void DigitalInputTest()
{
	Reset();
	Print("Digital Inputs");
	delay(700);
	while(!StartButton())
	{
		Reset();
		Print("F", digitalRead(LEFT_FRONT_MICROSWITCH_PIN));
		Print("S", digitalRead(LEFT_SIDE_MICROSWITCH_PIN));
		Print(" F", digitalRead(RIGHT_FRONT_MICROSWITCH_PIN));
		Print("S", digitalRead(RIGHT_SIDE_MICROSWITCH_PIN));
		LCD.setCursor(0,1);
		Print("QL:", digitalRead(LEFT_QRD_PIN));
		Print(" QR:", digitalRead(RIGHT_QRD_PIN));
		delay(50);
	}
}

void AnalogInputTest()
{
	Print("Analog Inputs");
	delay(700);
	while(!StartButton())
	{
		Reset();
		Print("L1:", analogRead(LEFT_LASER_PIN));
		Print(" L2:", analogRead(RIGHT_LASER_PIN));
		LCD.setCursor(0,1);
		Print("QRD:", analogRead(COLLECT_QRD_PIN));
		Print(" 1K:", analogRead(TARGET_DETECT_PIN));
		delay(50);
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