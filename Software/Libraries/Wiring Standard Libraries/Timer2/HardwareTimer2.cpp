/* -*- mode: jde; c-basic-offset: 2; indent-tabs-mode: nil -*- */

/*
  HardwareTimer2.cpp - HardwareTimer2 library for Wiring & Arduino
 
  Copyright (c) 2009-10 Hernando Barragan
 
  Based on MsTimer2.cpp - Using timer2 with 1ms resolution
  Copyright (c) 2008-09 Javier Valencia <javiervalencia80@gmail.com>
  http://www.arduino.cc/playground/Main/MsTimer2
 
  This library is free software; you can redistribute it and/or
  modify it under the terms of the GNU Lesser General Public
  License as published by the Free Software Foundation; either
  version 2.1 of the License, or (at your option) any later version.

  This library is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
  Lesser General Public License for more details.

  You should have received a copy of the GNU Lesser General Public
  License along with this library; if not, write to the Free Software
  Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA
*/

#include <HardwareTimer2.h>


void Timer2Service()
{
  // just call the timer default overflow
  Timer2._overflow();
}

#ifndef WIRING // Wiring pre-defines signal handlers so don't define any if compiling for the Wiring platform
ISR(TIMER2_OVF_vect) {
  // if mode specified in MILLISECONDS
  // use standard Timer2Service() which calls the timer overflow rutine
  // if mode is PRESCALER then call the user's function for flexibility
  // force adjust the counter for CPU speed differences
  if(F_CPU < 16000000UL) TCNT2 = tcnt2; 
  (mode == MILLISECONDS) ? ( Timer2Service() ) : ( if(Timer2.function) Timer2.function(); );
}
#endif



void HardwareTimer2::setPrescaler(unsigned int prescaler) {
#if defined (__AVR_ATmega168__) || defined (__AVR_ATmega48__) || defined (__AVR_ATmega88__) || defined (__AVR_ATmega328P__) || defined(__AVR_ATmega1280__) || defined(__AVR_ATmega1281__) || defined(__AVR_ATmega2561__) 
	TIMSK2 &= ~(1<<TOIE2);
	TCCR2A &= ~((1<<WGM21) | (1<<WGM20));
	TCCR2B &= ~(1<<WGM22);
	ASSR &= ~(1<<AS2);
	TIMSK2 &= ~(1<<OCIE2A);
	
#if defined(WIRING)  // for atmega1281 and atmega2561
	// WIRING provides this method in WTimer.c
	// but explicit CS2X setup below
	
	timer2SetPrescaler(prescaler);
#else
	switch (prescaler) {
		case CLOCK_STOP:
			TCCR2B &= ~((1<<CS22) | (1<<CS21) | (1<<CS20));
			break;    
		case CLOCK_DIV1:      
			TCCR2B |= (1<<CS20);
			TCCR2B &= ~((1<<CS22) | (1<<CS21));
			break;    
		case CLOCK_DIV8:      
			TCCR2B |= (1<<CS21);
			TCCR2B &= ~((1<<CS22) | (1<<CS20));
			break;    
		case CLOCK_DIV32:     
			TCCR2B |= ((1<<CS21) | (1<<CS20));
			TCCR2B &= ~(1<<CS22) ;
			break;    
		case CLOCK_DIV64:     
			TCCR2B |= (1<<CS22);
			TCCR2B &= ~((1<<CS21) | (1<<CS20));
			break;    
		case CLOCK_DIV128:    
			TCCR2B |= ((1<<CS22) | (1<<CS20));
			TCCR2B &= ~(1<<CS21) ;
			break;    
		case CLOCK_DIV256:   
			TCCR2B |= ((1<<CS22) | (1<<CS21));
			TCCR2B &= ~(1<<CS20) ;
			break;    
		case CLOCK_DIV1024: 
			TCCR2B |= ((1<<CS22) | (1<<CS21) | (1<<CS20));
			break;    
		default:
			break;
	}
#endif
	
#elif defined (__AVR_ATmega8__)
	TIMSK &= ~(1<<TOIE2);
	TCCR2 &= ~((1<<WGM21) | (1<<WGM20));
	TIMSK &= ~(1<<OCIE2);
	ASSR &= ~(1<<AS2);
	
	switch (prescaler) {
		case CLOCK_STOP:
			TCCR2 &= ~((1<<CS22) | (1<<CS21) | (1<<CS20));
			break;    
		case CLOCK_DIV1:      
			TCCR2 |= (1<<CS20);
			TCCR2 &= ~((1<<CS22) | (1<<CS21));
			break;    
		case CLOCK_DIV8:      
			TCCR2 |= (1<<CS21);
			TCCR2 &= ~((1<<CS22) | (1<<CS20));
			break;    
		case CLOCK_DIV32:     
			TCCR2 |= ((1<<CS21) | (1<<CS20));
			TCCR2 &= ~(1<<CS22) ;
			break;    
		case CLOCK_DIV64:     
			TCCR2 |= (1<<CS22);
			TCCR2 &= ~((1<<CS21) | (1<<CS20));
			break;    
		case CLOCK_DIV128:    
			TCCR2 |= ((1<<CS22) | (1<<CS20));
			TCCR2 &= ~(1<<CS21) ;
			break;    
		case CLOCK_DIV256:   
			TCCR2 |= ((1<<CS22) | (1<<CS21));
			TCCR2 &= ~(1<<CS20) ;
			break;    
		case CLOCK_DIV1024: 
			TCCR2 |= ((1<<CS22) | (1<<CS21) | (1<<CS20));
			break;    
		default:
			break;
	}
	
#elif defined (__AVR_ATmega128__)
	TIMSK &= ~(1<<TOIE2);
	TCCR2 &= ~((1<<WGM21) | (1<<WGM20));
	TIMSK &= ~(1<<OCIE2);
	
	
#if defined(WIRING)  // for atmega128 
	// WIRING provides this method in WTimer.c
	// but explicit CS2X setup below
	
	timer2SetPrescaler(prescaler);
#else
	
	switch (prescaler) {
		case CLOCK_STOP:
			TCCR2 &= ~((1<<CS22) | (1<<CS21) | (1<<CS20));
			break;    
		case CLOCK_DIV1:      
			TCCR2 |= (1<<CS20);
			TCCR2 &= ~((1<<CS22) | (1<<CS21));
			break;    
		case CLOCK_DIV8:      
			TCCR2 |= (1<<CS21);
			TCCR2 &= ~((1<<CS22) | (1<<CS20));
			break;    
		case CLOCK_DIV64:     
			TCCR2 |= ((1<<CS21) | (1<<CS20));
			TCCR2 &= ~(1<<CS22) ;
			break;    
		case CLOCK_DIV256:     
			TCCR2 |= (1<<CS22);
			TCCR2 &= ~((1<<CS21) | (1<<CS20));
			break;    
		case CLOCK_DIV1024:    
			TCCR2 |= ((1<<CS22) | (1<<CS20));
			TCCR2 &= ~(1<<CS21) ;
			break;    
		default:
			break;
	}
#endif 
	
#endif	
}

