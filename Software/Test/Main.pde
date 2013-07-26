
void setup()
{
	portMode(0, INPUT);       
	portMode(1, INPUT); 
	RCServo0.attach(RCServo0Output);
	RCServo1.attach(RCServo1Output);
	RCServo2.attach(RCServo2Output);
}

void loop()
{	
	Update();
	switch(maneuverState)
	{
		case MENU_STATE:
		ProcessMenu();
		break;
		case WALL_FOLLOWING_STATE:
		WallFollow();
		break;
		case TAPE_FOLLOW_DOWN_STATE:
		FollowTape(FOLLOW_DOWN_DIRECTION);
		break;
		case COLLECTION_STATE:
		Collection();
		break;
		case TAPE_FOLLOW_UP_STATE:
		FollowTape(FOLLOW_UP_DIRECTION);
		break;
		default:
		Reset();
		Print("Error: no state");
		break;
	}
}
