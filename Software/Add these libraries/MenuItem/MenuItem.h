#ifndef MenuItem_h
#define MenuItem_h

class MenuItem
{
private:
	int eepromAddress;
	int value;
	String name;
public:
	
	MenuItem();
	MenuItem(String itemName, int itemEepromAddress);
	
	void SetName(String newName);
	void SetAddress(int newEepromAddress);
	void SetValue(int newValue);
	
	String Name();
	int Address();
	int Value();
};

#endif
