//=============================================================================
// SuperWRU120.
//=============================================================================
class SuperWRU120 expands WRU120;

simulated function FixDefaults()
{
	Super.FixDefaults();
	DrawScale = 3;
}

defaultproperties
{
     RU=1200
     PickupMessage="YOU HAVE FOUND THE 1200 RU MEGA RESOURCE!!"
     PickupViewScale=3.000000
     CollisionRadius=90.000000
     CollisionHeight=90.000000
}
