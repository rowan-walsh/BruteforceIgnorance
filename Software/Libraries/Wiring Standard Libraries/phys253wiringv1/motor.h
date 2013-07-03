#ifndef motor_h
#define motor_h

// include types & constants of Wiring core API
//#include "WConstants.h"
#include "phys253pins.h"

class motorClass
{
	public:
		//consturctor
		motorClass();

		//member functions
		void stop(int motorVal);
		void stop_all();
		void speed(int motorVal, int speedval);
		void detach(int motorVal) ;

	private:
	    int _isvalid ;
};
#endif



