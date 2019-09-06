//=============================================================================
// SuperWRU30.
//=============================================================================
class SuperWRU30 expands WRU30;

simulated function FixDefaults()
{
	Super.FixDefaults();
	DrawScale = 3;
}


defaultproperties
{
     RU=300
     ItemName="300 RU (Red Diamond)"
     PickupMessage="YOU HAVE FOUND THE 300 RU MEGA RESOURCE!!"
     PickupViewScale=3.000000
     CollisionRadius=90.000000
     CollisionHeight=90.000000
}
