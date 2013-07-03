/*
  QSlide.cpp - QProx 401/501 library for Wiring & Arduino
  Copyright (c) 2006 Nicholas Zambetti & Massimo Banzi.  All right reserved.

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

/******************************************************************************
 * Includes
 ******************************************************************************/

// include this library's description file
#include "QSlide.h"

/******************************************************************************
 * Constructors 
 ******************************************************************************/

QSlide::QSlide(byte drd, byte din, byte ss, byte clk, byte dout, byte det, byte prx)
{
  // record pins for sensor
  _drd = drd;
  _din = din;
  _ss = ss;
  _clk = clk;
  _dout = dout;
  _det = det;
  _prx = prx;

  // set data directions for sensor pins
  pinMode(_drd, INPUT);
  pinMode(_din,  INPUT);
  pinMode(_ss,  OUTPUT);
  pinMode(_clk, OUTPUT);
  pinMode(_dout,  OUTPUT);
  pinMode(_det, INPUT);
  pinMode(_prx, INPUT);

  // initialize pin values
  digitalWrite(_clk, HIGH);
  digitalWrite(_ss,  HIGH);

  // initlialize wiring heart
  initWiring();
  interrupts();

  // initialize sensor
  calibrate();
  setProximityThreshold(10);
  setTouchThreshold(10);
}

/******************************************************************************
 * Private Member Functions
 ******************************************************************************/

// signals qtx01 to perform self-calibration
void QSlide::calibrate(void)
{
  // calibrate
  waitForReady();
  transfer(0x01);
  delay(600);

  // calibrate ends 
  waitForReady();
  transfer(0x02);
  delay(600);
} 

// wait for the qtx01 to be ready
void QSlide::waitForReady(void)
{
  while(!digitalRead(_drd)){
    continue;
  }
} 

// writes and reads a byte to/from the qtx01
byte QSlide::transfer(byte data_out)
{
  byte i = 8;
  byte mask = 0;
  byte data_in = 0;

  digitalWrite(_ss, LOW); // select slave by lowering ss pin
  delayMicroseconds(75);  //wait for 75 microseconds

  while(0 < i) {
    mask = 0x01 << --i; // generate bitmask for the appropriate bit MSB first

    // set out byte
    if(data_out & mask){         // choose bit
      digitalWrite(_dout, HIGH); // send 1
    }else{
      digitalWrite(_dout, LOW);  // send 0
    }

    // lower clock pin, this tells the sensor to read the bit we just put out
    digitalWrite(_clk, LOW); // tick

    // give the sensor time to read the data
    delayMicroseconds(75);

    // bring clock back up
    digitalWrite(_clk, HIGH); // tock

    // give the sensor some time to think
    delayMicroseconds(20);

    // now read a bit coming from the sensor
    if(digitalRead(_din)){
      data_in |= mask;
    }

    // give the sensor some time to think
    delayMicroseconds(20);
  }

  delayMicroseconds(75);   //  give the sensor some time to think
  digitalWrite(_ss, HIGH); // do acquisition burst

  return data_in;
}

// instructs qtx01 to perform drift compensation, also returns reading
byte QSlide::driftCompensate(void)
{
  waitForReady();
  return transfer(0x03);
}

/******************************************************************************
 * Public Member Functions
 ******************************************************************************/

void QSlide::setProximityThreshold(byte amount)
{
  waitForReady();
  transfer(0x40 & (amount & 0x3F));
}

void QSlide::setTouchThreshold(byte amount)
{
  waitForReady();
  transfer(0x80 & (amount & 0x3F));
}

byte QSlide::isTouching(void)
{
  return digitalRead(_det);
}

byte QSlide::isNear(void)
{
  return digitalRead(_prx);
}

byte QSlide::read(void)
{
  byte result;
  waitForReady();
  result = transfer(0x00);
  if(0x80 & result){ 
    result = result & 0x7f;
  }else{
    result = _prevResult;
  }
  _prevResult = result;
  return result;
}

