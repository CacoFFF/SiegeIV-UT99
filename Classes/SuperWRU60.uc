//=============================================================================
// SuperWRU60.
//=============================================================================
class SuperWRU60 expands WRU60;

simulated function FixDefaults()
{
	Super.FixDefaults();
	DrawScale = 3;
}

defaultproperties
{
     RU=600
     ItemName="600 RU (Blue Diamond)"
     PickupMessage="YOU HAVE FOUND THE 600 RU MEGA RESOURCE!!"
     PlayerViewScale=3.000000
     PickupViewScale=3.000000
     CollisionRadius=90.000000
     CollisionHeight=90.000000
}
