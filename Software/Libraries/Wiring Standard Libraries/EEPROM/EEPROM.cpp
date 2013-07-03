/* -*- mode: jde; c-basic-offset: 2; indent-tabs-mode: nil -*- */

/*
  Part of the Wiring project - http://wiring.org.co

  Copyright (c) 2004-10 Hernando Barragan

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

#include "EEPROM.h"


uint8_t WEEPROM::read(int address)
{
  return eeprom_read_byte((unsigned char *) address);
}

void WEEPROM::write(int address, uint8_t value)
{
  eeprom_write_byte((unsigned char *) address, value);
}

/*
uint8_t WEEPROM::read(uint16_t address)
{
#if defined (__AVR_ATmega2561__)||(__AVR_ATmega2560__)||(__AVR_ATmega1281__)||(__AVR_ATmega1280__)
  while( EECR & _BV(EEPE) );
#else
  while( EECR & _BV(EEWE) );
#endif
  EEARH = (uint8_t) ((address & 0xFF00) >> 8);
  EEARL = (uint8_t) (address & 0x00FF);
    
  // set read EERE
  EECR |= _BV(EERE);
    
  // return data byte 
  return EEDR;
}

void WEEPROM::write(uint16_t address, uint8_t value)
{
  // wait until any previous write is done
#if defined (__AVR_ATmega2561__)||(__AVR_ATmega2560__)||(__AVR_ATmega1281__)||(__AVR_ATmega1280__)
  while( EECR & _BV(EEPE) );
#else
  while( EECR & _BV(EEWE) );
#endif
  EEARH = (uint8_t) ((address & 0xFF00) >> 8);
  EEARL = (uint8_t) (address & 0x00FF);

  EEDR = value;

#if defined (__AVR_ATmega2561__)||(__AVR_ATmega2560__)||(__AVR_ATmega1281__)||(__AVR_ATmega1280__)
  // set master write enable EMWEE
  EECR |= _BV(EEMPE);

  // Set write EEPE
  EECR |= _BV( EEPE );

#else
  // set master write enable EMWEE
  EECR |= _BV(EEMWE);

  // Set write EEWE 
  EECR |= _BV( EEWE );
#endif
}
*/

WEEPROM EEPROM;

