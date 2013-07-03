/*
  Encoder.cpp - Encoder library for Wiring & Arduino
  Copyright (c) 2006-10 Hernando Barragan and Nicholas Zambetti.
  All right reserved.

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

#include "WProgram.h"
#include "Encoder.h"


Encoder* Encoder::_encoders[4];
uint8_t Encoder::_count = 0;
const uint8_t Encoder::_interrupts[] = { 2, 3, 38, 39 };

Encoder::Encoder() {
  _index = 0;
}

uint8_t Encoder::attach(uint8_t pin_a, uint8_t pin_b) {
  if(4 <= _count) {
    return 0;
  }
  pinMode(_pin_a = pin_a, INPUT);
  pinMode(_pin_b = pin_b, INPUT);
  _position = 0;
  if(this == _encoders[_index]) {
    return 1;
  }

  if(0 == _count) {
    for(uint8_t i=0; i< 4; i++ ) {
      _encoders[i] = NULL;
    }
  }

  for(uint8_t i = 0; i< 4; i++) {
    if(NULL == _encoders[i] && _interrupts[i] == _pin_a) {
      _encoders[i] = this;
      _index = i;
      ++_count;
      break;
    }
  }

  noInterrupts(); 
  switch(_pin_a) {
    case 2:
      //EICRA |= _BV(ISC20)|_BV(ISC21);
      //EIMSK  |= _BV(INT2);
      attachInterrupt(EXTERNAL_INT_2, service0, CHANGE);
      break;
    case 3:
      //EICRA |= _BV(ISC30)|_BV(ISC31);
      //EIMSK  |= _BV(INT3);
      attachInterrupt(EXTERNAL_INT_3, service1, CHANGE);
      break;
    case 38:
      //EICRB |= _BV(ISC60)|_BV(ISC61);
      //EIMSK  |= _BV(INT6);
      attachInterrupt(EXTERNAL_INT_6, service2, CHANGE);
      break;
    case 39:
      //EICRB |= _BV(ISC70)|_BV(ISC71);
      //EIMSK  |= _BV(INT7);
      attachInterrupt(EXTERNAL_INT_7, service3, CHANGE);
      break;
    default:
      break;
  }
  interrupts();
  return 1;
}


void Encoder::detach() {
  if(this == _encoders[_index]) {
    switch(_pin_a) {
      case 2:
        //EIMSK  &= ~_BV(INT2);
        detachInterrupt(EXTERNAL_INT_2);
        break;
      case 3:
        //EIMSK  &= ~_BV(INT3);
        detachInterrupt(EXTERNAL_INT_3);
        break;
      case 38:
        //EIMSK  &= ~_BV(INT6);
        detachInterrupt(EXTERNAL_INT_6);
        break;
      case 39:
        //EIMSK  &= ~_BV(INT7);
        detachInterrupt(EXTERNAL_INT_7);
        break;
      default:
        break;
    }
    _encoders[_index] = NULL;
    if(0 < _count) {
      --_count;
    }
  }
}


uint8_t Encoder::attached(void) {
  if(this == _encoders[_index]) {
    return 1;
  }
  return 0;
}


void Encoder::write(int32_t position) {
  _position = position;
}


int32_t Encoder::read(void) {
  return _position; 
}

void Encoder::service0(void) {	_encoders[0]->service();	}
void Encoder::service1(void) {	_encoders[1]->service();	}
void Encoder::service2(void) {	_encoders[2]->service();	}
void Encoder::service3(void) {	_encoders[3]->service();	}


void Encoder::service(void) {
  if((digitalRead(_pin_a) == LOW) ^ (digitalRead(_pin_b) == HIGH)) {
    _position++;
  } else {
    _position--;
  }
}
