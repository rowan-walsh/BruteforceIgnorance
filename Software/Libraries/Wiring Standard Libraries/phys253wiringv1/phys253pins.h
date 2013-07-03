#ifndef phys253pins_h
#define phys253pins_h

// last update - 2009 May 2.

const int knobInput[] 			= {-1, -1, -1, -1, -1, -1, 6, 7} ;
const int buzzerOutput			= 3 ;
const int buzzerOuptutDigital 	= 31 ;
const int stopInput 			= 49 ;
const int startInput 			= 50 ;

const int RCServo0Output    	= 35 ;
const int RCServo1Output    	= 31 ;
const int RCServo2Output    	= 34 ;

const int Motor_Direction[] 	= {24, 25, 38, 39} ;
const int Motor_EnableDigital[] = {29, 30, 36, 37} ;  //digital input/output values
const int Motor_Enable[] 		= {5,  4,  1,  0} ;   // PWM output values

#endif