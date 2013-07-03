#ifndef phys253_h
#define phys253_h


// include all of the h-file headers used in general Phys 253 programs
// added by Jon Nakane, 2009 March 23
// edit 2010 May 3 - removed WConstants.h from here and motor.h for Wiring-0026.
#include <phys253pins.h>
#include <motor.h>
#include <phys253pins.h>
#include <LiquidCrystal.h>
#include <Servo253.h>
//#include "WConstants.h"





//setup the variables and classes used throughout phys 253.
LiquidCrystal LCD = LiquidCrystal(26,27,28,2);

motorClass motor ;


Servo253 RCServo0 ;
Servo253 RCServo1 ;
Servo253 RCServo2 ;




inline int knob(int value) 		{ return analogRead(knobInput[value]) ;}
inline void buzzer	(int value) { return pulseOut(buzzerOutput, value*2) ;}
inline void buzzerOff () 	    { return pulseStop(buzzerOutput ) ;}
inline int startbutton() 		{ return !digitalRead(startInput) ;}
inline int stopbutton() 		{ return !digitalRead(stopInput) ;}



#ifdef __cplusplus            // added 2009 May 18th - required to disable analogWrite on PWM lines.
extern "C" {
#endif
void timer1PWMAOff(void);
void timer1PWMBOff(void);
void timer1PWMCOff(void);
void timer3PWMAOff(void);
void timer3PWMBOff(void);
void timer3PWMCOff(void);
#ifdef __cplusplus
}
#endif

void analogWriteReset(int PWMPin)   // added 2009 May 18th - required to disable analogWrite on PWM lines
{
    switch(PWMPin) {
		 case 5:
		 case 29:
		    timer1PWMAOff();
		    break ;
		 case 4:
		 case 30:
		    timer1PWMBOff();
		    break ;
		 case 3:
		 case 31:
		    timer1PWMCOff();
		    break ;
		 case 2:
		 case 35:
		    timer3PWMAOff();
		    break ;
		 case 1:
		 case 36:
		    timer3PWMBOff();
		    break ;
		 case 0:
		 case 37:
		    timer3PWMCOff();
		    break ;
	}
}






#endif
