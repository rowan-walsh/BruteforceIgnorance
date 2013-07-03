/* -*- mode: jde; c-basic-offset: 2; indent-tabs-mode: nil -*- */

/*
  HardwareTimer2.h - HardwareTimer2 library for Wiring & Arduino
 
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

#ifndef HardwareTimer2_h
#define HardwareTimer2_h

#include <avr/interrupt.h>
#include "WProgram.h"

// MILLISECONDS original mode of operation of MsTimer2
#define MILLISECONDS 0x01
// PRESCALER flexible mode for users to use Timer2
#define PRESCALER 0x02


#if defined(__AVR_ATmega128__) 

#define CLOCK_STOP      0x00
#define CLOCK_DIV1      0x01
#define CLOCK_DIV8      0x02
#define CLOCK_DIV64     0x03
#define CLOCK_DIV256    0x04
#define CLOCK_DIV1024   0x05
#define PRESCALE_MASK   0x07

#else

#define CLOCK_STOP      0x00
#define CLOCK_DIV1      0x01
#define CLOCK_DIV8      0x02
#define CLOCK_DIV32     0x03
#define CLOCK_DIV64     0x04
#define CLOCK_DIV128    0x05
#define CLOCK_DIV256    0x06
#define CLOCK_DIV1024   0x07
#define PRESCALE_MASK   0x07

#endif


class HardwareTimer2 {
  private:
    unsigned long msecs;
    volatile unsigned long count;
    volatile boolean overflowing;
    volatile unsigned int mode;
    volatile unsigned int tcnt2;
    
  public:
    void (*function)();	
	
	// prescaler mode set()
    void set(void (*f)(), unsigned int prescaler);
	// milliseconds mode set()
    void set(unsigned long ms, void (*f)());
	void setPrescaler(unsigned int prescaler);
    void start();
    void stop();
    void _overflow();
};

extern HardwareTimer2 Timer2;

#endif

