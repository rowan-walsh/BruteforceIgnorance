
#include "WProgram.h"
#include "QrdSensor.h"

QrdSensor::QrdSensor() 
{
}

// Defines the pin and threshold for the Qrd sensor
void QrdSensor::Attach(int sensorPin)
{
	pin = sensorPin;
}

// Indicates whether the sensor is detecting tape
bool QrdSensor::TapeDetected()
{
	return !digitalRead(pin);
}

// Returns the raw digital value of the sensor
int QrdSensor::Value()
{
	return digitalRead(pin);
}