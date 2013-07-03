/*
  LiquidCrystal.cpp - Liquid Crystal Display library for Wiring & Arduino
  Copyright (c) 2006-08 Hernando Barragan and Nicholas Zambetti.  
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

extern "C" {
  extern void pinMode(uint8_t, uint8_t);
  extern void digitalWrite(uint8_t, uint8_t);
  extern uint8_t digitalRead(uint8_t);
  extern void portMode(uint8_t, uint8_t);
  extern void portWrite(uint8_t, uint8_t);
  extern uint8_t portRead(uint8_t);
}

#include "LiquidCrystal.h"


#define WD_LINE0_DDRAMADDR  0x00
#define WD_LINE1_DDRAMADDR  0x40
#define WD_LINE2_DDRAMADDR  0x14
#define WD_LINE3_DDRAMADDR  0x54

#define WD_CLR             0
#define WD_HOME            1
#define WD_ENTRY_MODE      2
#define WD_ENTRY_INC       1
#define WD_ENTRY_SHIFT     0
#define WD_ON_CTRL         3
#define WD_ON_DISPLAY      2
#define WD_ON_CURSOR       1
#define WD_ON_BLINK        0
#define WD_MOVE            4
#define WD_MOVE_DISP       3
#define WD_MOVE_RIGHT      2
#define WD_FUNCTION        5
#define WD_FUNCTION_8BIT   4
#define WD_FUNCTION_2LINES 3
#define WD_FUNCTION_10DOTS 2
#define WD_CGRAM           6
#define WD_DDRAM           7
#define WD_BUSY            7
#define WD_DELAY asm volatile ("nop"); asm volatile ("nop")
//#define DATA_8_BITS     0x0
//#define DATA_4_BITS     0x1


void LiquidCrystal::display_init(void) {
  // initialize WD control lines
  digitalWrite(_control_rs, LOW);
  digitalWrite(_control_rw, LOW);
  digitalWrite(_control_e, LOW); 
  // initialize WD control lines to output
  pinMode(_control_rs, OUTPUT);
  pinMode(_control_rw, OUTPUT);
  pinMode(_control_e, OUTPUT);
  portMode(_port, INPUT);
  portWrite(_port, 0xff);
}

void LiquidCrystal::display_wait(void) {
  digitalWrite(_control_rs, LOW);

  portMode(_port, INPUT);
  portWrite(_port, 0x00);

  digitalWrite(_control_rw, HIGH);
  digitalWrite(_control_e, HIGH);

  WD_DELAY;
  while(portRead(_port) & 1<<WD_BUSY) {
    digitalWrite(_control_e, LOW);
    WD_DELAY;
    WD_DELAY;
    digitalWrite(_control_e, HIGH);
    WD_DELAY;
    WD_DELAY;
  }
  digitalWrite(_control_e, LOW);
}


void LiquidCrystal::display_control_write(uint8_t data) {
  display_wait();
  digitalWrite(_control_rs, LOW);
  digitalWrite(_control_rw, LOW);

  digitalWrite(_control_e, HIGH);
  portMode(_port, OUTPUT);
  portWrite(_port, data);

  WD_DELAY;
  WD_DELAY;
  digitalWrite(_control_e, LOW);

  portMode(_port, INPUT);
  portWrite(_port, 0xff);
}


uint8_t LiquidCrystal::display_control_read(void) {
  register uint8_t data;
  display_wait();
  portMode(_port, INPUT);
  portWrite(_port, 0xff);

  digitalWrite(_control_rs, LOW);
  digitalWrite(_control_rw, HIGH);

  digitalWrite(_control_e, HIGH);
  WD_DELAY;
  WD_DELAY;
  data = portRead(_port);
  digitalWrite(_control_e, LOW);
  return data;
}

void LiquidCrystal::display_data_write(uint8_t data) {
  display_wait();
  digitalWrite(_control_rs, HIGH);
  digitalWrite(_control_rw, LOW);
 
  digitalWrite(_control_e, HIGH);
  portMode(_port, OUTPUT);
  portWrite(_port, data);
 
  WD_DELAY;
  WD_DELAY;
  digitalWrite(_control_e, LOW);

  portMode(_port, INPUT);
  portWrite(_port, 0xff);  
}

uint8_t LiquidCrystal::display_data_read(void) {
  register uint8_t data;
  display_wait();
  portMode(_port, INPUT);
  portWrite(_port, 0xff);

  digitalWrite(_control_rs, HIGH);
  digitalWrite(_control_rw, HIGH);

  digitalWrite(_control_e, HIGH);
  WD_DELAY;
  WD_DELAY;
  data = portRead(_port);
  digitalWrite(_control_e, LOW);
  return data;
}

/*
void LiquidCrystal::display_load_char(uint8_t* wdCustomCharArray, uint8_t romCharNum, uint8_t wdCharNum) {
  register uint8_t i;
  uint8_t saveDDRAMAddr;

  // backup the current cursor position
  saveDDRAMAddr = display_control_read() & 0x7F;

  // multiply the character index by 8
  wdCharNum = (wdCharNum<<3);   // each character occupies 8 bytes
  romCharNum = (romCharNum<<3); // each character occupies 8 bytes

  // copy the 8 bytes into CG (character generator) RAM
  for(i=0; i<8; i++) {
    // set CG RAM address
    display_control_write((1<<WD_CGRAM) | (wdCharNum+i));
    // write character data
    display_data_drite( pgm_read_byte(wdCustomCharArray+romCharNum+i) );
  }
  // restore the previous cursor position
  display_control_write(1<<WD_DDRAM | saveDDRAMAddr);
}
*/

