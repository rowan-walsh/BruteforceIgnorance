/*
||
|| @file        FIFO.h
|| @version     1.2
|| @author      Alexander Brevig
|| @contact     alexanderbrevig@gmail.com
||
|| @description
|| | A simple FIFO class, mostly for primitive types but can be used with classes if assignment to int is allowed
|| | This FIFO is not dynamic, so be sure to choose an appropriate size for it
|| #
||
|| @license
|| | Copyright (c) 2010 Alexander Brevig
|| | This library is free software; you can redistribute it and/or
|| | modify it under the terms of the GNU Lesser General Public
|| | License as published by the Free Software Foundation; version
|| | 2.1 of the License.
|| |
|| | This library is distributed in the hope that it will be useful,
|| | but WITHOUT ANY WARRANTY; without even the implied warranty of
|| | MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
|| | Lesser General Public License for more details.
|| |
|| | You should have received a copy of the GNU Lesser General Public
|| | License along with this library; if not, write to the Free Software
|| | Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301 USA
|| #
||
*/

#ifndef FIFO_h
#define FIFO_h

template<typename T, int rawSize>
class FIFO {
  public:
    const int size;                         //speculative feature, in case it's needed

    FIFO();

    T dequeue();                            //get next element
    bool enqueue( T element );              //add an element
    T peek() const;                         //get the next element without releasing it from the FIFO
    void flush();                           //[1.1] reset to default state 

    //how many elements are currently in the FIFO?
    int count() { return numberOfElements; }

  private:
    volatile int numberOfElements;
    int nextIn;
    int nextOut;
    T raw[rawSize];
};

template<typename T, int rawSize>
FIFO<T,rawSize>::FIFO() : size(rawSize)
{
  flush();
}

template<typename T, int rawSize>
bool FIFO<T,rawSize>::enqueue( T element )
{
  if ( count() >= rawSize ) { return false; }
  numberOfElements++;
  raw[nextIn] = element;
  if (++nextIn >= size) // advance to next index, wrap if needed
    nextIn = 0;
  return true;
}

template<typename T, int rawSize>
T FIFO<T,rawSize>::dequeue()
{
  T item;
  numberOfElements--;
  item = raw[nextOut];
  if (++nextOut >= size) // advance to next index, wrap if needed
    nextOut = 0;
  return item;
}

template<typename T, int rawSize>
T FIFO<T,rawSize>::peek() const
{
  return raw[nextOut];
}

template<typename T, int rawSize>
void FIFO<T,rawSize>::flush()
{
  nextIn = nextOut = numberOfElements = 0;
}

#endif
