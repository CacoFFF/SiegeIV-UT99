// sgSpeed's speed affector
class XC_MA_sgSpeed expands XC_MovementAffector;

var sgSpeed Item;
var bool bActive;

replication
{
	reliable if ( Role == ROLE_Authority )
		bActive;
}

simulated function AffectMovement( float DeltaTime)
{
	if ( Role == ROLE_Authority )
	{
		if ( Item == none || Item.bDeleteMe )
		{
			Destroy();
			return;
		}
		bActive = Item.bActive;
	}
	if ( bActive && Pawn(Owner) != none )
	{
		Pawn(Owner).GroundSpeed *= 1.5;
		Pawn(Owner).WaterSpeed *= 1.5;
		Pawn(Owner).AirSpeed *= 1.5;
		Pawn(Owner).AccelRate *= 1.5;
	}
}

simulated function XC_MovementAffector InsertSorted( XC_MovementAffector Other)
{
	// I'm being replaced, self destruct on next tick
	if ( (Other.Class == Class) && (Other != self) )
		Item = none; 
	return Super.InsertSorted( Other);
}



defaultproperties
{
	 AffectorPriority=10
}