void LiquidCrystal::display_write(char* data, uint8_t len) {
  register uint8_t i;
  if (!data) return;
  for(i=0; i<len; i++) {
    display_data_write(data[i]);
  }
}



//////////////////Public API



/*
LiquidCrystal::LiquidCrystal()
{
  _control_rs = 8;
  _control_rw = 9;
  _control_e = 10;
  _port = 2;  
  display_start();
}
*/

LiquidCrystal::LiquidCrystal(uint8_t rs, uint8_t rw, uint8_t e, uint8_t port) {
  _control_rs = rs;
  _control_rw = rw;
  _control_e = e;
  _port = port;
  display_start();
}

void LiquidCrystal::display_start()
{
  display_init();
  display_control_write(((1<<WD_FUNCTION) | (1<<WD_FUNCTION_8BIT) | (1<<WD_FUNCTION_2LINES)));
  display_control_write(1<<WD_CLR);
  display_control_write(1<<WD_ENTRY_MODE | 1<<WD_ENTRY_INC);
  // set display to on
  //display_control_write(1<<WD_ON_CTRL | 1<<WD_ON_DISPLAY | 1<<WD_ON_BLINK);
  display_control_write(1<<WD_ON_CTRL | 1<<WD_ON_DISPLAY );
  display_control_write(1<<WD_HOME);
  // set data address to 0
  display_control_write(1<<WD_DDRAM | 0x00);
}

/*
uint8_t LiquidCrystal::read(void)
{
  return display_data_read();
}
*/

void LiquidCrystal::clear() {
  display_control_write(1<<WD_CLR);
}

void LiquidCrystal::home() {
  display_control_write(1<<WD_HOME);
}

void LiquidCrystal::setCursor(uint8_t x, uint8_t y) {
  register uint8_t DDRAMAddr;

  // remap lines into proper order
  switch(y) {
    case 0: DDRAMAddr = WD_LINE0_DDRAMADDR+x; break;
    case 1: DDRAMAddr = WD_LINE1_DDRAMADDR+x; break;
    case 2: DDRAMAddr = WD_LINE2_DDRAMADDR+x; break;
    case 3: DDRAMAddr = WD_LINE3_DDRAMADDR+x; break;
    default: DDRAMAddr = WD_LINE0_DDRAMADDR+x;
  }
  // set data address
  display_control_write(1<<WD_DDRAM | DDRAMAddr);
}

/*
void LiquidCrystal::print(char c)
{
  display_write(&c, 1);
}

void LiquidCrystal::print(char c[])
{
  display_write(c, strlen(c));
}


void LiquidCrystal::print(String &str)
{
  print(str.toCharArray());
}
*/

void LiquidCrystal::write(uint8_t b)
{
  char c = b;
  display_write(&c, 1);
}

/*
void LiquidCrystal::print(int n)
{
  print((long) n);
}

void LiquidCrystal::print(long n)
{
  if (n < 0) {
    print('-');
    n = -n;
  }
  printNumber(n, 10);
}

void LiquidCrystal::print(long n, int base)
{
  if (base == 0)
    print((char) n);
  else if (base == 10)
    print(n);
  else
    printNumber(n, base);
}

void LiquidCrystal::println(void)
{
  print('\n');
}

void LiquidCrystal::println(char c)
{
  print(c);
  println();
}

void LiquidCrystal::println(char c[])
{
  display_write(c, strlen(c));
  println();
}


void LiquidCrystal::println(String &str)
{
  print(str);
  println();
}


void LiquidCrystal::println(uint8_t b)
{
  print(b);
  println();
}

void LiquidCrystal::println(int n)
{
  println((long) n);
}

void LiquidCrystal::println(long n)
{
  print(n);
  println();
}

void LiquidCrystal::println(long n, int base)
{
  print(n, base);
  println();
}

// Private Methods /////////////////////////////////////////////////////////////

void LiquidCrystal::printNumber(unsigned long n, uint8_t base)
{
  uint8_t buf[8 * sizeof(long)]; // Assumes 8-bit chars.
  int i = 0;
  if (n == 0) {
    print('0');
    return;
  }
  while (n > 0) {
    buf[i++] = n % base;
    n /= base;
  }
  for (i--; i >= 0; i--){
    print((char)(buf[i] < 10 ? '0' + buf[i] : 'A' + buf[i] - 10));
  }
}
*/
