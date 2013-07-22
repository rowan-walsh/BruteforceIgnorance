#ifndef QrdSensor_h
#define QrdSensor_h

class QrdSensor
{
  private:
	  int pin;
  public:
	QrdSensor();
	void Attach(int sensorPin);
	bool TapeDetected();
	int Value();
};

#endif
