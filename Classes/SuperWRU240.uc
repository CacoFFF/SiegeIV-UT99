//=============================================================================
// SuperWRU240.
//=============================================================================
class SuperWRU240 expands WRU240;

simulated function FixDefaults()
{
	Super.FixDefaults();
	DrawScale = 3;
}


defaultproperties
{
     RU=2400
     PickupMessage="YOU HAVE FOUND THE 2400 RU MEGA RESOURCE!!"
     PickupViewScale=3.000000
     CollisionRadius=90.000000
     CollisionHeight=90.000000
}
