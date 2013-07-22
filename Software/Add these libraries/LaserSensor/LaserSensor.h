#ifndef LaserSensor_h
#define LaserSensor_h

class LaserSensor
{
  private:
	  int threshold;
	  int pin;
  public:
	LaserSensor();
	void Attach(int sensorPin, int sensorThreshold);
	void SetThreshold(int threshold);
	bool AboveThreshold();
	bool BelowThreshold();
	int Value();
};

#endif
