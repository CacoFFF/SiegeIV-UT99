//=============================================================================
// sgMineTrigger.
//
// Written by Higor
// Subclass of triggers to prevent translocators from bouncing from this actor
//=============================================================================
class sgMineTrigger expands Triggers;

var Mine Master;

event Touch( Actor Other )
{
	local pawn P;

	if ( !Other.bIsPawn )
		return;

	if ( Master == none )
	{
		Destroy();
		return;
	}

	if ( ScriptedPawn(Other) != none )
	{
		Master.CheckThis( Pawn(Other) );
		return;
	}

	P = Pawn(Other);
	if ( P.bIsPlayer && (P.Health > 0) && (P.PlayerReplicationInfo != None) && (P.PlayerReplicationInfo.Team != Master.Team) && !P.PlayerReplicationInfo.bIsSpectator )
	{
		Master.CheckThis( P);
		return;
	}
}

function bool IsTouching( actor Other)
{
	if ( Other == none )
		return false;
	if ( abs(Other.Location.Z - Location.Z) > (CollisionHeight + Other.CollisionHeight) )
		return false;
	return VSize( (Other.Location - Location) * vect(1,1,0)) < (CollisionRadius + Other.CollisionRadius);
}

defaultproperties
{
     CollisionRadius=10.000000
     CollisionHeight=10.000000
}