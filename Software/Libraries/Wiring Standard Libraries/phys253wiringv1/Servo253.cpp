/*
  Servo253.cpp - Servo library for Arduino & Wiring

  Modified to operate using Timer2.  Jon Nakane, 2009 April


  Based on Hernando Barragan's original C implementation
  Copyright (c) 2006 Nicholas Zambetti.  All right reserved.

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

/*
version by Jon Nakane (jnakane@physics.ubc.ca) to try to convert to Timer2 to avoid
conflicts with Timer3 and the PWM outputs.  There was substantial jitter when both the PWM outputs
and servo motors were activated.

*/

#include "WProgram.h"

extern "C" {
//  #include <stdio.h>
//  #include <inttypes.h>
//  #include <avr/interrupt.h>
//  #include <avr/pgmspace.h>
//  #include <stdio.h>
//  #include <stdarg.h>
//  #include <math.h>

//  #include "WConstants.h"

  extern void pinMode(uint8_t, uint8_t);
  extern uint8_t digitalRead(uint8_t);
  extern void digitalWrite(uint8_t, uint8_t);

  extern void timer2Init(void);
  extern void timer2SetPrescaler(uint8_t);
  extern void timerAttach(uint8_t, void(*)(void));
  extern void timerDetach(uint8_t);
}

#include "Servo253.h"

// USEFUL DEFINITIONS //////////////////////////////////////////////////////////

/*
ideally
62500 steps in one sec
62.5 steps in one ms
1250 steps in 20 ms = servo period
56.25 min amount of servo steps
131.25 max amount of servo steps
*/

// in reality
//#define SERVO_MINIMUM 10
//#define SERVO_MAXIMUM 40
//#define SERVO_PERIOD  2600

//#define SERVO_MINIMUM 40
//#define SERVO_MAXIMUM 158
//#define SERVO_PERIOD  1300

#define SERVO_MINIMUM 10
#define SERVO_MAXIMUM 40
#define SERVO_PERIOD  500


// Initialize Class Variables //////////////////////////////////////////////////

Servo253* Servo253::_servos[8];
uint8_t   Servo253::_count = 0;
int8_t    Servo253::_current = -1;
uint16_t  Servo253::_positionTicks = 0;

// Constructors ////////////////////////////////////////////////////////////////

Servo253::Servo253()
{
  _index = 0;
  _duty = SERVO_MINIMUM;
}

// Public Methods //////////////////////////////////////////////////////////////

uint8_t Servo253::attach(int pin)
{
  // if list is already full, return a failure
  if(8 < _count){
    return 0;
  }
  // record pin number, set pin to output
  pinMode(_pin = pin, OUTPUT);
  // if already in list, return a success
  if(this == _servos[_index]){
    return 1;
  }
  // if first servo, ready the list
  if(0 == _count){
    for(uint8_t i = 0; i < 8; ++i){
      _servos[i] = NULL;
    }
  }
  // find empty slot, add servo to list
  for(uint8_t i = 0; i < 8; ++i){
    if(NULL == _servos[i]){
      _servos[i] = this;
      _index = i;
      ++_count;
      break;
    }
  }
  // init servos if this is the first
  if(1 == _count){
    start();
  }
  // return a success
  return 1;
}




void Servo253::detach()
{
  // if already in list
  if(this == _servos[_index]){
    // remove from list
    _servos[_index] = NULL;
    // adjust count and end timer if this was last servo
    if(0 < _count){
      --_count;
      if(0 == _count){
        end();
      }
    }
  }
}



void Servo253::write(int angle)
{
  // scale position
  //  position is scaled according to the max and min of servo position
  uint16_t position = (uint16_t)(SERVO_MINIMUM + (((float)angle / 180) * (SERVO_MAXIMUM - SERVO_MINIMUM)));

  // bind to limits
  position = max(position, SERVO_MINIMUM);
  position = min(position, SERVO_MAXIMUM);

  // set position
  _duty = position;
}


uint8_t Servo253::read()
{
  return (uint8_t)(((float)(_duty - SERVO_MINIMUM) / (SERVO_MAXIMUM - SERVO_MINIMUM)) * 180);
}



uint8_t Servo253::attached()
{
  if(this == _servos[_index]){
    return 1;
  }
  return 0;
}


// Private Methods /////////////////////////////////////////////////////////////

void Servo253::end()
{
  //digitalWrite(48, LOW);
  // disable the timer2 output compare interrupt
  TIMSK &= ~_BV(OCIE2);
  timerDetach(TIMER2OUTCOMPARE_INT);
}






void Servo253::start()
{
  //digitalWrite(48, HIGH);
  timer2Init();

  // disble timer2 output compare interrupt
  TIMSK &= ~_BV(OCIE2);

  // set the prescaler for timer2
   timer2SetPrescaler(TIMER_CLK_DIV1024);
//timer2SetPrescaler(TIMER_CLK_DIV256);

  // attach the software PWM service routine to timer2 output compare
  timerAttach(TIMER2OUTCOMPARE_INT, service);

///TIMER2_OVF_vect


  // update output compare register
  OCR2 += SERVO_PERIOD;



  // enable the timer2 output compare interrupt
  TIMSK |= _BV(OCIE2);

  // reset position ticks
  _positionTicks = 0;

  // reset current servo
  _current = -1;
}



void Servo253::service()
{
  uint16_t ticks;


  // turn off current servo, if not "non servo"
  if(0 <= _current){
    digitalWrite(_servos[_current]->_pin, LOW);
  }


 // advance to next servo
  while(_current < 7){
    if(NULL != _servos[++_current]){
      break;
    }
  }

 // if current is not a servo
  if(NULL == _servos[_current]){
    // reset and wait out the period
    _current = -1;
    ticks = SERVO_PERIOD - _positionTicks;
  }else{
    // turn on new servo
    digitalWrite(_servos[_current]->_pin, HIGH);
    // schedule ttl
    ticks = _servos[_current]->_duty;
  }



  // schedule next interrupt
  OCR2 += ticks;
  // keep track of this period
  _positionTicks += ticks;
  if(_positionTicks >= SERVO_PERIOD){
    _positionTicks = 0;
  }


}
