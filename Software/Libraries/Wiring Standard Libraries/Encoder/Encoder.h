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

#ifndef Encoder_h
#define Encoder_h

#include <inttypes.h>


class Encoder
{
  private:
    uint8_t _index;
    static const uint8_t _interrupts[];
    volatile uint8_t _pin_a;
    volatile uint8_t _pin_b;
    volatile int32_t _position;
    static uint8_t _count;
    static Encoder* _encoders[];
    static void service0(void);
    static void service1(void);
    static void service2(void);
    static void service3(void);
    void service(void);

  public:
    Encoder();
    uint8_t attach(uint8_t, uint8_t);
    void detach();
    void write(int32_t);
    int32_t read(void);
    uint8_t attached(void);
};

#endif
