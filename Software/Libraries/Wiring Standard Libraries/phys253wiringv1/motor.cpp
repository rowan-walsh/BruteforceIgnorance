#include "WProgram.h"
#include "motor.h"


//#include "phys253.h"
//#include "phys253pins.h"



motorClass::motorClass()
{
	for (int i = 0 ; i < 4; i++) {
		pinMode(Motor_Direction[i], OUTPUT);
//		pinMode(Motor_EnableDigital[i], OUTPUT);

		digitalWrite(Motor_Direction[i], HIGH);
//	  	analogWrite(Motor_Enable[i], 1);  //make the motor glitch, force it to be zero.
	  	analogWrite(Motor_Enable[i], 0);
      }
}


void motorClass::stop(int motorVal)
{
	analogWrite(Motor_Enable[motorVal], 0);
}


void motorClass::stop_all()
{
	for (int i = 0 ; i < 4; i++) {
		analogWrite(Motor_Enable[i],0);
	}
}


void motorClass::speed(int motorVal, int speedvalue)
{
	if (speedvalue >= 0)
	{
		digitalWrite(Motor_Direction[motorVal], HIGH);
		analogWrite(Motor_Enable[motorVal], abs(speedvalue));
	}

	if(speedvalue < 0)
	{
		digitalWrite(Motor_Direction[motorVal], LOW);
		analogWrite(Motor_Enable[motorVal], abs(speedvalue));
	}
}


