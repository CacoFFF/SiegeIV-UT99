//=============================================================================
// SuperWRU15.
//=============================================================================
class SuperWRU15 expands WRU15;

simulated function FixDefaults()
{
	Super.FixDefaults();
	DrawScale = 3;
}


defaultproperties
{
     RU=150
     ItemName="150 RU (White Diamond)"
     PickupMessage="YOU HAVE FOUND THE 150 RU MEGA RESOURCE!!"
     PickupViewScale=3.000000
     CollisionRadius=90.000000
     CollisionHeight=90.000000
}
