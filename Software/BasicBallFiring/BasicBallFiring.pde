
#include <phys253.h>      
#include <LiquidCrystal.h>
#include <Servo253.h> 
#include <EEPROM.h>

// Pin Definitions
#define MENU_ADJUST_KNOB 6
#define VALUE_ADJUST_KNOB 7
#define QRD_SENSOR 5
#define BRUSH_MOTOR 2
#define SHOOTING_MOTOR 3

// EEPROM addresses
#define BRUSH_SPEED 0
#define SHOOTING_SPEED 1
#define THRESHOLD 2
#define UNLOAD_ANGLE 3
#define LOAD_ANGLE 4

// Stored values. These are saved to and retrieved from EEPROM
// Values are multiplied by four to increase maximum possible value (255 max otherwise)
float brushSpeed = EEPROM.read(BRUSH_SPEED) * 4;  
float shootingSpeed = EEPROM.read(SHOOTING_SPEED) * 4;
float threshold = EEPROM.read(THRESHOLD) * 4;
int unloadAngle = EEPROM.read(UNLOAD_ANGLE) * 4;
int loadAngle = EEPROM.read(LOAD_ANGLE) * 4;

// State tracking
bool MENU = true;
bool armed = false;
int ballDetectionQrd = 0;
int lcdRefreshPeriod = 200; // Update LCD screen every n iterations. Larger = fewer updates. Smaller = flicker
int lcdRefreshCount = 0; // Current iteration. Do not change this value

// Ball loading servo is RCServo0

void setup()
{
	portMode(0, INPUT) ;      
	portMode(1, INPUT) ;   
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
	else Process();
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
	ballDetectionQrd= analogRead(QRD_SENSOR);
	armed = ballDetectionQrd > threshold; // This may require debounce if psuedorandom firing occurs

	// Detects button presses and decrements the LCD counter
	if(StopButton()) MENU = true;
	if(StartButton()) MENU = false;
	lcdRefreshCount = (lcdRefreshCount <= 0) ? lcdRefreshPeriod : (lcdRefreshCount - 1);
}

void Process()
{
	// Set motor speeds
	motor.speed(BRUSH_MOTOR, brushSpeed);
	motor.speed(SHOOTING_MOTOR, shootingSpeed);

	// Fire ball if loaded
	if (armed) 
	{
		RCServo1.write(loadAngle);
		RCServo2.write(loadAngle);
RCServo0.write(loadAngle);
	}
	else
	{
		RCServo1.write(unloadAngle);
		RCServo2.write(unloadAngle);
		RCServo0.write(unloadAngle);

	} 

	// Update LCD with values	
	if(lcdRefreshCount != 0) return; // Mitigates screen flicker
	LCD.clear(); LCD.home();
	LCD.print("Detect: "); LCD.print(ballDetectionQrd);	
	LCD.setCursor(0, 1);
}

// Displays a tuning parameter on the LCD
void ProcessMenu()
{
	motor.stop_all();
	int knobValue = knob(VALUE_ADJUST_KNOB);
	LCD.clear(); LCD.setCursor(0,1);
	LCD.print("Set to "); LCD.print(knobValue); LCD.print("?");
	LCD.home();

	int menuItem = knob(MENU_ADJUST_KNOB) / (1023.0/5.0); // Divides to constrain possible values
	switch (menuItem)
	{
	case BRUSH_SPEED:
		LCD.print("Brush Vel: ");
		LCD.print(brushSpeed);
		if (!StopButton()) break;
		brushSpeed = knobValue;
		EEPROM.write(BRUSH_SPEED, brushSpeed / 4); // divide by four to prevent overflow (EEPROM max is 255)
		break;
	case SHOOTING_SPEED:
		LCD.print("Shoot Vel: ");
		LCD.print(shootingSpeed);
		if (!StopButton()) break;
		shootingSpeed = knobValue;
		EEPROM.write(SHOOTING_SPEED, shootingSpeed / 4); // divide by four to prevent overflow (EEPROM max is 255)
		break;
	case THRESHOLD:
		LCD.print("TH: ");
		LCD.print((int)threshold);
		LCD.print(" ");
		LCD.print(ballDetectionQrd);
		if (!StopButton()) break;
		threshold = knobValue;
		EEPROM.write(THRESHOLD, threshold);
		break;
	case LOAD_ANGLE:
		LCD.print("Load Ang: ");
		LCD.print(loadAngle);
		if (!StopButton()) break;
		loadAngle = knobValue;
		EEPROM.write(LOAD_ANGLE, loadAngle / 4); // divide by four to prevent overflow (EEPROM max is 255)
		break;
	case UNLOAD_ANGLE:
		LCD.print("Collect ang: ");
		LCD.print(unloadAngle);
		if (!StopButton()) break;
		unloadAngle = knobValue;
		EEPROM.write(UNLOAD_ANGLE, unloadAngle / 4); // divide by four to prevent overflow (EEPROM max is 255)
		break;
	default:
		LCD.print("Collect ang: ");
		LCD.print(unloadAngle);
		if (!StopButton()) break;
		unloadAngle = knobValue;
		EEPROM.write(UNLOAD_ANGLE, unloadAngle / 4); // divide by four to prevent overflow (EEPROM max is 255)
		break;
	}
	delay(30); // Pauses to prevent screen flicker
}
