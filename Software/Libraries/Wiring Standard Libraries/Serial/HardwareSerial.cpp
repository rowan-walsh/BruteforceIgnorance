/* $Id: HardwareSerial.cpp 776 2010-09-01 06:59:00Z h $

  Hardware Serial Library Class
  Redesigned for RX and TX buffering using FIFO (by Alexander Brevig)
  by Brett Hagman
  http://www.roguerobotics.com/
  bhagman@roguerobotics.com


  Original Source:
    HardwareSerial.cpp - Hardware serial library for Wiring - 2006 Nicholas Zambetti
  Modifications:
    23 November 2006 by David A. Mellis

    This library is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This library is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.
*/

#include "HardwareSerial.h"

// Small fix for atmega8
#if !defined(__AVR_ATmega8__)
#define RXCIE RXCIE0
#define UDRIE UDRIE0
#define RXEN  RXEN0
#define TXEN  TXEN0
#define UDRE  UDRE0
#define U2X   U2X0
#endif

ISR(Serial_RX_vect)
{
  Serial.rxfifo.enqueue(*Serial._udr);
}

ISR(Serial_TX_vect)
{
  if (Serial.txfifo.count() > 0)
    *Serial._udr = Serial.txfifo.dequeue();

  if (Serial.txfifo.count() == 0)
    *Serial._ucsrb = (1 << RXEN) | (1 << TXEN) | (1 << RXCIE);
}


#if SerialPorts > 1
ISR(Serial1_RX_vect)
{
  Serial1.rxfifo.enqueue(*Serial1._udr);
}

ISR(Serial1_TX_vect)
{
  if (Serial1.txfifo.count() > 0)
    *Serial1._udr = Serial1.txfifo.dequeue();

  if (Serial1.txfifo.count() == 0)
    *Serial1._ucsrb = (1 << RXEN) | (1 << TXEN) | (1 << RXCIE);
}
#endif

#if SerialPorts > 2
ISR(Serial2_RX_vect)
{
  Serial2.rxfifo.enqueue(*Serial2._udr);
}

ISR(Serial2_TX_vect)
{
  if (Serial2.txfifo.count() > 0)
    *Serial2._udr = Serial2.txfifo.dequeue();

  if (Serial2.txfifo.count() == 0)
    *Serial2._ucsrb = (1 << RXEN) | (1 << TXEN) | (1 << RXCIE);
}
#endif

#if SerialPorts > 3
ISR(Serial3_RX_vect)
{
  Serial3.rxfifo.enqueue(*Serial3._udr);
}

ISR(Serial3_TX_vect)
{
  if (Serial3.txfifo.count() > 0)
    *Serial3._udr = Serial3.txfifo.dequeue();

  if (Serial3.txfifo.count() == 0)
    *Serial3._ucsrb = (1 << RXEN) | (1 << TXEN) | (1 << RXCIE);
}
#endif


// Constructor

HardwareSerial::HardwareSerial(
  volatile uint8_t *ubrrh,
  volatile uint8_t *ubrrl,
  volatile uint8_t *ucsra,
  volatile uint8_t *ucsrb,
  volatile uint8_t *udr)
{
  _ubrrh = ubrrh;
  _ubrrl = ubrrl;
  _ucsra = ucsra;
  _ucsrb = ucsrb;
  _udr = udr;
}


// Public Methods

void HardwareSerial::begin(long baud)
{
  uint16_t baud_setting;
  bool use_u2x;

  // U2X mode is needed for baud rates higher than (CPU Hz / 16)
  if (baud > F_CPU / 16) {
    use_u2x = true;
  } else {
    // figure out if U2X mode would allow for a better connection
    
    // calculate the percent difference between the baud-rate specified and
    // the real baud rate for both U2X and non-U2X mode (0-255 error percent)
    uint8_t nonu2x_baud_error = abs((int)(255-((F_CPU/(16*(((F_CPU/8/baud-1)/2)+1))*255)/baud)));
    uint8_t u2x_baud_error = abs((int)(255-((F_CPU/(8*(((F_CPU/4/baud-1)/2)+1))*255)/baud)));
    
    // prefer non-U2X mode because it handles clock skew better
    use_u2x = (nonu2x_baud_error > u2x_baud_error);
  }
  
  if (use_u2x) {
    *_ucsra = 1 << U2X;
    baud_setting = (F_CPU / 4 / baud - 1) / 2;
  } else {
    *_ucsra = 0;
    baud_setting = (F_CPU / 8 / baud - 1) / 2;
  }

  // assign the baud_setting, a.k.a. ubbr (USART Baud Rate Register)

	*_ubrrh = baud_setting >> 8;
        *_ubrrl = baud_setting;
  *_ucsrb = (1 << RXEN) | (1 << TXEN) | (1 << RXCIE);
}


void HardwareSerial::end()
{
  *_ucsrb &= ~(1 << RXEN) | (1 << TXEN) | (1 << RXCIE);
}


int HardwareSerial::available(void)
{
  return rxfifo.count();
}


int HardwareSerial::read(void)
{
  if (rxfifo.count())
    return rxfifo.dequeue();
  else
    return -1;
}


int HardwareSerial::peek(void)
{
  if (rxfifo.count())
    return rxfifo.peek();
  else
    return -1;
}


void HardwareSerial::flush()
{
  rxfifo.flush();
}


void HardwareSerial::write(uint8_t c)
{
  // We will block here until we have some space free in the FIFO
  while (txfifo.count() >= TX_BUFFER_SIZE);

  cli();
  txfifo.enqueue(c);
  *_ucsrb |= (1 << UDRIE);
  sei();
}


// Preinstantiate Objects


#if defined(__AVR_ATmega8__)
HardwareSerial Serial(&UBRRH, &UBRRL, &UCSRA, &UCSRB, &UDR);
#else
HardwareSerial Serial(&UBRR0H, &UBRR0L, &UCSR0A, &UCSR0B, &UDR0);
#endif

#if SerialPorts > 1
HardwareSerial Serial1(&UBRR1H, &UBRR1L, &UCSR1A, &UCSR1B, &UDR1);
#endif
#if SerialPorts > 2
HardwareSerial Serial2(&UBRR2H, &UBRR2L, &UCSR2A, &UCSR2B, &UDR2);
#endif
#if SerialPorts > 3
HardwareSerial Serial3(&UBRR3H, &UBRR3L, &UCSR3A, &UCSR3B, &UDR3);
#endif
