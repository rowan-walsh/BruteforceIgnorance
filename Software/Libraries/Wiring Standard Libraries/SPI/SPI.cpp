/* -*- mode: jde; c-basic-offset: 2; indent-tabs-mode: nil -*- */

/*
  Part of the Wiring project - http://wiring.org.co

  Copyright (c) 2010 Hernando Barragan

  This library is free software; you can redistribute it and/or
  modify it under the terms of the GNU Lesser General Public
  License as published by the Free Software Foundation; either
  version 2.1 of the License, or (at your option) any later version.

  This library is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
  Lesser General Public License for more details.

  You should have received a copy of the GNU Lesser General
  Public License along with this library; if not, write to the
  Free Software Foundation, Inc., 59 Temple Place, Suite 330,
  Boston, MA  02111-1307  USA
*/

#include "SPI.h"


// default is MASTER
void WSPI::begin() 
{
  begin(SPI_MASTER, MSBFIRST, SPI_MODE3, SPI_CLOCK_DIV4); 
}


void WSPI::begin(uint8_t mode, uint8_t bitOrder, uint8_t dataMode, uint8_t clockRate)
{
  if(mode == SPI_MASTER) {
    pinMode(SS, OUTPUT);
    pinMode(SCK, OUTPUT);
    pinMode(MOSI, OUTPUT);
    pinMode(MISO, INPUT);
    setBitOrder(bitOrder);
    setDataMode(dataMode);
    setClockDivider(clockRate); 

    // Enable SPI, Master
    SPCR |= _BV(MSTR);
    SPCR |= _BV(SPE);
  } else { 
    pinMode(SS, INPUT);
    pinMode(SCK, INPUT);
    pinMode(MOSI, INPUT);
    pinMode(MISO, OUTPUT);
    setBitOrder(bitOrder);
    setDataMode(dataMode);
    // clock rate is ignored in slave mode

    // Enable SPI, Slave
    SPCR |= _BV(SPE);
  }
}


void WSPI::end() {
  SPCR &= ~_BV(SPE);
}


// send and receive
uint8_t WSPI::transfer(uint8_t data)
{
  SPDR =  data;
  while(!(SPSR & _BV(SPIF)));
  return SPDR;
}


inline void WSPI::setBitOrder(uint8_t bitOrder) {
  if(bitOrder == LSBFIRST) {
    SPCR |= _BV(DORD);
  } else {
    SPCR &= ~(_BV(DORD));
  }
}


void WSPI::setClockDivider(uint8_t rate) {
  SPCR = (SPCR & ~SPI_CLOCK_MASK) | (rate & SPI_CLOCK_MASK);
  SPSR = (SPSR & ~SPI_2XCLOCK_MASK) | (rate & SPI_2XCLOCK_MASK);
}


void WSPI::setDataMode(uint8_t mode)
{
  SPCR = (SPCR & ~SPI_MODE_MASK) | mode;
}


WSPI SPI;
