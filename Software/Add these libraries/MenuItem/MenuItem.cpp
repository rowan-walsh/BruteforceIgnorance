#include "WProgram.h"
#include "MenuItem.h"
#include <EEPROM.h>

MenuItem::MenuItem()
{
}

MenuItem::MenuItem(String itemName, int itemEepromAddress)
{
	SetName(itemName);
	SetAddress(itemEepromAddress);
}

// Changes the eeprom address and loads the new value stored in that address
void MenuItem::SetAddress(int newEepromAddress)
{
	eepromAddress = newEepromAddress;
	value = EEPROM.read(eepromAddress) * 4;
}

// Sets the name of the menu item
void MenuItem::SetName(String newName)
{
	name = newName;
}

// Sets the current item value and saves it to the EEPROM
void MenuItem::SetValue(int newValue)
{
	if (newValue > 1000) newValue = 1000; // Max eeprom value
	value = newValue;
	EEPROM.write(eepromAddress, value / 4);
}

// Returns the current item value
int MenuItem::Value()
{
	return value;
}

// Returns name of the menu item
String MenuItem::Name()
{
	return name;
}

// returns the eeprom address of the item
int MenuItem::Address()
{
	return eepromAddress;
}