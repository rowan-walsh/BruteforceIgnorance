
// PRE: Start facing target wall
// POST: Stopped with rear QRD sensor on center tape
void LocateCenterTape()
{
	Strafe(LEFT);
	while(!LeftTouchSensor())	// Wait for left wall alignment
		Update();
	Strafe(RIGHT);				// Start moving right
	int tapeCount = 0;
	while(tapeCount < 2)		// Look for center tape
	{		
		if (TapeRiseDetected()) tapeCount++; // Prevents same tape from being detected twice
		else Update();
	}			
	StopMotors();				// Stop at center tape
}

// PRE: Situated on tape
// POST: Situated on tape, but rotated 180 degrees
void RotateOnTape(int turnRate = 100, int timeout = 10000)
{
	SetWheelAngle(0);
	LeftMotor(turnRate); 
	RightMotor(-turnRate);
	while(!FrontTapeDetected())
	{
		Update();
		if(timeout <= 0) TapeRecovery();
		else timeout--;
	}
	StopMotors(); 
}

// PRE: Sensors cannot detect tape
// POST: Moves in expanding spirals until tape is detected
void TapeRecovery()
{
	int leftSpeed = -200;
	int rightSpeed = 200;
	int timeout = 0;
	LeftMotor(leftSpeed);
	RightMotor(rightSpeed);
	while(!FrontTapeDetected())
	{
		Update();
		timeout++;
		// Increase spiral radius
		if (timeout % 100 == 0) LeftMotor(++leftSpeed);
		if (timeout < 10000) continue;
		// Call again to reset spiral
		TapeRecovery();
		return;
	}
	StopMotors();
}