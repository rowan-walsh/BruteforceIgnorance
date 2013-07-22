
#include "WProgram.h"
#include "LaserSensor.h"

LaserSensor::LaserSensor() 
{
}

// Defines the pin and threshold for the laser sensor
void LaserSensor::Attach(int sensorPin, int sensorThreshold)
{
	pin = sensorPin;
	threshold = sensorThreshold;
}

// Sets the arbitrary threshold of the laser sensor
void LaserSensor::SetThreshold(int sensorThreshold)
{
	threshold = sensorThreshold;
}

// Indicates whether the sensor is above threshold
bool LaserSensor::AboveThreshold()
{
	return analogRead(pin) > threshold;
}

// Indicates whether the sensor is below threshold
bool LaserSensor::BelowThreshold()
{
	return analogRead(pin) < threshold;
}

// Returns the analog value of the laser sensor
int LaserSensor::Value()
{
	return analogRead(pin);
}