// HardwareTimer2 set for prescaler
void HardwareTimer2::set(void (*f)(), unsigned int prescaler) {
  mode = PRESCALER;
  stop();
  setPrescaler(prescaler);
	
  // just in case someone wants to mess with TCNT2 later
  // for fractions of counter, calculate the counter difference
  tcnt2 = 256 - (int)((float)F_CPU * 0.001 / (float)prescaler);	
  function = f;  
}


// HardwareTimer2 set for milliseconds (the original mode use of MsTimer2)
void HardwareTimer2::set(unsigned long ms, void (*f)()) {
  mode = MILLISECONDS;
  float prescaler = 0.0;
  stop();

  if ((F_CPU >= 1000000UL) && (F_CPU <= 16000000UL)) {  // prescaler set to 64
    setPrescaler(CLOCK_DIV64);
    prescaler = (float) CLOCK_DIV64;
  } else if (F_CPU < 1000000UL) {  // prescaler set to 8
    setPrescaler(CLOCK_DIV8);
    prescaler = (float) CLOCK_DIV8;
  } else {
#if defined (__AVR_ATmega128__)
    setPrescaler(CLOCK_DIV256);  // for other speeds if atmega128 prescaler set to 256
    prescaler = (float) CLOCK_DIV256;
#else
    setPrescaler(CLOCK_DIV128);  // prescaler set to 128
    prescaler = (float) CLOCK_DIV128;
#endif
  }
  tcnt2 = 256 - (int)((float)F_CPU * 0.001 / prescaler);	
  (ms == 0) ? msecs = 1 : msecs = ms;  
  function = f;
}


void HardwareTimer2::start() {
  count = 0;
  overflowing = 0;
#if defined (__AVR_ATmega168__) || defined (__AVR_ATmega48__) || defined (__AVR_ATmega88__) || defined (__AVR_ATmega328P__) || (__AVR_ATmega1280__) || defined(__AVR_ATmega1281__) || defined(__AVR_ATmega2561__)
  TCNT2 = tcnt2;
#if defined (WIRING)
  timerAttach(TIMER2OVERFLOW_INT, (mode == MILLISECONDS) ? Timer2Service : function);
#endif
  TIMSK2 |= (1<<TOIE2);
#elif defined (__AVR_ATmega128__)
  TCNT2 = tcnt2;
#if defined (WIRING)
  timerAttach(TIMER2OVERFLOW_INT, (mode == MILLISECONDS) ? Timer2Service : function);
#endif
  TIMSK |= (1<<TOIE2);
#elif defined (__AVR_ATmega8__)
  TCNT2 = tcnt2;
  TIMSK |= (1<<TOIE2);
#endif
}


void HardwareTimer2::stop() {
#if defined (__AVR_ATmega168__) || defined (__AVR_ATmega48__) || defined (__AVR_ATmega88__) || defined (__AVR_ATmega328P__) || (__AVR_ATmega1280__) || defined(__AVR_ATmega1281__) || defined(__AVR_ATmega2561__)
  TIMSK2 &= ~(1<<TOIE2);
#if defined (WIRING)
  timerDetach(TIMER2OVERFLOW_INT);
#endif
#elif defined (__AVR_ATmega128__)
  TIMSK &= ~(1<<TOIE2);
#if defined (WIRING)
  timerDetach(TIMER2OVERFLOW_INT);
#endif
#elif defined (__AVR_ATmega8__)
  TIMSK &= ~(1<<TOIE2);
#endif
}


void HardwareTimer2::_overflow() {
  count += 1;  	
  if (count >= msecs && !overflowing) {
    overflowing = true;
    count = 0;
    (*function)();
    overflowing = 0;
  }
}

// Timer2 instance of HardwareTimer2
HardwareTimer2 Timer2;




