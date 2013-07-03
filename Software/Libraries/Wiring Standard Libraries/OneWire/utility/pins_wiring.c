/*
  pins_wiring.c - pin definitions for the Wiring board
  To use with the OneWire library for Wiring, place this file
  in the utility directory under the OneWire library
  
  Copyright (c) 2008 Alan K. Duncan
  This is based very heavily on pin_arduino.c in the Arduino
  distribution.  It bears the same GNU Lesser General Public License
  as listed below

  Copyright (c) 2005 David A. Mellis

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

//#include <avr/io.h>

//extern "C" {
  #include "pins_wiring.h"
//}

//----------	DEFINE CONSTANTS FOR PORTS ON ATMEGA128  --------
#define PA 1
#define PB 2
#define PC 3
#define PD 4
#define PE 5

//---------- MAP PORT NAMES TO ADDRESSES IN MEMORY -------
const uint8_t *port_to_mode_PGM[] =
	{NOT_A_PORT, &DDRA, &DDRB, &DDRC, &DDRD, &DDRE, };

const uint8_t PROGMEM *port_to_output_PGM[] =
	{NOT_A_PORT, &PORTA, &PORTB, &PORTC, &PORTD, &PORTE, };

const uint8_t PROGMEM *port_to_input_PGM[] =
	{NOT_A_PORT, &PINA, &PINB, &PINC, &PIND, &PINE,};

const uint8_t PROGMEM digital_pin_to_port_PGM[] = {
	PD, /* 0 */
	PD,
	PD,
	PD,
	PD,
	PD,
	PD,
	PD,
	PC, /* 8 */
	PC,
	PC,
	PC,
	PC,
	PC,
	PC, /* 14 */
	PC, /* 15 */
	PA, /* 16 */
	PA,
	PA,
	PA,
	PA,
	PA,
	PA,
	PA, /* 23 */
	PB, /* 24 */
	PB,
	PB,
	PB,
	PB,
	PB,
	PB,
	PB, /* 31 */
	PE, /* 32 */
	PE,
	PE,
	PE,
	PE,
	PE,
	PE,
	PE, /* 39 */
};

const uint8_t PROGMEM digital_pin_to_bit_mask_PGM[] = {
	_BV(0), /* 0, port D */
	_BV(1),
	_BV(2),
	_BV(3),
	_BV(4),
	_BV(5),
	_BV(6),
	_BV(7),
	_BV(0), /* 8, port C */
	_BV(1),
	_BV(2),
	_BV(3),
	_BV(4),
	_BV(5),
	_BV(6),
	_BV(7),
	_BV(0), /* 16, port A */
	_BV(1), 
	_BV(2),
	_BV(3),
	_BV(4),
	_BV(5),
	_BV(6),
	_BV(7),
	_BV(0), /* 24, port B */
	_BV(1),
	_BV(2),
	_BV(3),
	_BV(4),
	_BV(5),
	_BV(6),
	_BV(7),
	_BV(0), /* 32, port E */
	_BV(1),
	_BV(2),
	_BV(3),
	_BV(4),
	_BV(5),
	_BV(6),
	_BV(7), /* 39, port E */
};

const uint8_t PROGMEM digital_pin_to_timer_PGM[] = {
	NOT_ON_TIMER,	/* digital pin 0, PORTD */
	NOT_ON_TIMER,
	NOT_ON_TIMER,
	NOT_ON_TIMER,
	NOT_ON_TIMER,
	NOT_ON_TIMER,
	NOT_ON_TIMER,	/* digital pin 6, PORTD, PD6 */
	NOT_ON_TIMER, /* digital pin 7, PORTD, PD7 */
	NOT_ON_TIMER, /* digital pin 8, PORTC, PC0 */
	NOT_ON_TIMER,
	NOT_ON_TIMER,
	NOT_ON_TIMER,
	NOT_ON_TIMER,
	NOT_ON_TIMER,
	NOT_ON_TIMER,
	NOT_ON_TIMER, /* digital pin 15, PORTC, PC7 */
	NOT_ON_TIMER, /* digital pin 16, PORTA, PA0 */
	NOT_ON_TIMER,
	NOT_ON_TIMER,
	NOT_ON_TIMER,
	NOT_ON_TIMER,
	NOT_ON_TIMER,
	NOT_ON_TIMER,
	NOT_ON_TIMER, /* digital pin 23, PORTA, PA7 */
	NOT_ON_TIMER, /* digital pin 24, PORTB, PB0 */
	NOT_ON_TIMER,
	NOT_ON_TIMER,
	NOT_ON_TIMER,
	TIMER0,		/* digital pin 28, PORTB, PB4 */
	TIMER1A,		/* digital pin 29, PORTB, PB5 */
	TIMER1B,		/* digital pin 30, PORTB, PB6 */
	TIMER2,		/* digital pin 31, PORTB, PB7 */
	NOT_ON_TIMER,	/* digital pin 32, PORTE, PE0 */
	NOT_ON_TIMER,
	NOT_ON_TIMER,
	TIMER3A,		/* digital pin 35, PORTE, PE3 */
	TIMER3B,		/* digital pin 36, PORTE, PE4 */
	TIMER3C,		/* digital pin 37, PORTE, PE5 */
	NOT_ON_TIMER,		/* digital pin 38, PORTE, PE6 */
	NOT_ON_TIMER	/* digital pin 39, PORTE, PE7 */
	
};

